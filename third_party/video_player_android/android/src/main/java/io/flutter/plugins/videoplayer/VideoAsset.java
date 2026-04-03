// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.common.MediaItem;
import androidx.media3.exoplayer.source.MediaSource;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

/** A video to be played by {@link VideoPlayer}. */
public abstract class VideoAsset {
  static final class PlaybackDecision {
    private final boolean useVlcFallback;
    @NonNull private final String engineName;
    @NonNull private final String appliedRule;
    @Nullable private final String fallbackReason;
    @Nullable private final String probeResult;

    private PlaybackDecision(
        boolean useVlcFallback,
        @NonNull String engineName,
        @NonNull String appliedRule,
        @Nullable String fallbackReason,
        @Nullable String probeResult) {
      this.useVlcFallback = useVlcFallback;
      this.engineName = engineName;
      this.appliedRule = appliedRule;
      this.fallbackReason = fallbackReason;
      this.probeResult = probeResult;
    }

    @NonNull
    static PlaybackDecision exoPlayer(@NonNull String appliedRule, @Nullable String probeResult) {
      return new PlaybackDecision(false, "exo_player", appliedRule, null, probeResult);
    }

    @NonNull
    static PlaybackDecision libVlc(
        @NonNull String appliedRule,
        @NonNull String fallbackReason,
        @Nullable String probeResult) {
      return new PlaybackDecision(true, "lib_vlc", appliedRule, fallbackReason, probeResult);
    }

    boolean shouldUseVlcFallback() {
      return useVlcFallback;
    }

    @NonNull
    String getEngineName() {
      return engineName;
    }

    @NonNull
    String getAppliedRule() {
      return appliedRule;
    }

    @Nullable
    String getFallbackReason() {
      return fallbackReason;
    }

    @Nullable
    String getProbeResult() {
      return probeResult;
    }
  }

  /**
   * Returns an asset from a local {@code asset:///} URL, i.e. an on-device asset.
   *
   * @param assetUrl local asset, beginning in {@code asset:///}.
   * @return the asset.
   */
  @NonNull
  static VideoAsset fromAssetUrl(@NonNull String assetUrl) {
    if (!assetUrl.startsWith("asset:///")) {
      throw new IllegalArgumentException("assetUrl must start with 'asset:///'");
    }
    return new LocalVideoAsset(assetUrl);
  }

  /**
   * Returns an asset from a remote URL.
   *
   * @param remoteUrl remote asset, i.e. typically beginning with {@code https://} or similar.
   * @param streamingFormat which streaming format, provided as a hint if able.
   * @param httpHeaders HTTP headers to set for a request.
   * @return the asset.
   */
  @NonNull
  static VideoAsset fromRemoteUrl(
      @Nullable String remoteUrl,
      @NonNull StreamingFormat streamingFormat,
      @NonNull Map<String, String> httpHeaders,
      @Nullable String userAgent) {
    return new HttpVideoAsset(remoteUrl, streamingFormat, new HashMap<>(httpHeaders), userAgent);
  }

  /**
   * Returns an asset from a RTSP URL.
   *
   * @param rtspUrl remote asset, beginning with {@code rtsp://}.
   * @return the asset.
   */
  @NonNull
  static VideoAsset fromRtspUrl(@NonNull String rtspUrl) {
    if (!rtspUrl.startsWith("rtsp://")) {
      throw new IllegalArgumentException("rtspUrl must start with 'rtsp://'");
    }
    return new RtspVideoAsset(rtspUrl);
  }

  @Nullable protected final String assetUrl;

  protected VideoAsset(@Nullable String assetUrl) {
    this.assetUrl = assetUrl;
  }

  /**
   * Returns the configured media item to be played.
   *
   * @return media item.
   */
  @NonNull
  public abstract MediaItem getMediaItem();

  /**
   * Returns the configured media source factory, if needed for this asset type.
   *
   * @param context application context.
   * @return configured factory, or {@code null} if not needed for this asset type.
   */
  @NonNull
  public abstract MediaSource.Factory getMediaSourceFactory(@NonNull Context context);

  @Nullable
  public final String getAssetUrl() {
    return assetUrl;
  }

  @NonNull
  public Map<String, String> getHttpHeaders() {
    return Collections.emptyMap();
  }

  @Nullable
  public String getUserAgent() {
    return null;
  }

  @NonNull
  public PlaybackDecision getPlaybackDecision() {
    return PlaybackDecision.exoPlayer("default_exoplayer", null);
  }

  public boolean shouldUseVlcFallback() {
    return getPlaybackDecision().shouldUseVlcFallback();
  }

  /** Streaming formats that can be provided to the video player as a hint. */
  enum StreamingFormat {
    /** Default, if the format is either not known or not another valid format. */
    UNKNOWN,

    /** Smooth Streaming. */
    SMOOTH,

    /** MPEG-DASH (Dynamic Adaptive over HTTP). */
    DYNAMIC_ADAPTIVE,

    /** HTTP Live Streaming (HLS). */
    HTTP_LIVE
  }
}
