import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/player/data/engine/android_channel_player_engine_adapter.dart';
import 'package:tiviplayer/features/player/domain/engine/player_engine_adapter.dart';
import 'package:tiviplayer/features/player/domain/entities/playback_context.dart';
import 'package:tiviplayer/features/player/domain/entities/playback_manifest.dart';
import 'package:tiviplayer/features/player/domain/entities/resolved_playback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = 'tiviplayer/player_engine_android.test';
  const methodChannel = MethodChannel(channelName);

  final playback = ResolvedPlayback(
    uri: Uri.parse('https://example.test/stream.m3u8'),
    context: const PlaybackContext(
      contentType: PlaybackContentType.live,
      itemId: '1001',
      title: 'Canal teste',
      containerExtension: 'm3u8',
    ),
  );

  const track = PlaybackTrack(
    id: 'audio-pt',
    type: PlaybackTrackType.audio,
    label: 'PT-BR',
    languageCode: 'pt',
  );
  const variant = PlaybackVariant(
    id: 'v1080',
    label: '1080p',
    bitrateKbps: 5500,
  );

  final invocations = <MethodCall>[];

  setUp(() {
    invocations.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
          invocations.add(call);
          switch (call.method) {
            case 'getCapabilities':
              return <String, Object?>{
                'audioTrackSelection': true,
                'subtitleTrackSelection': true,
                'manualQualitySelection': true,
                'autoQualitySelection': true,
              };
            case 'selectAudioTrack':
            case 'selectSubtitleTrack':
            case 'selectQualityVariant':
            case 'setAutoQuality':
              return <String, Object?>{'status': 'applied'};
            default:
              return <String, Object?>{'status': 'failed'};
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  test('maps track and quality selection payload to channel', () async {
    final adapter = AndroidChannelPlayerEngineAdapter(channel: methodChannel);

    final audioResult = await adapter.selectAudioTrack(
      playback: playback,
      track: track,
    );
    final qualityResult = await adapter.selectQualityVariant(
      playback: playback,
      variant: variant,
    );
    final autoResult = await adapter.selectAutoQuality(playback: playback);

    expect(audioResult, PlayerSelectionApplyResult.applied);
    expect(qualityResult, PlayerSelectionApplyResult.applied);
    expect(autoResult, PlayerSelectionApplyResult.applied);
    expect(
      invocations.map((entry) => entry.method),
      containsAll(<String>[
        'getCapabilities',
        'selectAudioTrack',
        'selectQualityVariant',
        'setAutoQuality',
      ]),
    );

    final selectAudioCall = invocations.firstWhere(
      (entry) => entry.method == 'selectAudioTrack',
    );
    final selectAudioArgs = selectAudioCall.arguments as Map<Object?, Object?>;
    expect(selectAudioArgs['uri'], playback.uri.toString());
    expect(selectAudioArgs['isLive'], isTrue);

    final trackMap = selectAudioArgs['track'] as Map<Object?, Object?>;
    expect(trackMap['id'], 'audio-pt');
    expect(trackMap['label'], 'PT-BR');
    expect(trackMap['languageCode'], 'pt');
  });
}
