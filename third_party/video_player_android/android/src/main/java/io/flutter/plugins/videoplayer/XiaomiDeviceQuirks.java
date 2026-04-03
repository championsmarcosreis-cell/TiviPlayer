// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import android.net.Uri;
import android.os.Build;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.common.AudioAttributes;
import androidx.media3.common.C;
import androidx.media3.exoplayer.audio.DefaultAudioSink;
import androidx.media3.exoplayer.audio.DefaultAudioTrackBufferSizeProvider;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/** Device-specific playback quirks used by the local Android player override. */
final class XiaomiDeviceQuirks {
  private static final String TAG = "TiviDeviceQuirks";
  private static final int XIAOMI_MIN_PCM_BUFFER_DURATION_US = 100_000;
  private static final int XIAOMI_MAX_PCM_BUFFER_DURATION_US = 150_000;
  private static final int XIAOMI_PCM_BUFFER_MULTIPLICATION_FACTOR = 2;
  // Streams that consistently hit AudioTrack timestamp discontinuities in ExoPlayer but are
  // stable in VLC. Keep this list intentionally small and evidence-based.
  private static final Set<String> STREAM_IDS_REQUIRING_VLC_FALLBACK =
      new HashSet<>(Arrays.asList("95", "96", "119"));
  private static final Map<String, TransportStreamProbe.AudioProfile> SAMSUNG_STREAM_AUDIO_CACHE =
      new ConcurrentHashMap<>();

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

  @NonNull
  static VideoAsset.PlaybackDecision resolvePlaybackDecision(
      @Nullable String assetUrl,
      @NonNull VideoAsset.StreamingFormat streamingFormat,
      @NonNull Map<String, String> httpHeaders,
      @Nullable String userAgent) {
    if (assetUrl == null || streamingFormat != VideoAsset.StreamingFormat.UNKNOWN) {
      return VideoAsset.PlaybackDecision.exoPlayer("explicit_streaming_format", null);
    }

    Uri uri = Uri.parse(assetUrl);
    if (!isSupportedXtreamLiveUrl(uri)) {
      return VideoAsset.PlaybackDecision.exoPlayer("non_xtream_live_stream", null);
    }

    String lastSegment = uri.getLastPathSegment();
    if (STREAM_IDS_REQUIRING_VLC_FALLBACK.contains(lastSegment)) {
      return VideoAsset.PlaybackDecision.libVlc(
          "stream_id_whitelist",
          "stream_id " + lastSegment + " is explicitly whitelisted",
          null);
    }

    if (shouldApply()) {
      return VideoAsset.PlaybackDecision.libVlc(
          "xiaomi_brand_fallback",
          "device brand requires Xiaomi/Redmi/Poco fallback",
          null);
    }

    if (!shouldApplySamsungAdtsFallback()) {
      return VideoAsset.PlaybackDecision.exoPlayer("no_matching_fallback_rule", null);
    }

    TransportStreamProbe.AudioProfile cachedProfile = SAMSUNG_STREAM_AUDIO_CACHE.get(assetUrl);
    if (cachedProfile == TransportStreamProbe.AudioProfile.AAC_ADTS) {
      return VideoAsset.PlaybackDecision.libVlc(
          "samsung_adts_probe_cache",
          "cached Samsung AAC ADTS detection",
          cachedProfile.name());
    }
    if (cachedProfile == TransportStreamProbe.AudioProfile.OTHER_AUDIO) {
      return VideoAsset.PlaybackDecision.exoPlayer(
          "samsung_adts_probe_cache", cachedProfile.name());
    }

    TransportStreamProbe.AudioProfile detectedProfile =
        TransportStreamProbe.probeAudioProfile(
            assetUrl,
            httpHeaders != null ? httpHeaders : Collections.emptyMap(),
            userAgent);
    if (detectedProfile.isCacheable()) {
      SAMSUNG_STREAM_AUDIO_CACHE.put(assetUrl, detectedProfile);
    }
    if (detectedProfile == TransportStreamProbe.AudioProfile.AAC_ADTS) {
      return VideoAsset.PlaybackDecision.libVlc(
          "samsung_adts_probe",
          "Samsung probe detected AAC ADTS",
          detectedProfile.name());
    }

    return VideoAsset.PlaybackDecision.exoPlayer("samsung_adts_probe", detectedProfile.name());
  }

  static boolean shouldUseVlcFallback(
      @Nullable String assetUrl,
      @NonNull VideoAsset.StreamingFormat streamingFormat,
      @NonNull Map<String, String> httpHeaders,
      @Nullable String userAgent) {
    return resolvePlaybackDecision(assetUrl, streamingFormat, httpHeaders, userAgent)
        .shouldUseVlcFallback();
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

  private static boolean shouldApplySamsungAdtsFallback() {
    return matchesSamsungBrand(Build.MANUFACTURER) || matchesSamsungBrand(Build.BRAND);
  }

  private static boolean matchesSamsungBrand(String value) {
    if (value == null || value.isEmpty()) {
      return false;
    }

    String normalized = value.toLowerCase(Locale.US);
    return normalized.contains("samsung");
  }

  private static boolean isSupportedXtreamLiveUrl(@NonNull Uri uri) {
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
    return segmentCount >= 3;
  }
}
