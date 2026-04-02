// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import android.media.AudioDeviceInfo;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.common.AudioAttributes;
import androidx.media3.common.AuxEffectInfo;
import androidx.media3.common.Format;
import androidx.media3.common.PlaybackParameters;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.analytics.PlayerId;
import androidx.media3.exoplayer.audio.AudioOffloadSupport;
import androidx.media3.exoplayer.audio.AudioOutputProvider;
import androidx.media3.exoplayer.audio.AudioSink;
import java.nio.ByteBuffer;

/**
 * Wraps Media3's AudioSink and drops Xiaomi-specific spurious timestamp discontinuity callbacks.
 */
@UnstableApi
final class XiaomiQuirkAudioSink implements AudioSink {
  @NonNull private final AudioSink delegate;
  @Nullable private Listener externalListener;

  XiaomiQuirkAudioSink(@NonNull AudioSink delegate) {
    this.delegate = delegate;
  }

  @Override
  public void setListener(@NonNull Listener listener) {
    externalListener = listener;
    delegate.setListener(
        new Listener() {
          @Override
          public void onPositionDiscontinuity() {
            listener.onPositionDiscontinuity();
          }

          @Override
          public void onPositionAdvancing(long playoutStartSystemTimeMs) {
            listener.onPositionAdvancing(playoutStartSystemTimeMs);
          }

          @Override
          public void onUnderrun(
              int bufferSize, long bufferSizeMs, long elapsedSinceLastFeedMs) {
            listener.onUnderrun(bufferSize, bufferSizeMs, elapsedSinceLastFeedMs);
          }

          @Override
          public void onSkipSilenceEnabledChanged(boolean skipSilenceEnabled) {
            listener.onSkipSilenceEnabledChanged(skipSilenceEnabled);
          }

          @Override
          public void onOffloadBufferEmptying() {
            listener.onOffloadBufferEmptying();
          }

          @Override
          public void onOffloadBufferFull() {
            listener.onOffloadBufferFull();
          }

          @Override
          public void onAudioSinkError(@NonNull Exception audioSinkError) {
            if (audioSinkError instanceof AudioSink.UnexpectedDiscontinuityException) {
              return;
            }
            listener.onAudioSinkError(audioSinkError);
          }

          @Override
          public void onAudioCapabilitiesChanged() {
            listener.onAudioCapabilitiesChanged();
          }

          @Override
          public void onAudioTrackInitialized(@NonNull AudioTrackConfig audioTrackConfig) {
            listener.onAudioTrackInitialized(audioTrackConfig);
          }

          @Override
          public void onAudioTrackReleased(@NonNull AudioTrackConfig audioTrackConfig) {
            listener.onAudioTrackReleased(audioTrackConfig);
          }

          @Override
          public void onSilenceSkipped() {
            listener.onSilenceSkipped();
          }

          @Override
          public void onAudioSessionIdChanged(int audioSessionId) {
            listener.onAudioSessionIdChanged(audioSessionId);
          }
        });
  }

  @Override
  public void setPlayerId(@NonNull PlayerId playerId) {
    delegate.setPlayerId(playerId);
  }

  @Override
  public void setClock(@NonNull androidx.media3.common.util.Clock clock) {
    delegate.setClock(clock);
  }

  @Override
  public boolean supportsFormat(@NonNull Format format) {
    return delegate.supportsFormat(format);
  }

  @Override
  public int getFormatSupport(@NonNull Format format) {
    return delegate.getFormatSupport(format);
  }

  @Override
  public AudioOffloadSupport getFormatOffloadSupport(@NonNull Format format) {
    return delegate.getFormatOffloadSupport(format);
  }

  @Override
  public long getCurrentPositionUs(boolean sourceEnded) {
    return delegate.getCurrentPositionUs(sourceEnded);
  }

  @Override
  public void configure(@NonNull Format inputFormat, int specifiedBufferSize, @Nullable int[] outputChannels)
      throws ConfigurationException {
    delegate.configure(inputFormat, specifiedBufferSize, outputChannels);
  }

  @Override
  public void play() {
    delegate.play();
  }

  @Override
  public void handleDiscontinuity() {
    delegate.handleDiscontinuity();
  }

  @Override
  public boolean handleBuffer(@NonNull ByteBuffer buffer, long presentationTimeUs, int encodedAccessUnitCount)
      throws InitializationException, WriteException {
    return delegate.handleBuffer(buffer, presentationTimeUs, encodedAccessUnitCount);
  }

  @Override
  public void playToEndOfStream() throws WriteException {
    delegate.playToEndOfStream();
  }

  @Override
  public boolean isEnded() {
    return delegate.isEnded();
  }

  @Override
  public boolean hasPendingData() {
    return delegate.hasPendingData();
  }

  @Override
  public void setPlaybackParameters(@NonNull PlaybackParameters playbackParameters) {
    delegate.setPlaybackParameters(playbackParameters);
  }

  @Override
  public PlaybackParameters getPlaybackParameters() {
    return delegate.getPlaybackParameters();
  }

  @Override
  public void setSkipSilenceEnabled(boolean skipSilenceEnabled) {
    delegate.setSkipSilenceEnabled(skipSilenceEnabled);
  }

  @Override
  public boolean getSkipSilenceEnabled() {
    return delegate.getSkipSilenceEnabled();
  }

  @Override
  public void setAudioAttributes(@NonNull AudioAttributes audioAttributes) {
    delegate.setAudioAttributes(audioAttributes);
  }

  @Override
  public AudioAttributes getAudioAttributes() {
    return delegate.getAudioAttributes();
  }

  @Override
  public void setAudioSessionId(int audioSessionId) {
    delegate.setAudioSessionId(audioSessionId);
  }

  @Override
  public void setAuxEffectInfo(@NonNull AuxEffectInfo auxEffectInfo) {
    delegate.setAuxEffectInfo(auxEffectInfo);
  }

  @Override
  public void setPreferredDevice(@Nullable AudioDeviceInfo preferredDevice) {
    delegate.setPreferredDevice(preferredDevice);
  }

  @Override
  public void setVirtualDeviceId(int virtualDeviceId) {
    delegate.setVirtualDeviceId(virtualDeviceId);
  }

  @Override
  public long getAudioTrackBufferSizeUs() {
    return delegate.getAudioTrackBufferSizeUs();
  }

  @Override
  public void enableTunnelingV21() {
    delegate.enableTunnelingV21();
  }

  @Override
  public void disableTunneling() {
    delegate.disableTunneling();
  }

  @Override
  public void setOffloadMode(int offloadMode) {
    delegate.setOffloadMode(offloadMode);
  }

  @Override
  public void setOffloadDelayPadding(int delayInFrames, int paddingInFrames) {
    delegate.setOffloadDelayPadding(delayInFrames, paddingInFrames);
  }

  @Override
  public void setAudioOutputProvider(@NonNull AudioOutputProvider audioOutputProvider) {
    delegate.setAudioOutputProvider(audioOutputProvider);
  }

  @Override
  public void setVolume(float volume) {
    delegate.setVolume(volume);
  }

  @Override
  public void pause() {
    delegate.pause();
  }

  @Override
  public void flush() {
    delegate.flush();
  }

  @Override
  public void reset() {
    delegate.reset();
  }

  @Override
  public void release() {
    externalListener = null;
    delegate.release();
  }
}
