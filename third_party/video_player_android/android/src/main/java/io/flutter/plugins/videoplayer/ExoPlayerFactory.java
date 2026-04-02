// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.media3.common.util.Log;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.DefaultRenderersFactory;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.RenderersFactory;
import androidx.media3.exoplayer.audio.DefaultAudioSink;
import androidx.media3.exoplayer.audio.AudioSink;
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector;

/** Builds ExoPlayer with device-specific quirks that the app needs on Android. */
@UnstableApi
public final class ExoPlayerFactory {
  private static final String TAG = "TiviExoPlayerFactory";

  private ExoPlayerFactory() {}

  @NonNull
  public static ExoPlayer create(@NonNull Context context, @NonNull VideoAsset asset) {
    DefaultTrackSelector trackSelector = new DefaultTrackSelector(context);
    RenderersFactory renderersFactory = new DefaultRenderersFactory(context);
    ExoPlayer.Builder builder =
        new ExoPlayer.Builder(context)
            .setTrackSelector(trackSelector)
            .setMediaSourceFactory(asset.getMediaSourceFactory(context));

    if (XiaomiDeviceQuirks.shouldApply()) {
      Log.i(TAG, "Applying Xiaomi audio sink workaround profile.");
      renderersFactory =
          new XiaomiRenderersFactory(context)
              .forceDisableMediaCodecAsynchronousQueueing()
              .setEnableDecoderFallback(true)
              .setEnableAudioTrackPlaybackParams(false)
              .setEnableAudioOutputPlaybackParameters(false);
    }

    return builder.setRenderersFactory(renderersFactory).build();
  }

  private static final class XiaomiRenderersFactory extends DefaultRenderersFactory {
    XiaomiRenderersFactory(@NonNull Context context) {
      super(context);
    }

    @Override
    protected AudioSink buildAudioSink(
        @NonNull Context context,
        boolean enableFloatOutput,
        boolean enableAudioTrackPlaybackParams) {
      DefaultAudioSink audioSink =
          new DefaultAudioSink.Builder(context)
              .setEnableFloatOutput(enableFloatOutput)
              .setEnableAudioTrackPlaybackParams(enableAudioTrackPlaybackParams)
              .setAudioTrackBufferSizeProvider(
                  XiaomiDeviceQuirks.createAudioTrackBufferSizeProvider())
              .build();
      return new XiaomiQuirkAudioSink(
          audioSink);
    }
  }
}
