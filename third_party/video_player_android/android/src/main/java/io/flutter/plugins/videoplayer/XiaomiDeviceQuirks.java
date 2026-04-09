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
  private static final int VLC_DEFAULT_NETWORK_CACHE_MS = 1500;
  private static final int VLC_DEFAULT_LIVE_CACHE_MS = 1500;
  private static final int VLC_TOLERANT_NETWORK_CACHE_MS = 2500;
  private static final int VLC_TOLERANT_LIVE_CACHE_MS = 2500;
  // Streams that consistently hit AudioTrack timestamp discontinuities in ExoPlayer but are
  // stable in VLC. Keep this list intentionally small and evidence-based.
  private static final Set<String> STREAM_IDS_REQUIRING_VLC_FALLBACK =
      new HashSet<>(Arrays.asList("95", "96", "119"));
  private static final Map<String, TransportStreamProbe.StreamInfo> STREAM_INFO_CACHE =
      new ConcurrentHashMap<>();

  private XiaomiDeviceQuirks() {}

  static final class VlcHardwareDecodingDecision {
    private final boolean disableHardwareDecoding;
    @NonNull private final String reason;

    VlcHardwareDecodingDecision(boolean disableHardwareDecoding, @NonNull String reason) {
      this.disableHardwareDecoding = disableHardwareDecoding;
      this.reason = reason;
    }

    boolean shouldDisableHardwareDecoding() {
      return disableHardwareDecoding;
    }

    @NonNull
    String getReason() {
      return reason;
    }
  }

  static final class VlcPlaybackProfile {
    private final int networkCachingMs;
    private final int liveCachingMs;
    @NonNull private final String reason;

    VlcPlaybackProfile(int networkCachingMs, int liveCachingMs, @NonNull String reason) {
      this.networkCachingMs = networkCachingMs;
      this.liveCachingMs = liveCachingMs;
      this.reason = reason;
    }

    int getNetworkCachingMs() {
      return networkCachingMs;
    }

    int getLiveCachingMs() {
      return liveCachingMs;
    }

    @NonNull
    String getReason() {
      return reason;
    }

    @NonNull
    List<String> createLibVlcOptions() {
      List<String> options = new ArrayList<>();
      options.add("--network-caching=" + networkCachingMs);
      options.add("--live-caching=" + liveCachingMs);
      return options;
    }

    void applyToMedia(@NonNull org.videolan.libvlc.Media media) {
      media.addOption(":network-caching=" + networkCachingMs);
      media.addOption(":live-caching=" + liveCachingMs);
    }
  }

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

    TransportStreamProbe.StreamInfo samsungStreamInfo = null;
    if (shouldApplySamsungAdtsFallback()) {
      samsungStreamInfo =
          getStreamInfo(
              assetUrl, httpHeaders != null ? httpHeaders : Collections.emptyMap(), userAgent);
    }

    String lastSegment = uri.getLastPathSegment();
    if (STREAM_IDS_REQUIRING_VLC_FALLBACK.contains(lastSegment)) {
      return VideoAsset.PlaybackDecision.libVlc(
          "stream_id_whitelist",
          "stream_id " + lastSegment + " is explicitly whitelisted",
          samsungStreamInfo != null ? samsungStreamInfo.toSummaryString() : null);
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

    if (samsungStreamInfo == null) {
      return VideoAsset.PlaybackDecision.exoPlayer("samsung_stream_probe", null);
    }

    TransportStreamProbe.AudioProfile detectedProfile = samsungStreamInfo.getAudioProfile();
    if (detectedProfile == TransportStreamProbe.AudioProfile.AAC_ADTS) {
      return VideoAsset.PlaybackDecision.libVlc(
          "samsung_adts_probe_cache",
          "cached Samsung stream probe detected AAC ADTS",
          samsungStreamInfo.toSummaryString());
    }

    return VideoAsset.PlaybackDecision.exoPlayer(
        "samsung_adts_probe_cache", samsungStreamInfo.toSummaryString());
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
  static VlcHardwareDecodingDecision getSamsungVlcHardwareDecodingDecision(@Nullable Uri uri) {
    if (!shouldApplySamsungAdtsFallback()) {
      return new VlcHardwareDecodingDecision(false, "non_samsung_device");
    }
    if (uri == null) {
      return new VlcHardwareDecodingDecision(false, "missing_uri");
    }

    TransportStreamProbe.StreamInfo streamInfo = STREAM_INFO_CACHE.get(uri.toString());
    if (streamInfo == null) {
      return new VlcHardwareDecodingDecision(false, "missing_cached_probe");
    }

    if (streamInfo.shouldDisableSamsungHardwareDecoding()) {
      return new VlcHardwareDecodingDecision(
          true,
          "cached_stream_probe matched Samsung HW decode guard ("
              + streamInfo.toSummaryString()
              + ")");
    }

    return new VlcHardwareDecodingDecision(
        false,
        "cached_stream_probe kept HW decode enabled ("
            + streamInfo.toSummaryString()
            + ")");
  }

  @Nullable
  static String getXtreamStreamId(@Nullable Uri uri) {
    if (uri == null) {
      return null;
    }
    return uri.getLastPathSegment();
  }

  @NonNull
  static VlcPlaybackProfile resolveVlcPlaybackProfile(
      @Nullable String assetUrl,
      @NonNull Map<String, String> httpHeaders,
      @Nullable String userAgent) {
    if (assetUrl == null || assetUrl.isEmpty()) {
      return defaultVlcPlaybackProfile("missing_asset_url");
    }

    Uri uri = Uri.parse(assetUrl);
    TransportStreamProbe.StreamInfo streamInfo = null;
    if (isSupportedXtreamLiveUrl(uri)) {
      streamInfo = getStreamInfo(assetUrl, httpHeaders, userAgent);
    }

    return resolveVlcPlaybackProfile(uri, streamInfo);
  }

  @NonNull
  static VlcPlaybackProfile resolveVlcPlaybackProfile(
      @Nullable Uri uri, @Nullable TransportStreamProbe.StreamInfo streamInfo) {
    String streamId = getXtreamStreamId(uri);
    if (streamId != null && STREAM_IDS_REQUIRING_VLC_FALLBACK.contains(streamId)) {
      return tolerantVlcPlaybackProfile("whitelisted_stream_id_" + streamId);
    }

    if (streamInfo != null
        && streamInfo.getAudioProfile() == TransportStreamProbe.AudioProfile.AAC_ADTS) {
      return tolerantVlcPlaybackProfile(
          "aac_adts_transport_stream(" + streamInfo.toSummaryString() + ")");
    }

    return defaultVlcPlaybackProfile("generic_live_fallback");
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

  @NonNull
  private static TransportStreamProbe.StreamInfo getStreamInfo(
      @NonNull String assetUrl,
      @NonNull Map<String, String> httpHeaders,
      @Nullable String userAgent) {
    TransportStreamProbe.StreamInfo cachedStreamInfo = STREAM_INFO_CACHE.get(assetUrl);
    if (cachedStreamInfo != null) {
      return cachedStreamInfo;
    }

    TransportStreamProbe.StreamInfo detectedStreamInfo =
        TransportStreamProbe.probeStreamInfo(assetUrl, httpHeaders, userAgent);
    if (detectedStreamInfo.isCacheable()) {
      STREAM_INFO_CACHE.put(assetUrl, detectedStreamInfo);
    }
    return detectedStreamInfo;
  }

  @NonNull
  private static VlcPlaybackProfile defaultVlcPlaybackProfile(@NonNull String reason) {
    return new VlcPlaybackProfile(
        VLC_DEFAULT_NETWORK_CACHE_MS, VLC_DEFAULT_LIVE_CACHE_MS, reason);
  }

  @NonNull
  private static VlcPlaybackProfile tolerantVlcPlaybackProfile(@NonNull String reason) {
    return new VlcPlaybackProfile(
        VLC_TOLERANT_NETWORK_CACHE_MS, VLC_TOLERANT_LIVE_CACHE_MS, reason);
  }
}
