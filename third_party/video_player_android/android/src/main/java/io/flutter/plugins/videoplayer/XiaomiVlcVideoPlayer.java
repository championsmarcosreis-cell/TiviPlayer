package io.flutter.plugins.videoplayer;

import android.content.Context;
import android.net.Uri;
import android.util.Log;
import android.view.Surface;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.common.MediaItem;
import androidx.media3.exoplayer.ExoPlayer;
import io.flutter.view.TextureRegistry.SurfaceProducer;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.videolan.libvlc.LibVLC;
import org.videolan.libvlc.Media;
import org.videolan.libvlc.MediaPlayer;
import org.videolan.libvlc.interfaces.IMedia;
import org.videolan.libvlc.interfaces.IVLCVout;

/**
 * Xiaomi-only playback fallback that swaps ExoPlayer AAC decoding for LibVLC on problematic live
 * progressive Xtream URLs.
 */
public final class XiaomiVlcVideoPlayer
    implements ManagedVideoPlayer,
        SurfaceProducer.Callback,
        IVLCVout.Callback,
        IVLCVout.OnNewVideoLayoutListener {
  private static final String TAG = "TiviXiaomiVlc";
  private static final int FALLBACK_VIDEO_WIDTH = 1280;
  private static final int FALLBACK_VIDEO_HEIGHT = 720;
  private static final int LIVE_CACHE_MS = 1200;
  private static final int MIN_USABLE_SURFACE_DIMENSION = 16;

  @NonNull private final VideoPlayerCallbacks videoPlayerEvents;
  @NonNull private final SurfaceProducer surfaceProducer;
  @NonNull private final Uri uri;
  @NonNull private final LibVLC libVlc;
  @NonNull private final MediaPlayer mediaPlayer;

  @Nullable private DisposeHandler disposeHandler;
  @Nullable private Surface attachedSurface;
  @Nullable private static volatile String lastPreloadedVlcClassName;
  @NonNull private static final Object[] VLC_KEEPERS = createVlcKeepers();
  private int attachedSurfaceWidth;
  private int attachedSurfaceHeight;
  private boolean initialized;
  private boolean looping;
  private long currentPositionMs;
  private long durationMs;
  private int videoWidth;
  private int videoHeight;
  private float lastBufferingPercent;
  private boolean playbackStarted;
  private boolean pauseRequested;

  @NonNull
  public static XiaomiVlcVideoPlayer create(
      @NonNull Context context,
      @NonNull VideoPlayerCallbacks events,
      @NonNull SurfaceProducer surfaceProducer,
      @NonNull VideoAsset asset,
      @NonNull VideoPlayerOptions options) {
    return new XiaomiVlcVideoPlayer(context, events, surfaceProducer, asset, options);
  }

  private XiaomiVlcVideoPlayer(
      @NonNull Context context,
      @NonNull VideoPlayerCallbacks events,
      @NonNull SurfaceProducer surfaceProducer,
      @NonNull VideoAsset asset,
      @NonNull VideoPlayerOptions options) {
    this.videoPlayerEvents = events;
    this.surfaceProducer = surfaceProducer;
    MediaItem mediaItem = asset.getMediaItem();
    MediaItem.LocalConfiguration localConfiguration = mediaItem.localConfiguration;
    if (localConfiguration == null) {
      throw new IllegalArgumentException("Xiaomi VLC fallback requires a network media item.");
    }
    this.uri = localConfiguration.uri;
    preloadVlcClasses();
    this.libVlc = new LibVLC(context, XiaomiDeviceQuirks.createVlcOptions());
    String userAgent = asset.getUserAgent();
    if (userAgent != null && !userAgent.isEmpty()) {
      libVlc.setUserAgent(userAgent, userAgent);
    }
    this.mediaPlayer = new MediaPlayer(libVlc);
    resetVideoAspectRatio();
    this.mediaPlayer.setEventListener(this::onPlayerEvent);

    surfaceProducer.setCallback(this);
    attachSurface(/* forceNewSurface= */ false);
    prepareAndPlay(asset, options);
  }

  private static void preloadVlcClasses() {
    // LibVLC's JNI bootstrap resolves these classes during library load in release builds.
    Class<?>[] requiredClasses =
        new Class<?>[] {
          IMedia.Event.class,
          IMedia.Type.class,
          IMedia.Meta.class,
          IMedia.State.class,
          IMedia.Parse.class,
          IMedia.ParsedStatus.class,
          IMedia.Track.class,
          IMedia.Track.Type.class,
          IMedia.AudioTrack.class,
          IMedia.VideoTrack.class,
          IMedia.VideoTrack.Orientation.class,
          IMedia.VideoTrack.Projection.class,
          IMedia.SubtitleTrack.class,
          IMedia.UnknownTrack.class,
          IMedia.Slave.class,
          IMedia.Slave.Type.class,
          IMedia.Stats.class,
          MediaPlayer.Event.class,
          MediaPlayer.Position.class,
          MediaPlayer.Navigate.class,
          MediaPlayer.Title.class,
          MediaPlayer.Chapter.class,
          MediaPlayer.TrackDescription.class,
          MediaPlayer.Equalizer.class
        };
    if (requiredClasses.length == 0) {
      Log.w(TAG, "LibVLC preloading set is unexpectedly empty.");
      return;
    }
    for (Class<?> requiredClass : requiredClasses) {
      lastPreloadedVlcClassName = requiredClass.getName();
    }
    Log.d(
        TAG,
        "Preloaded "
            + requiredClasses.length
            + " LibVLC classes before JNI load; last="
            + lastPreloadedVlcClassName);
    if (VLC_KEEPERS.length == 0) {
      Log.w(TAG, "LibVLC keeper set is unexpectedly empty.");
    }
  }

  @NonNull
  private static Object[] createVlcKeepers() {
    return new Object[] {
      new IMedia.AudioTrack("", "", 0, 0, 0, 0, 0, "", "", 2, 48000),
      new IMedia.VideoTrack("", "", 0, 0, 0, 0, 0, "", "", 1, 1, 1, 1, 30, 1, 0, 0),
      new IMedia.SubtitleTrack("", "", 0, 0, 0, 0, 0, "", "", "utf-8"),
      new IMedia.UnknownTrack("", "", 0, 0, 0, 0, 0, "", ""),
      new IMedia.Slave(IMedia.Slave.Type.Audio, 0, "about:blank"),
      new IMedia.Stats(0, 0f, 0, 0f, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0f)
    };
  }

  private void prepareAndPlay(@NonNull VideoAsset asset, @NonNull VideoPlayerOptions options) {
    Media media = new Media(libVlc, uri);
    media.setHWDecoderEnabled(true, false);
    media.addOption(":network-caching=" + LIVE_CACHE_MS);
    media.addOption(":live-caching=" + LIVE_CACHE_MS);
    media.addOption(":clock-jitter=0");
    media.addOption(":clock-synchro=0");
    String userAgent = asset.getUserAgent();
    if (userAgent != null && !userAgent.isEmpty()) {
      media.addOption(":http-user-agent=" + userAgent);
    }
    for (Map.Entry<String, String> header : asset.getHttpHeaders().entrySet()) {
      media.addOption(":http-header=" + header.getKey() + "=" + header.getValue());
    }
    mediaPlayer.setMedia(media);
    media.release();
    setVolume(options.mixWithOthers ? 1.0 : 1.0);
    videoPlayerEvents.onPlaybackStateChanged(PlatformPlaybackState.BUFFERING);
    mediaPlayer.play();
    Log.i(TAG, "Started LibVLC fallback for Xiaomi URL " + uri);
  }

  private void onPlayerEvent(@NonNull MediaPlayer.Event event) {
    switch (event.type) {
      case MediaPlayer.Event.Opening:
        videoPlayerEvents.onPlaybackStateChanged(PlatformPlaybackState.BUFFERING);
        break;
      case MediaPlayer.Event.Buffering:
        lastBufferingPercent = event.getBuffering();
        // LibVLC can keep emitting buffering callbacks during live playback. Forwarding those as
        // a sticky buffering state makes Flutter trigger runtime recovery after 12s, which looks
        // like the channel is pausing/reopening on Xiaomi.
        if (!playbackStarted) {
          videoPlayerEvents.onPlaybackStateChanged(PlatformPlaybackState.BUFFERING);
        }
        break;
      case MediaPlayer.Event.Playing:
        playbackStarted = true;
        pauseRequested = false;
        updateDuration();
        updateSurfaceLayout();
        maybeSendInitialized(true);
        videoPlayerEvents.onPlaybackStateChanged(PlatformPlaybackState.READY);
        videoPlayerEvents.onIsPlayingStateUpdate(true);
        break;
      case MediaPlayer.Event.Paused:
        if (pauseRequested || !playbackStarted) {
          maybeSendInitialized(true);
          videoPlayerEvents.onPlaybackStateChanged(PlatformPlaybackState.READY);
          videoPlayerEvents.onIsPlayingStateUpdate(false);
        } else {
          Log.d(TAG, "Ignoring transient LibVLC pause while live playback should stay active.");
        }
        break;
      case MediaPlayer.Event.Stopped:
        playbackStarted = false;
        pauseRequested = false;
        videoPlayerEvents.onPlaybackStateChanged(PlatformPlaybackState.IDLE);
        videoPlayerEvents.onIsPlayingStateUpdate(false);
        break;
      case MediaPlayer.Event.EndReached:
        playbackStarted = false;
        pauseRequested = false;
        videoPlayerEvents.onPlaybackStateChanged(PlatformPlaybackState.ENDED);
        videoPlayerEvents.onIsPlayingStateUpdate(false);
        if (looping) {
          mediaPlayer.play();
        }
        break;
      case MediaPlayer.Event.EncounteredError:
        playbackStarted = false;
        pauseRequested = false;
        videoPlayerEvents.onIsPlayingStateUpdate(false);
        videoPlayerEvents.onError(
            "VideoError", "Xiaomi VLC fallback failed for stream " + uri, null);
        break;
      case MediaPlayer.Event.TimeChanged:
        currentPositionMs = event.getTimeChanged();
        break;
      case MediaPlayer.Event.LengthChanged:
        durationMs = Math.max(0L, event.getLengthChanged());
        maybeSendInitialized(false);
        break;
      case MediaPlayer.Event.Vout:
      case MediaPlayer.Event.ESAdded:
      case MediaPlayer.Event.ESSelected:
        updateVideoMetrics();
        updateSurfaceLayout();
        maybeSendInitialized(false);
        break;
      default:
        break;
    }
  }

  private void updateDuration() {
    durationMs = Math.max(durationMs, Math.max(0L, mediaPlayer.getLength()));
  }

  private void updateVideoMetrics() {
    IMedia.VideoTrack videoTrack = mediaPlayer.getCurrentVideoTrack();
    if (videoTrack == null) {
      return;
    }
    updateReportedVideoSize(
        normalizeVideoWidth(videoTrack.width, videoTrack.height, videoTrack.sarNum, videoTrack.sarDen),
        normalizeVideoHeight(videoTrack.width, videoTrack.height),
        "track");
    applyVideoScaling();
  }

  private void resetVideoAspectRatio() {
    mediaPlayer.setVideoScale(MediaPlayer.ScaleType.SURFACE_BEST_FIT);
    mediaPlayer.setScale(0f);
    mediaPlayer.setAspectRatio(null);
  }

  private void applyVideoScaling() {
    // Let LibVLC preserve the video's aspect ratio inside the current output window instead of
    // forcing the output surface to mimic transient layout callbacks.
    mediaPlayer.setVideoScale(MediaPlayer.ScaleType.SURFACE_BEST_FIT);
    mediaPlayer.setScale(0f);
    mediaPlayer.setAspectRatio(null);
  }

  private void updateReportedVideoSize(int width, int height, @NonNull String source) {
    if (width <= 0 || height <= 0) {
      return;
    }
    if (videoWidth == width && videoHeight == height) {
      return;
    }
    videoWidth = width;
    videoHeight = height;
    Log.i(TAG, "Resolved LibVLC video size via " + source + " to " + width + "x" + height + " for " + uri);
  }

  private void maybeSendInitialized(boolean allowEmptySize) {
    if (initialized) {
      return;
    }
    updateVideoMetrics();
    updateDuration();
    if (!allowEmptySize && videoWidth <= 0 && videoHeight <= 0) {
      return;
    }
    int initializedWidth = videoWidth;
    int initializedHeight = videoHeight;
    if (initializedWidth <= 0 || initializedHeight <= 0) {
      initializedWidth = FALLBACK_VIDEO_WIDTH;
      initializedHeight = FALLBACK_VIDEO_HEIGHT;
      Log.i(
          TAG,
          "Using fallback initialized video size "
              + initializedWidth
              + "x"
              + initializedHeight
              + " for "
              + uri);
    }
    initialized = true;
    videoPlayerEvents.onInitialized(
        initializedWidth, initializedHeight, Math.max(durationMs, 0L), 0);
  }

  private int normalizeVideoWidth(int width, int height, int sarNum, int sarDen) {
    int normalizedWidth = normalizeVideoHeight(width, height);
    if (width > 0) {
      normalizedWidth = width;
    }
    if (sarNum > 0 && sarDen > 0) {
      normalizedWidth = Math.round(normalizedWidth * (sarNum / (float) sarDen));
    }
    return Math.max(normalizedWidth, 0);
  }

  private int normalizeVideoHeight(int width, int height) {
    int normalizedHeight = height > 0 ? height : width;
    return Math.max(normalizedHeight, 0);
  }

  private int resolveTargetWidth() {
    if (videoWidth > 0) {
      return videoWidth;
    }
    return FALLBACK_VIDEO_WIDTH;
  }

  private int resolveTargetHeight() {
    if (videoHeight > 0) {
      return videoHeight;
    }
    return FALLBACK_VIDEO_HEIGHT;
  }

  private boolean isUsableSurfaceDimension(int dimension) {
    return dimension >= MIN_USABLE_SURFACE_DIMENSION;
  }

  private void updateSurfaceLayout() {
    if (attachedSurface == null) {
      return;
    }
    int targetWidth = Math.max(resolveTargetWidth(), 1);
    int targetHeight = Math.max(resolveTargetHeight(), 1);
    if (attachedSurfaceWidth == targetWidth && attachedSurfaceHeight == targetHeight) {
      return;
    }
    attachedSurfaceWidth = targetWidth;
    attachedSurfaceHeight = targetHeight;
    surfaceProducer.setSize(targetWidth, targetHeight);
    IVLCVout vout = mediaPlayer.getVLCVout();
    if (vout.areViewsAttached()) {
      vout.setWindowSize(targetWidth, targetHeight);
      applyVideoScaling();
      mediaPlayer.updateVideoSurfaces();
    }
    surfaceProducer.scheduleFrame();
    Log.i(
        TAG,
        "Updated LibVLC output window to "
            + targetWidth
            + "x"
            + targetHeight
            + " (reported video "
            + videoWidth
            + "x"
            + videoHeight
            + ") for "
            + uri);
  }

  private void attachSurface(boolean forceNewSurface) {
    int targetWidth = Math.max(resolveTargetWidth(), 1);
    int targetHeight = Math.max(resolveTargetHeight(), 1);
    surfaceProducer.setSize(targetWidth, targetHeight);
    Surface surface =
        forceNewSurface ? surfaceProducer.getForcedNewSurface() : surfaceProducer.getSurface();
    if (surface == null) {
      Log.w(TAG, "LibVLC surface is null after resize request " + targetWidth + "x" + targetHeight);
      return;
    }
    if (surface == attachedSurface
        && attachedSurfaceWidth == targetWidth
        && attachedSurfaceHeight == targetHeight
        && mediaPlayer.getVLCVout().areViewsAttached()) {
      return;
    }
    detachSurface();
    attachedSurface = surface;
    attachedSurfaceWidth = targetWidth;
    attachedSurfaceHeight = targetHeight;
    IVLCVout vout = mediaPlayer.getVLCVout();
    vout.setVideoSurface(surface, null);
    vout.setWindowSize(targetWidth, targetHeight);
    vout.addCallback(this);
    vout.attachViews(this);
    applyVideoScaling();
    mediaPlayer.updateVideoSurfaces();
    surfaceProducer.scheduleFrame();
    Log.i(
        TAG,
        "Attached LibVLC surface with output window "
            + targetWidth
            + "x"
            + targetHeight
            + " for "
            + uri);
  }

  private void detachSurface() {
    IVLCVout vout = mediaPlayer.getVLCVout();
    vout.removeCallback(this);
    if (vout.areViewsAttached()) {
      vout.detachViews();
    }
    attachedSurface = null;
    attachedSurfaceWidth = 0;
    attachedSurfaceHeight = 0;
  }

  @Override
  public void setDisposeHandler(@Nullable DisposeHandler handler) {
    disposeHandler = handler;
  }

  @Override
  public void play() {
    pauseRequested = false;
    mediaPlayer.play();
  }

  @Override
  public void pause() {
    pauseRequested = true;
    mediaPlayer.pause();
  }

  @Override
  public void setLooping(boolean looping) {
    this.looping = looping;
  }

  @Override
  public void setVolume(double volume) {
    double bracketedValue = Math.max(0.0, Math.min(1.0, volume));
    mediaPlayer.setVolume((int) Math.round(bracketedValue * 100.0));
  }

  @Override
  public void setPlaybackSpeed(double speed) {
    mediaPlayer.setRate((float) speed);
  }

  @Override
  public long getCurrentPosition() {
    currentPositionMs = Math.max(currentPositionMs, mediaPlayer.getTime());
    return Math.max(0L, currentPositionMs);
  }

  @Override
  public long getBufferedPosition() {
    long duration = Math.max(durationMs, mediaPlayer.getLength());
    if (duration > 0 && lastBufferingPercent > 0f) {
      long estimated = Math.round(duration * Math.min(lastBufferingPercent, 100f) / 100f);
      return Math.max(getCurrentPosition(), estimated);
    }
    return getCurrentPosition();
  }

  @Override
  public void seekTo(long position) {
    mediaPlayer.setTime(position);
  }

  @Override
  public @NonNull NativeAudioTrackData getAudioTracks() {
    MediaPlayer.TrackDescription[] tracks = mediaPlayer.getAudioTracks();
    if (tracks == null || tracks.length == 0) {
      return new NativeAudioTrackData(new ArrayList<>());
    }

    int selectedTrack = mediaPlayer.getAudioTrack();
    List<ExoPlayerAudioTrackData> audioTracks = new ArrayList<>();
    long trackIndex = 0;
    for (MediaPlayer.TrackDescription track : tracks) {
      if (track == null || track.id == -1) {
        continue;
      }
      audioTracks.add(
          new ExoPlayerAudioTrackData(
              0L,
              trackIndex,
              track.name,
              null,
              track.id == selectedTrack,
              null,
              null,
              null,
              null));
      trackIndex++;
    }
    return new NativeAudioTrackData(audioTracks);
  }

  @Override
  public void selectAudioTrack(long groupIndex, long trackIndex) {
    MediaPlayer.TrackDescription[] tracks = mediaPlayer.getAudioTracks();
    if (tracks == null) {
      throw new IllegalStateException("No VLC audio tracks available for selection.");
    }

    int currentTrackIndex = 0;
    for (MediaPlayer.TrackDescription track : tracks) {
      if (track == null || track.id == -1) {
        continue;
      }
      if (currentTrackIndex == (int) trackIndex) {
        mediaPlayer.setAudioTrack(track.id);
        return;
      }
      currentTrackIndex++;
    }

    throw new IllegalArgumentException(
        "Cannot select VLC audio track: trackIndex " + trackIndex + " is out of bounds.");
  }

  @Override
  public void dispose() {
    if (disposeHandler != null) {
      disposeHandler.onDispose();
    }
    detachSurface();
    mediaPlayer.setEventListener(null);
    mediaPlayer.stop();
    mediaPlayer.release();
    libVlc.release();
    surfaceProducer.release();
  }

  @Override
  @Nullable
  public ExoPlayer getExoPlayer() {
    return null;
  }

  @Override
  public void onSurfaceAvailable() {
    attachSurface(/* forceNewSurface= */ false);
  }

  @Override
  public void onSurfaceCleanup() {
    detachSurface();
  }

  @Override
  public void onSurfacesCreated(IVLCVout vlcVout) {
    updateVideoMetrics();
    surfaceProducer.scheduleFrame();
    maybeSendInitialized(false);
  }

  @Override
  public void onSurfacesDestroyed(IVLCVout vlcVout) {
    attachedSurface = null;
  }

  @Override
  public void onNewVideoLayout(
      IVLCVout vlcVout,
      int width,
      int height,
      int visibleWidth,
      int visibleHeight,
      int sarNum,
      int sarDen) {
    applyVideoScaling();
    Log.i(
        TAG,
        "LibVLC requested video layout frame="
            + width
            + "x"
            + height
            + " visible="
            + visibleWidth
            + "x"
            + visibleHeight
            + " sar="
            + sarNum
            + ":"
            + sarDen
            + " outputWindow="
            + resolveTargetWidth()
            + "x"
            + resolveTargetHeight()
            + " for "
            + uri);
    updateSurfaceLayout();
    surfaceProducer.scheduleFrame();
    maybeSendInitialized(false);
  }
}
