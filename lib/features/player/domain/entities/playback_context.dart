import 'playback_manifest.dart';

enum PlaybackContentType { live, vod, seriesEpisode }

class PlaybackLiveChannelItem {
  const PlaybackLiveChannelItem({
    required this.itemId,
    required this.title,
    this.containerExtension,
    this.artworkUrl,
  });

  final String itemId;
  final String title;
  final String? containerExtension;
  final String? artworkUrl;
}

class PlaybackContext {
  const PlaybackContext({
    required this.contentType,
    required this.itemId,
    required this.title,
    this.containerExtension,
    this.artworkUrl,
    this.resumePosition,
    this.notes,
    this.manifest = const PlaybackManifest(),
    this.liveChannels = const <PlaybackLiveChannelItem>[],
    this.liveChannelIndex,
  });

  final PlaybackContentType contentType;
  final String itemId;
  final String title;
  final String? containerExtension;
  final String? artworkUrl;
  final Duration? resumePosition;
  final String? notes;
  final PlaybackManifest manifest;
  final List<PlaybackLiveChannelItem> liveChannels;
  final int? liveChannelIndex;

  bool get isLive => contentType == PlaybackContentType.live;
  bool get isSeekable => !isLive;

  int? get resolvedLiveChannelIndex {
    if (!isLive || liveChannels.isEmpty) {
      return null;
    }
    final requestedIndex = liveChannelIndex;
    if (requestedIndex != null &&
        requestedIndex >= 0 &&
        requestedIndex < liveChannels.length &&
        liveChannels[requestedIndex].itemId == itemId) {
      return requestedIndex;
    }
    for (var index = 0; index < liveChannels.length; index++) {
      if (liveChannels[index].itemId == itemId) {
        return index;
      }
    }
    return null;
  }

  bool get hasLiveChannelNavigation =>
      isLive && resolvedLiveChannelIndex != null && liveChannels.length > 1;

  PlaybackLiveChannelItem? get previousLiveChannel {
    final currentIndex = resolvedLiveChannelIndex;
    if (currentIndex == null || currentIndex <= 0) {
      return null;
    }
    return liveChannels[currentIndex - 1];
  }

  PlaybackLiveChannelItem? get nextLiveChannel {
    final currentIndex = resolvedLiveChannelIndex;
    if (currentIndex == null || currentIndex >= liveChannels.length - 1) {
      return null;
    }
    return liveChannels[currentIndex + 1];
  }

  PlaybackContext forLiveChannelIndex(int index) {
    if (!isLive || index < 0 || index >= liveChannels.length) {
      return this;
    }
    final channel = liveChannels[index];
    return PlaybackContext(
      contentType: contentType,
      itemId: channel.itemId,
      title: channel.title,
      containerExtension: channel.containerExtension,
      artworkUrl: channel.artworkUrl,
      resumePosition: null,
      notes: notes,
      manifest: manifest,
      liveChannels: liveChannels,
      liveChannelIndex: index,
    );
  }
}
