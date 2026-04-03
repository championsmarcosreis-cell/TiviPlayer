package io.flutter.plugins.videoplayer;

import android.util.Log;
import android.net.Uri;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import java.util.ArrayList;
import java.util.Collections;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.List;
import java.util.Locale;
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
  private static final int PTS_CLOCK_HZ = 90_000;
  private static final int H264_VIDEO_STREAM_TYPE = 0x1B;
  private static final int H265_VIDEO_STREAM_TYPE = 0x24;
  private static final int MPEG2_VIDEO_STREAM_TYPE = 0x02;
  private static final float FPS_24ISH_MIN = 23.5f;
  private static final float FPS_24ISH_MAX = 24.5f;
  private static final float SAMSUNG_PROBLEM_CADENCE_MIN_FPS = 40.0f;
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

  enum VideoFrameRateProfile {
    UNKNOWN,
    FPS_24ISH,
    OTHER
  }

  static final class StreamInfo {
    @NonNull private final AudioProfile audioProfile;
    @NonNull private final VideoFrameRateProfile videoFrameRateProfile;
    private final float estimatedFramesPerSecond;
    private final int videoPid;
    private final int videoStreamType;

    StreamInfo(
        @NonNull AudioProfile audioProfile,
        @NonNull VideoFrameRateProfile videoFrameRateProfile,
        float estimatedFramesPerSecond,
        int videoPid,
        int videoStreamType) {
      this.audioProfile = audioProfile;
      this.videoFrameRateProfile = videoFrameRateProfile;
      this.estimatedFramesPerSecond = estimatedFramesPerSecond;
      this.videoPid = videoPid;
      this.videoStreamType = videoStreamType;
    }

    @NonNull
    AudioProfile getAudioProfile() {
      return audioProfile;
    }

    @NonNull
    VideoFrameRateProfile getVideoFrameRateProfile() {
      return videoFrameRateProfile;
    }

    float getEstimatedFramesPerSecond() {
      return estimatedFramesPerSecond;
    }

    boolean isCacheable() {
      return audioProfile.isCacheable() || !Float.isNaN(estimatedFramesPerSecond);
    }

    boolean shouldDisableSamsungHardwareDecoding() {
      return audioProfile == AudioProfile.AAC_ADTS && matchesSamsungProblemCadence();
    }

    boolean matchesSamsungProblemCadence() {
      return !Float.isNaN(estimatedFramesPerSecond)
          && estimatedFramesPerSecond >= SAMSUNG_PROBLEM_CADENCE_MIN_FPS;
    }

    @NonNull
    String toSummaryString() {
      String fpsSummary =
          Float.isNaN(estimatedFramesPerSecond)
              ? "unknown_fps"
              : String.format(Locale.US, "%.2ffps", estimatedFramesPerSecond);
      String videoPidSummary = videoPid >= 0 ? String.valueOf(videoPid) : "unknown";
      String streamTypeSummary =
          videoStreamType >= 0 ? String.format(Locale.US, "0x%02X", videoStreamType) : "unknown";
      return "audio="
          + audioProfile
          + ", videoFrameRateProfile="
          + videoFrameRateProfile
          + ", fps="
          + fpsSummary
          + ", samsungProblemCadence="
          + matchesSamsungProblemCadence()
          + ", videoPid="
          + videoPidSummary
          + ", videoStreamType="
          + streamTypeSummary;
    }
  }

  private static final class ProgramMapInfo {
    @NonNull final AudioProfile audioProfile;
    final int videoPid;
    final int videoStreamType;

    ProgramMapInfo(@NonNull AudioProfile audioProfile, int videoPid, int videoStreamType) {
      this.audioProfile = audioProfile;
      this.videoPid = videoPid;
      this.videoStreamType = videoStreamType;
    }
  }

  @NonNull
  static AudioProfile probeAudioProfile(
      @NonNull String assetUrl,
      @NonNull Map<String, String> httpHeaders,
      @Nullable String userAgent) {
    return probeStreamInfo(assetUrl, httpHeaders, userAgent).getAudioProfile();
  }

  @NonNull
  static StreamInfo probeStreamInfo(
      @NonNull String assetUrl,
      @NonNull Map<String, String> httpHeaders,
      @Nullable String userAgent) {
    Future<StreamInfo> future =
        PROBE_EXECUTOR.submit(
            new Callable<StreamInfo>() {
              @Override
              public StreamInfo call() {
                return probeStreamInfoBlocking(assetUrl, httpHeaders, userAgent);
              }
            });
    try {
      return future.get(FUTURE_TIMEOUT_MS, TimeUnit.MILLISECONDS);
    } catch (TimeoutException exception) {
      future.cancel(true);
      Log.w(
          TAG,
          "Timed out probing transport stream info for " + summarizeUri(assetUrl),
          exception);
      return new StreamInfo(AudioProfile.UNKNOWN, VideoFrameRateProfile.UNKNOWN, Float.NaN, -1, -1);
    } catch (InterruptedException exception) {
      future.cancel(true);
      Thread.currentThread().interrupt();
      Log.w(
          TAG,
          "Interrupted while probing transport stream info for " + summarizeUri(assetUrl),
          exception);
      return new StreamInfo(AudioProfile.UNKNOWN, VideoFrameRateProfile.UNKNOWN, Float.NaN, -1, -1);
    } catch (ExecutionException exception) {
      Log.w(
          TAG,
          "Failed to probe transport stream info for " + summarizeUri(assetUrl),
          exception);
      return new StreamInfo(AudioProfile.UNKNOWN, VideoFrameRateProfile.UNKNOWN, Float.NaN, -1, -1);
    }
  }

  @NonNull
  private static StreamInfo probeStreamInfoBlocking(
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
        return new StreamInfo(AudioProfile.UNKNOWN, VideoFrameRateProfile.UNKNOWN, Float.NaN, -1, -1);
      }
      try (InputStream inputStream = connection.getInputStream()) {
        byte[] sample = readProbeSample(inputStream);
        StreamInfo streamInfo = inspectSampleInfo(sample, sample.length);
        Log.i(
            TAG,
            "Detected transport stream info "
                + streamInfo.toSummaryString()
                + " for "
                + summarizeUri(assetUrl));
        return streamInfo;
      }
    } catch (IOException exception) {
      Log.w(
          TAG,
          "I/O error probing transport stream info for " + summarizeUri(assetUrl),
          exception);
      return new StreamInfo(AudioProfile.UNKNOWN, VideoFrameRateProfile.UNKNOWN, Float.NaN, -1, -1);
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
    return inspectSampleInfo(sample, length).getAudioProfile();
  }

  @VisibleForTesting
  @NonNull
  static StreamInfo inspectSampleInfo(@NonNull byte[] sample, int length) {
    if (length < TRANSPORT_STREAM_PACKET_SIZE * REQUIRED_SYNC_PACKETS) {
      return new StreamInfo(AudioProfile.UNKNOWN, VideoFrameRateProfile.UNKNOWN, Float.NaN, -1, -1);
    }

    int syncOffset = findTransportStreamSyncOffset(sample, length);
    if (syncOffset < 0) {
      return new StreamInfo(AudioProfile.OTHER_STREAM, VideoFrameRateProfile.UNKNOWN, Float.NaN, -1, -1);
    }

    int programMapPid = -1;
    boolean foundProgramMap = false;
    boolean foundAudioDescriptor = false;
    int videoPid = -1;
    int videoStreamType = -1;
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
      ProgramMapInfo programMapInfo =
          parseProgramMapInfo(sample, payloadOffset, packetOffset + TRANSPORT_STREAM_PACKET_SIZE);
      if (programMapInfo.videoPid >= 0) {
        videoPid = programMapInfo.videoPid;
        videoStreamType = programMapInfo.videoStreamType;
      }
      if (programMapInfo.audioProfile == AudioProfile.AAC_ADTS) {
        float estimatedFramesPerSecond = estimateVideoFrameRate(sample, length, syncOffset, videoPid);
        return new StreamInfo(
            AudioProfile.AAC_ADTS,
            classifyFrameRate(estimatedFramesPerSecond),
            estimatedFramesPerSecond,
            videoPid,
            videoStreamType);
      }
      if (programMapInfo.audioProfile == AudioProfile.OTHER_AUDIO) {
        foundAudioDescriptor = true;
      }
    }

    float estimatedFramesPerSecond = estimateVideoFrameRate(sample, length, syncOffset, videoPid);
    AudioProfile audioProfile = AudioProfile.UNKNOWN;
    if (foundAudioDescriptor || foundProgramMap) {
      audioProfile = AudioProfile.OTHER_AUDIO;
    }
    return new StreamInfo(
        audioProfile,
        classifyFrameRate(estimatedFramesPerSecond),
        estimatedFramesPerSecond,
        videoPid,
        videoStreamType);
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
  private static ProgramMapInfo parseProgramMapInfo(
      @NonNull byte[] sample, int payloadOffset, int packetEnd) {
    int sectionOffset = skipPointerField(sample, payloadOffset, packetEnd);
    if (!isPsiHeaderAvailable(sample, sectionOffset, packetEnd) || (sample[sectionOffset] & 0xFF) != 0x02) {
      return new ProgramMapInfo(AudioProfile.UNKNOWN, -1, -1);
    }
    int sectionLength = parseSectionLength(sample, sectionOffset);
    int sectionEnd = Math.min(sectionOffset + 3 + sectionLength, packetEnd);
    if (sectionEnd - sectionOffset < 16) {
      return new ProgramMapInfo(AudioProfile.UNKNOWN, -1, -1);
    }
    int programInfoLength =
        ((sample[sectionOffset + 10] & 0x0F) << 8) | (sample[sectionOffset + 11] & 0xFF);
    int streamOffset = sectionOffset + 12 + programInfoLength;
    boolean foundAudioDescriptor = false;
    boolean foundAdtsAudio = false;
    int videoPid = -1;
    int videoStreamType = -1;
    while (streamOffset + 5 <= sectionEnd - 4) {
      int streamType = sample[streamOffset] & 0xFF;
      int elementaryPid =
          ((sample[streamOffset + 1] & 0x1F) << 8) | (sample[streamOffset + 2] & 0xFF);
      int esInfoLength = ((sample[streamOffset + 3] & 0x0F) << 8) | (sample[streamOffset + 4] & 0xFF);
      if (streamType == AAC_ADTS_STREAM_TYPE) {
        foundAdtsAudio = true;
      }
      if (isKnownAudioStreamType(streamType)) {
        foundAudioDescriptor = true;
      }
      if (videoPid < 0 && isKnownVideoStreamType(streamType)) {
        videoPid = elementaryPid;
        videoStreamType = streamType;
      }
      streamOffset += 5 + esInfoLength;
    }
    return new ProgramMapInfo(
        foundAdtsAudio
            ? AudioProfile.AAC_ADTS
            : (foundAudioDescriptor ? AudioProfile.OTHER_AUDIO : AudioProfile.UNKNOWN),
        videoPid,
        videoStreamType);
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

  private static boolean isKnownVideoStreamType(int streamType) {
    return streamType == H264_VIDEO_STREAM_TYPE
        || streamType == H265_VIDEO_STREAM_TYPE
        || streamType == MPEG2_VIDEO_STREAM_TYPE;
  }

  private static float estimateVideoFrameRate(
      @NonNull byte[] sample, int length, int syncOffset, int videoPid) {
    if (videoPid < 0) {
      return Float.NaN;
    }

    long previousPts = -1L;
    List<Long> deltas = new ArrayList<>();
    for (int packetOffset = syncOffset;
        packetOffset + TRANSPORT_STREAM_PACKET_SIZE <= length;
        packetOffset += TRANSPORT_STREAM_PACKET_SIZE) {
      if ((sample[packetOffset] & 0xFF) != 0x47) {
        continue;
      }
      int pid = ((sample[packetOffset + 1] & 0x1F) << 8) | (sample[packetOffset + 2] & 0xFF);
      if (pid != videoPid) {
        continue;
      }

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
      if (!payloadStart) {
        continue;
      }

      long currentPts =
          parsePesPresentationTimestamp(
              sample, payloadOffset, packetOffset + TRANSPORT_STREAM_PACKET_SIZE);
      if (currentPts < 0L) {
        continue;
      }
      if (previousPts >= 0L) {
        long delta = currentPts - previousPts;
        if (delta > 0L && delta <= PTS_CLOCK_HZ) {
          deltas.add(delta);
          if (deltas.size() >= 4) {
            break;
          }
        }
      }
      previousPts = currentPts;
    }

    if (deltas.isEmpty()) {
      return Float.NaN;
    }

    Collections.sort(deltas);
    long medianDelta = deltas.get(deltas.size() / 2);
    if (medianDelta <= 0L) {
      return Float.NaN;
    }
    return PTS_CLOCK_HZ / (float) medianDelta;
  }

  private static long parsePesPresentationTimestamp(
      @NonNull byte[] sample, int payloadOffset, int packetEnd) {
    if (payloadOffset + 14 > packetEnd) {
      return -1L;
    }
    if ((sample[payloadOffset] & 0xFF) != 0x00
        || (sample[payloadOffset + 1] & 0xFF) != 0x00
        || (sample[payloadOffset + 2] & 0xFF) != 0x01) {
      return -1L;
    }
    int ptsDtsFlags = (sample[payloadOffset + 7] >> 6) & 0x03;
    if (ptsDtsFlags != 0x02 && ptsDtsFlags != 0x03) {
      return -1L;
    }
    int ptsOffset = payloadOffset + 9;
    if (ptsOffset + 5 > packetEnd) {
      return -1L;
    }
    return (((long) ((sample[ptsOffset] >> 1) & 0x07)) << 30)
        | (((long) (sample[ptsOffset + 1] & 0xFF)) << 22)
        | (((long) ((sample[ptsOffset + 2] >> 1) & 0x7F)) << 15)
        | (((long) (sample[ptsOffset + 3] & 0xFF)) << 7)
        | ((sample[ptsOffset + 4] >> 1) & 0x7F);
  }

  @NonNull
  private static VideoFrameRateProfile classifyFrameRate(float framesPerSecond) {
    if (Float.isNaN(framesPerSecond) || framesPerSecond <= 0f) {
      return VideoFrameRateProfile.UNKNOWN;
    }
    if (framesPerSecond >= FPS_24ISH_MIN && framesPerSecond <= FPS_24ISH_MAX) {
      return VideoFrameRateProfile.FPS_24ISH;
    }
    return VideoFrameRateProfile.OTHER;
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
