package io.flutter.plugins.videoplayer;

import androidx.annotation.Nullable;
import androidx.media3.exoplayer.ExoPlayer;

/** Common contract for Android video player backends used by the plugin. */
public interface ManagedVideoPlayer extends VideoPlayerInstanceApi {
  /** A handler to run when dispose is called. */
  interface DisposeHandler {
    void onDispose();
  }

  void setDisposeHandler(@Nullable DisposeHandler handler);

  void dispose();

  @Nullable
  ExoPlayer getExoPlayer();
}
