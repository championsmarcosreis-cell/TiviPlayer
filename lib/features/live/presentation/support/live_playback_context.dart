import '../../domain/entities/live_stream.dart';
import '../../../player/presentation/support/player_screen_arguments.dart';

PlayerScreenArguments buildLivePlaybackContext(
  List<LiveStream> streams,
  int currentIndex,
) {
  final boundedIndex = currentIndex.clamp(0, streams.length - 1);
  final liveNavigation = PlayerLiveNavigation(
    channels: streams
        .map(
          (item) => PlayerLiveNavigationItem(
            itemId: item.id,
            title: item.name,
            containerExtension: item.containerExtension,
            artworkUrl: item.iconUrl,
            hasArchive: item.hasArchive,
          ),
        )
        .toList(growable: false),
    currentIndex: boundedIndex,
  );

  return PlayerScreenArguments.live(liveNavigation);
}
