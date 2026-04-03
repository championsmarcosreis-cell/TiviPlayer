package io.flutter.plugins.videoplayer;

import android.util.Log;
import android.net.Uri;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/** Performs a small off-main-thread probe of MPEG-TS streams to identify AAC ADTS audio. */
final class TransportStreamProbe {
  private static final String TAG = "TiviTsProbe";
  private static final int TRANSPORT_STREAM_PACKET_SIZE = 188;
  private static final int REQUIRED_SYNC_PACKETS = 5;
  private static final int MAX_PROBE_BYTES = 256 * 1024;
  private static final int CONNECT_TIMEOUT_MS = 1200;
  private static final int READ_TIMEOUT_MS = 1200;
  private static final int FUTURE_TIMEOUT_MS = 1800;
  private static final int PAT_PID = 0x0000;
  private static final int AAC_ADTS_STREAM_TYPE = 0x0F;
  private static final ExecutorService PROBE_EXECUTOR =
      Executors.newSingleThreadExecutor(
          new ThreadFactory() {
            @Override
            public Thread newThread(@NonNull Runnable runnable) {
              Thread thread = new Thread(runnable, "TiviTsProbe");
              thread.setDaemon(true);
              return thread;
            }
          });

  private TransportStreamProbe() {}

  enum AudioProfile {
    UNKNOWN(false),
    AAC_ADTS(true),
    OTHER_AUDIO(true),
    OTHER_STREAM(false);

    private final boolean cacheable;

    AudioProfile(boolean cacheable) {
      this.cacheable = cacheable;
    }

    boolean isCacheable() {
      return cacheable;
    }
  }

  @NonNull
  static AudioProfile probeAudioProfile(
      @NonNull String assetUrl,
      @NonNull Map<String, String> httpHeaders,
      @Nullable String userAgent) {
    Future<AudioProfile> future =
        PROBE_EXECUTOR.submit(
            new Callable<AudioProfile>() {
              @Override
              public AudioProfile call() {
                return probeAudioProfileBlocking(assetUrl, httpHeaders, userAgent);
              }
            });
    try {
      return future.get(FUTURE_TIMEOUT_MS, TimeUnit.MILLISECONDS);
    } catch (TimeoutException exception) {
      future.cancel(true);
      Log.w(
          TAG,
          "Timed out probing transport stream audio profile for " + summarizeUri(assetUrl),
          exception);
      return AudioProfile.UNKNOWN;
    } catch (InterruptedException exception) {
      future.cancel(true);
      Thread.currentThread().interrupt();
      Log.w(
          TAG,
          "Interrupted while probing transport stream audio profile for " + summarizeUri(assetUrl),
          exception);
      return AudioProfile.UNKNOWN;
    } catch (ExecutionException exception) {
      Log.w(
          TAG,
          "Failed to probe transport stream audio profile for " + summarizeUri(assetUrl),
          exception);
      return AudioProfile.UNKNOWN;
    }
  }

  @NonNull
  private static AudioProfile probeAudioProfileBlocking(
      @NonNull String assetUrl,
      @NonNull Map<String, String> httpHeaders,
      @Nullable String userAgent) {
    HttpURLConnection connection = null;
    try {
      connection = (HttpURLConnection) new URL(assetUrl).openConnection();
      connection.setInstanceFollowRedirects(true);
      connection.setConnectTimeout(CONNECT_TIMEOUT_MS);
      connection.setReadTimeout(READ_TIMEOUT_MS);
      connection.setRequestMethod("GET");
      connection.setRequestProperty("Accept-Encoding", "identity");
      connection.setRequestProperty("Connection", "close");
      connection.setRequestProperty("Range", "bytes=0-" + (MAX_PROBE_BYTES - 1));
      if (userAgent != null && !userAgent.isEmpty()) {
        connection.setRequestProperty("User-Agent", userAgent);
      }
      for (Map.Entry<String, String> header : httpHeaders.entrySet()) {
        connection.setRequestProperty(header.getKey(), header.getValue());
      }
      connection.connect();
      int responseCode = connection.getResponseCode();
      if (responseCode >= 400) {
        Log.w(
            TAG,
            "Probe request returned HTTP "
                + responseCode
                + " for "
                + summarizeUri(assetUrl));
        return AudioProfile.UNKNOWN;
      }
      try (InputStream inputStream = connection.getInputStream()) {
        byte[] sample = readProbeSample(inputStream);
        AudioProfile profile = inspectSample(sample, sample.length);
        Log.i(
            TAG,
            "Detected transport stream audio profile "
                + profile
                + " for "
                + summarizeUri(assetUrl));
        return profile;
      }
    } catch (IOException exception) {
      Log.w(
          TAG,
          "I/O error probing transport stream audio profile for " + summarizeUri(assetUrl),
          exception);
      return AudioProfile.UNKNOWN;
    } finally {
      if (connection != null) {
        connection.disconnect();
      }
    }
  }

  @NonNull
  private static byte[] readProbeSample(@NonNull InputStream inputStream) throws IOException {
    ByteArrayOutputStream outputStream = new ByteArrayOutputStream(MAX_PROBE_BYTES);
    byte[] buffer = new byte[4096];
    int remaining = MAX_PROBE_BYTES;
    while (remaining > 0) {
      int bytesRead = inputStream.read(buffer, 0, Math.min(buffer.length, remaining));
      if (bytesRead < 0) {
        break;
      }
      outputStream.write(buffer, 0, bytesRead);
      remaining -= bytesRead;
    }
    return outputStream.toByteArray();
  }

  @VisibleForTesting
  @NonNull
  static AudioProfile inspectSample(@NonNull byte[] sample, int length) {
    if (length < TRANSPORT_STREAM_PACKET_SIZE * REQUIRED_SYNC_PACKETS) {
      return AudioProfile.UNKNOWN;
    }

    int syncOffset = findTransportStreamSyncOffset(sample, length);
    if (syncOffset < 0) {
      return AudioProfile.OTHER_STREAM;
    }

    int programMapPid = -1;
    boolean foundProgramMap = false;
    boolean foundAudioDescriptor = false;
    for (int packetOffset = syncOffset;
        packetOffset + TRANSPORT_STREAM_PACKET_SIZE <= length;
        packetOffset += TRANSPORT_STREAM_PACKET_SIZE) {
      if ((sample[packetOffset] & 0xFF) != 0x47) {
        continue;
      }
      int pid = ((sample[packetOffset + 1] & 0x1F) << 8) | (sample[packetOffset + 2] & 0xFF);
      int adaptationFieldControl = (sample[packetOffset + 3] >> 4) & 0x03;
      if (adaptationFieldControl == 0 || adaptationFieldControl == 2) {
        continue;
      }

      int payloadOffset = packetOffset + 4;
      if (adaptationFieldControl == 3) {
        int adaptationLength = sample[payloadOffset] & 0xFF;
        payloadOffset += 1 + adaptationLength;
      }
      if (payloadOffset >= packetOffset + TRANSPORT_STREAM_PACKET_SIZE) {
        continue;
      }

      boolean payloadStart = (sample[packetOffset + 1] & 0x40) != 0;
      if (pid == PAT_PID && payloadStart) {
        int parsedProgramMapPid =
            parseProgramMapPid(sample, payloadOffset, packetOffset + TRANSPORT_STREAM_PACKET_SIZE);
        if (parsedProgramMapPid >= 0) {
          programMapPid = parsedProgramMapPid;
        }
        continue;
      }

      if (programMapPid < 0 || pid != programMapPid || !payloadStart) {
        continue;
      }

      foundProgramMap = true;
      AudioProfile profile =
          parseAudioProfileFromProgramMap(
              sample, payloadOffset, packetOffset + TRANSPORT_STREAM_PACKET_SIZE);
      if (profile == AudioProfile.AAC_ADTS) {
        return AudioProfile.AAC_ADTS;
      }
      if (profile == AudioProfile.OTHER_AUDIO) {
        foundAudioDescriptor = true;
      }
    }

    if (foundAudioDescriptor || foundProgramMap) {
      return AudioProfile.OTHER_AUDIO;
    }
    return AudioProfile.UNKNOWN;
  }

  private static int findTransportStreamSyncOffset(@NonNull byte[] sample, int length) {
    for (int offset = 0; offset < TRANSPORT_STREAM_PACKET_SIZE; offset++) {
      int syncCount = 0;
      for (int position = offset;
          position < length && syncCount < REQUIRED_SYNC_PACKETS;
          position += TRANSPORT_STREAM_PACKET_SIZE) {
        if ((sample[position] & 0xFF) != 0x47) {
          break;
        }
        syncCount++;
      }
      if (syncCount >= REQUIRED_SYNC_PACKETS) {
        return offset;
      }
    }
    return -1;
  }

  private static int parseProgramMapPid(@NonNull byte[] sample, int payloadOffset, int packetEnd) {
    int sectionOffset = skipPointerField(sample, payloadOffset, packetEnd);
    if (!isPsiHeaderAvailable(sample, sectionOffset, packetEnd) || (sample[sectionOffset] & 0xFF) != 0x00) {
      return -1;
    }
    int sectionLength = parseSectionLength(sample, sectionOffset);
    int sectionEnd = Math.min(sectionOffset + 3 + sectionLength, packetEnd);
    if (sectionEnd - sectionOffset < 12) {
      return -1;
    }
    for (int entryOffset = sectionOffset + 8;
        entryOffset + 4 <= sectionEnd - 4;
        entryOffset += 4) {
      int programNumber = ((sample[entryOffset] & 0xFF) << 8) | (sample[entryOffset + 1] & 0xFF);
      if (programNumber == 0) {
        continue;
      }
      return ((sample[entryOffset + 2] & 0x1F) << 8) | (sample[entryOffset + 3] & 0xFF);
    }
    return -1;
  }

  @NonNull
  private static AudioProfile parseAudioProfileFromProgramMap(
      @NonNull byte[] sample, int payloadOffset, int packetEnd) {
    int sectionOffset = skipPointerField(sample, payloadOffset, packetEnd);
    if (!isPsiHeaderAvailable(sample, sectionOffset, packetEnd) || (sample[sectionOffset] & 0xFF) != 0x02) {
      return AudioProfile.UNKNOWN;
    }
    int sectionLength = parseSectionLength(sample, sectionOffset);
    int sectionEnd = Math.min(sectionOffset + 3 + sectionLength, packetEnd);
    if (sectionEnd - sectionOffset < 16) {
      return AudioProfile.UNKNOWN;
    }
    int programInfoLength =
        ((sample[sectionOffset + 10] & 0x0F) << 8) | (sample[sectionOffset + 11] & 0xFF);
    int streamOffset = sectionOffset + 12 + programInfoLength;
    boolean foundAudioDescriptor = false;
    while (streamOffset + 5 <= sectionEnd - 4) {
      int streamType = sample[streamOffset] & 0xFF;
      int esInfoLength = ((sample[streamOffset + 3] & 0x0F) << 8) | (sample[streamOffset + 4] & 0xFF);
      if (streamType == AAC_ADTS_STREAM_TYPE) {
        return AudioProfile.AAC_ADTS;
      }
      if (isKnownAudioStreamType(streamType)) {
        foundAudioDescriptor = true;
      }
      streamOffset += 5 + esInfoLength;
    }
    return foundAudioDescriptor ? AudioProfile.OTHER_AUDIO : AudioProfile.UNKNOWN;
  }

  private static boolean isPsiHeaderAvailable(@NonNull byte[] sample, int sectionOffset, int packetEnd) {
    return sectionOffset >= 0 && sectionOffset + 3 <= packetEnd;
  }

  private static int skipPointerField(@NonNull byte[] sample, int payloadOffset, int packetEnd) {
    if (payloadOffset >= packetEnd) {
      return -1;
    }
    int pointerField = sample[payloadOffset] & 0xFF;
    int sectionOffset = payloadOffset + 1 + pointerField;
    if (sectionOffset >= packetEnd) {
      return -1;
    }
    return sectionOffset;
  }

  private static int parseSectionLength(@NonNull byte[] sample, int sectionOffset) {
    return ((sample[sectionOffset + 1] & 0x0F) << 8) | (sample[sectionOffset + 2] & 0xFF);
  }

  private static boolean isKnownAudioStreamType(int streamType) {
    return streamType == 0x03
        || streamType == 0x04
        || streamType == 0x0F
        || streamType == 0x11
        || streamType == 0x81
        || streamType == 0x87;
  }

  @NonNull
  private static String summarizeUri(@Nullable String rawUri) {
    if (rawUri == null || rawUri.isEmpty()) {
      return "unknown";
    }

    try {
      Uri uri = Uri.parse(rawUri);
      String host = uri.getHost();
      String lastPathSegment = uri.getLastPathSegment();
      return uri.getScheme()
          + "://"
          + (host == null || host.isEmpty() ? "unknown-host" : host)
          + "/..."
          + "/"
          + (lastPathSegment == null || lastPathSegment.isEmpty() ? "unknown" : lastPathSegment);
    } catch (RuntimeException exception) {
      return "unparseable";
    }
  }
}
