import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/player/data/engine/video_player_engine_adapter.dart';
import 'package:tiviplayer/features/player/domain/engine/player_engine_adapter.dart';
import 'package:tiviplayer/features/player/domain/entities/playback_context.dart';
import 'package:tiviplayer/features/player/domain/entities/playback_manifest.dart';
import 'package:tiviplayer/features/player/domain/entities/resolved_playback.dart';

void main() {
  const adapter = VideoPlayerEngineAdapter();

  final playback = ResolvedPlayback(
    uri: Uri.parse('http://provider.example/live/user/pass/1001.ts'),
    context: const PlaybackContext(
      contentType: PlaybackContentType.live,
      itemId: '1001',
      title: 'Canal teste',
      containerExtension: 'ts',
    ),
  );

  const audioTrack = PlaybackTrack(
    id: 'a-1',
    type: PlaybackTrackType.audio,
    label: 'PT-BR',
  );

  const subtitleTrack = PlaybackTrack(
    id: 's-1',
    type: PlaybackTrackType.subtitle,
    label: 'PT-BR',
  );

  const variant = PlaybackVariant(id: 'v-1', label: '1080p');

  test('exposes no runtime selection capabilities on video_player adapter', () {
    expect(adapter.supportsAudioTrackSelection, isFalse);
    expect(adapter.supportsSubtitleTrackSelection, isFalse);
    expect(adapter.supportsQualitySelection, isFalse);
  });

  test('returns notSupported for runtime selection requests', () async {
    final audioResult = await adapter.selectAudioTrack(
      playback: playback,
      track: audioTrack,
    );
    final subtitleResult = await adapter.selectSubtitleTrack(
      playback: playback,
      track: subtitleTrack,
    );
    final qualityResult = await adapter.selectQualityVariant(
      playback: playback,
      variant: variant,
    );

    expect(audioResult, PlayerSelectionApplyResult.notSupported);
    expect(subtitleResult, PlayerSelectionApplyResult.notSupported);
    expect(qualityResult, PlayerSelectionApplyResult.notSupported);
  });
}
