import '../../domain/entities/live_stream.dart';
import '../../../player/domain/entities/playback_context.dart';

PlaybackContext buildLivePlaybackContext(
  List<LiveStream> streams,
  int currentIndex,
) {
  final boundedIndex = currentIndex.clamp(0, streams.length - 1);
  final current = streams[boundedIndex];
  final liveChannels = streams
      .map(
        (item) => PlaybackLiveChannelItem(
          itemId: item.id,
          title: item.name,
          containerExtension: item.containerExtension,
          artworkUrl: item.iconUrl,
        ),
      )
      .toList(growable: false);

  return PlaybackContext(
    contentType: PlaybackContentType.live,
    itemId: current.id,
    title: current.name,
    containerExtension: current.containerExtension,
    artworkUrl: current.iconUrl,
    liveChannels: liveChannels,
    liveChannelIndex: boundedIndex,
  );
}
