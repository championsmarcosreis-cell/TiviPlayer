import '../entities/playback_manifest.dart';
import '../entities/resolved_playback.dart';
import 'package:video_player/video_player.dart';

enum PlayerSelectionApplyResult { applied, notSupported, failed }

abstract class PlayerEngineAdapter {
  bool get supportsAudioTrackSelection;
  bool get supportsSubtitleTrackSelection;
  bool get supportsManualQualitySelection;
  bool get supportsAutoQualitySelection;

  Future<bool> isAudioTrackSelectionAvailable({
    required ResolvedPlayback playback,
    VideoPlayerController? controller,
  });

  Future<List<PlaybackTrack>> getAudioTracks({
    required ResolvedPlayback playback,
    VideoPlayerController? controller,
  });

  Future<PlayerSelectionApplyResult> selectAudioTrack({
    required ResolvedPlayback playback,
    required PlaybackTrack track,
    VideoPlayerController? controller,
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
