// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import android.net.Uri;
import android.os.Build;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.common.AudioAttributes;
import androidx.media3.common.C;
import androidx.media3.exoplayer.audio.DefaultAudioSink;
import androidx.media3.exoplayer.audio.DefaultAudioTrackBufferSizeProvider;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/** Xiaomi/Redmi/Poco-specific playback quirks used by the local Android player override. */
final class XiaomiDeviceQuirks {
  private static final int XIAOMI_MIN_PCM_BUFFER_DURATION_US = 100_000;
  private static final int XIAOMI_MAX_PCM_BUFFER_DURATION_US = 150_000;
  private static final int XIAOMI_PCM_BUFFER_MULTIPLICATION_FACTOR = 2;
  // Streams that consistently hit AudioTrack timestamp discontinuities in ExoPlayer but are
  // stable in VLC. Keep this list intentionally small and evidence-based.
  private static final Set<String> STREAM_IDS_REQUIRING_VLC_FALLBACK =
      new HashSet<>(Arrays.asList("95", "96", "119"));

  private XiaomiDeviceQuirks() {}

  static boolean shouldApply() {
    return matchesXiaomiBrand(Build.MANUFACTURER) || matchesXiaomiBrand(Build.BRAND);
  }

  @NonNull
  static DefaultAudioSink.AudioTrackBufferSizeProvider createAudioTrackBufferSizeProvider() {
    return new DefaultAudioTrackBufferSizeProvider.Builder()
        .setMinPcmBufferDurationUs(XIAOMI_MIN_PCM_BUFFER_DURATION_US)
        .setMaxPcmBufferDurationUs(XIAOMI_MAX_PCM_BUFFER_DURATION_US)
        .setPcmBufferMultiplicationFactor(XIAOMI_PCM_BUFFER_MULTIPLICATION_FACTOR)
        .build();
  }

  @NonNull
  static AudioAttributes createAudioAttributes() {
    return new AudioAttributes.Builder()
        .setUsage(C.USAGE_MEDIA)
        .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
        .build();
  }

  static boolean shouldUseVlcFallback(
      @Nullable String assetUrl, @NonNull VideoAsset.StreamingFormat streamingFormat) {
    if (assetUrl == null || streamingFormat != VideoAsset.StreamingFormat.UNKNOWN) {
      return false;
    }

    Uri uri = Uri.parse(assetUrl);
    String scheme = uri.getScheme();
    if (scheme == null) {
      return false;
    }

    String normalizedScheme = scheme.toLowerCase(Locale.US);
    if (!normalizedScheme.equals("http") && !normalizedScheme.equals("https")) {
      return false;
    }

    String lastSegment = uri.getLastPathSegment();
    if (lastSegment == null || lastSegment.isEmpty() || lastSegment.contains(".")) {
      return false;
    }

    for (int i = 0; i < lastSegment.length(); i++) {
      if (!Character.isDigit(lastSegment.charAt(i))) {
        return false;
      }
    }

    String path = uri.getPath();
    if (path == null || path.isEmpty()) {
      return false;
    }

    int segmentCount = 0;
    for (String segment : path.split("/")) {
      if (!segment.isEmpty()) {
        segmentCount++;
      }
    }
    if (segmentCount < 3) {
      return false;
    }

    if (STREAM_IDS_REQUIRING_VLC_FALLBACK.contains(lastSegment)) {
      return true;
    }

    return shouldApply();
  }

  @NonNull
  static List<String> createVlcOptions() {
    List<String> options = new ArrayList<>();
    options.add("--network-caching=400");
    options.add("--live-caching=400");
    options.add("--clock-jitter=0");
    options.add("--clock-synchro=0");
    return options;
  }

  private static boolean matchesXiaomiBrand(String value) {
    if (value == null || value.isEmpty()) {
      return false;
    }

    String normalized = value.toLowerCase(Locale.US);
    return normalized.contains("xiaomi")
        || normalized.contains("redmi")
        || normalized.contains("poco");
  }
}
