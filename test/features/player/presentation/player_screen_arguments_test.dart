import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/player/domain/entities/playback_context.dart';
import 'package:tiviplayer/features/player/presentation/support/player_screen_arguments.dart';

void main() {
  test('on-demand navigation exposes adjacent items and playback context', () {
    const navigation = PlayerOnDemandNavigation(
      items: [
        PlayerOnDemandNavigationItem(
          contentType: PlaybackContentType.seriesEpisode,
          itemId: 'ep-1',
          title: 'Serie • Episodio 1',
          seriesId: 'series-1',
        ),
        PlayerOnDemandNavigationItem(
          contentType: PlaybackContentType.seriesEpisode,
          itemId: 'ep-2',
          title: 'Serie • Episodio 2',
          seriesId: 'series-1',
        ),
        PlayerOnDemandNavigationItem(
          contentType: PlaybackContentType.seriesEpisode,
          itemId: 'ep-3',
          title: 'Serie • Episodio 3',
          seriesId: 'series-1',
        ),
      ],
      currentIndex: 1,
    );

    expect(navigation.currentItem?.itemId, 'ep-2');
    expect(navigation.previousItem?.itemId, 'ep-1');
    expect(navigation.nextItem?.itemId, 'ep-3');
    expect(navigation.playbackContext.itemId, 'ep-2');
    expect(
      navigation.playbackContext.contentType,
      PlaybackContentType.seriesEpisode,
    );
    expect(navigation.playbackContext.canSeek, isTrue);
  });

  test(
    'player arguments resolve playback context from on-demand navigation',
    () {
      const arguments = PlayerScreenArguments.onDemand(
        PlayerOnDemandNavigation(
          items: [
            PlayerOnDemandNavigationItem(
              contentType: PlaybackContentType.seriesEpisode,
              itemId: 'ep-9',
              title: 'Serie • Episodio 9',
              seriesId: 'series-9',
            ),
          ],
          currentIndex: 0,
        ),
      );

      expect(arguments.isOnDemandNavigationSession, isTrue);
      expect(arguments.playbackContext.itemId, 'ep-9');
      expect(arguments.playbackContext.seriesId, 'series-9');
    },
  );
}
