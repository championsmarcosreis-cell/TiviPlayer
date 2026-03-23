import '../../domain/engine/player_engine_adapter.dart';
import '../../domain/entities/playback_manifest.dart';
import '../../domain/entities/resolved_playback.dart';

class VideoPlayerEngineAdapter implements PlayerEngineAdapter {
  const VideoPlayerEngineAdapter();

  @override
  bool get supportsAudioTrackSelection => false;

  @override
  bool get supportsSubtitleTrackSelection => false;

  @override
  bool get supportsQualitySelection => false;

  @override
  Future<PlayerSelectionApplyResult> selectAudioTrack({
    required ResolvedPlayback playback,
    required PlaybackTrack track,
  }) async {
    return PlayerSelectionApplyResult.notSupported;
  }

  @override
  Future<PlayerSelectionApplyResult> selectSubtitleTrack({
    required ResolvedPlayback playback,
    PlaybackTrack? track,
  }) async {
    return PlayerSelectionApplyResult.notSupported;
  }

  @override
  Future<PlayerSelectionApplyResult> selectQualityVariant({
    required ResolvedPlayback playback,
    required PlaybackVariant variant,
  }) async {
    return PlayerSelectionApplyResult.notSupported;
  }
}
