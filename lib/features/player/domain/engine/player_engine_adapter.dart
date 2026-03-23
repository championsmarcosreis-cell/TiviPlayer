import '../entities/playback_manifest.dart';
import '../entities/resolved_playback.dart';

enum PlayerSelectionApplyResult { applied, notSupported, failed }

abstract class PlayerEngineAdapter {
  bool get supportsAudioTrackSelection;
  bool get supportsSubtitleTrackSelection;
  bool get supportsManualQualitySelection;
  bool get supportsAutoQualitySelection;

  Future<PlayerSelectionApplyResult> selectAudioTrack({
    required ResolvedPlayback playback,
    required PlaybackTrack track,
  });

  Future<PlayerSelectionApplyResult> selectSubtitleTrack({
    required ResolvedPlayback playback,
    PlaybackTrack? track,
  });

  Future<PlayerSelectionApplyResult> selectQualityVariant({
    required ResolvedPlayback playback,
    required PlaybackVariant variant,
  });

  Future<PlayerSelectionApplyResult> selectAutoQuality({
    required ResolvedPlayback playback,
  });
}
