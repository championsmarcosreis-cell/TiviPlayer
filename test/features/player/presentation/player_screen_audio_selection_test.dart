import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/player/domain/entities/playback_manifest.dart';
import 'package:tiviplayer/features/player/presentation/screens/player_screen.dart';

void main() {
  test('buildAudioSelectionOptions preserves duplicate labels by track id', () {
    const tracks = <PlaybackTrack>[
      PlaybackTrack(
        id: 'audio-pt-1',
        type: PlaybackTrackType.audio,
        label: 'PT-BR',
      ),
      PlaybackTrack(
        id: 'audio-pt-2',
        type: PlaybackTrackType.audio,
        label: 'PT-BR',
      ),
    ];

    final options = buildAudioSelectionOptions(tracks);

    expect(options, hasLength(2));
    expect(options.map((option) => option.id), <String>[
      'audio-pt-1',
      'audio-pt-2',
    ]);
    expect(options.map((option) => option.label), <String>[
      'PT-BR • audio-pt-1',
      'PT-BR • audio-pt-2',
    ]);
  });

  test('buildAudioSelectionOptions keeps unique labels unchanged', () {
    const tracks = <PlaybackTrack>[
      PlaybackTrack(
        id: 'audio-pt',
        type: PlaybackTrackType.audio,
        label: 'PT-BR',
      ),
      PlaybackTrack(id: 'audio-en', type: PlaybackTrackType.audio, label: 'EN'),
    ];

    final options = buildAudioSelectionOptions(tracks);

    expect(options.map((option) => option.label), <String>['PT-BR', 'EN']);
  });
}
