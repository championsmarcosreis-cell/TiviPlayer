import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/player/domain/entities/playback_context.dart';
import 'package:tiviplayer/features/player/presentation/screens/player_screen.dart';
import 'package:video_player/video_player.dart';

void main() {
  const liveContext = PlaybackContext(
    contentType: PlaybackContentType.live,
    itemId: '11',
    title: 'Canal ao vivo',
  );
  const vodContext = PlaybackContext(
    contentType: PlaybackContentType.vod,
    itemId: '44',
    title: 'Filme',
  );

  test('mantém a tela acordada só para live ativo no mobile', () {
    expect(
      shouldKeepMobileLiveScreenAwake(
        isTv: false,
        playbackContext: liveContext,
        playerValue: const VideoPlayerValue(
          isInitialized: true,
          isPlaying: true,
          duration: Duration(minutes: 1),
        ),
      ),
      isTrue,
    );
  });

  test('não mantém a tela acordada para VOD, TV ou player parado', () {
    expect(
      shouldKeepMobileLiveScreenAwake(
        isTv: false,
        playbackContext: vodContext,
        playerValue: const VideoPlayerValue(
          isInitialized: true,
          isPlaying: true,
          duration: Duration(minutes: 1),
        ),
      ),
      isFalse,
    );

    expect(
      shouldKeepMobileLiveScreenAwake(
        isTv: true,
        playbackContext: liveContext,
        playerValue: const VideoPlayerValue(
          isInitialized: true,
          isPlaying: true,
          duration: Duration(minutes: 1),
        ),
      ),
      isFalse,
    );

    expect(
      shouldKeepMobileLiveScreenAwake(
        isTv: false,
        playbackContext: liveContext,
        playerValue: const VideoPlayerValue(
          isInitialized: true,
          isPlaying: false,
          isBuffering: false,
          duration: Duration(minutes: 1),
        ),
      ),
      isFalse,
    );
  });
}
