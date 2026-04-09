import '../../domain/entities/playback_context.dart';

class PlayerOnDemandNavigationItem {
  const PlayerOnDemandNavigationItem({
    required this.contentType,
    required this.itemId,
    required this.title,
    this.containerExtension,
    this.artworkUrl,
    this.backdropUrl,
    this.seriesId,
    this.resumePosition,
  });

  final PlaybackContentType contentType;
  final String itemId;
  final String title;
  final String? containerExtension;
  final String? artworkUrl;
  final String? backdropUrl;
  final String? seriesId;
  final Duration? resumePosition;

  PlaybackContext get playbackContext => PlaybackContext(
    contentType: contentType,
    itemId: itemId,
    title: title,
    containerExtension: containerExtension,
    artworkUrl: artworkUrl,
    backdropUrl: backdropUrl,
    seriesId: seriesId,
    resumePosition: resumePosition,
    capabilities: const PlaybackSessionCapabilities.onDemand(),
  );
}

class PlayerOnDemandNavigation {
  const PlayerOnDemandNavigation({
    required this.items,
    required this.currentIndex,
  });

  final List<PlayerOnDemandNavigationItem> items;
  final int currentIndex;

  int get boundedCurrentIndex {
    if (items.isEmpty) {
      return 0;
    }
    return currentIndex.clamp(0, items.length - 1);
  }

  PlayerOnDemandNavigationItem? get currentItem {
    if (items.isEmpty) {
      return null;
    }
    return items[boundedCurrentIndex];
  }

  bool get hasAdjacentNavigation => items.length > 1;

  PlayerOnDemandNavigationItem? get previousItem {
    if (!hasAdjacentNavigation || boundedCurrentIndex <= 0) {
      return null;
    }
    return items[boundedCurrentIndex - 1];
  }

  PlayerOnDemandNavigationItem? get nextItem {
    if (!hasAdjacentNavigation || boundedCurrentIndex >= items.length - 1) {
      return null;
    }
    return items[boundedCurrentIndex + 1];
  }

  PlaybackContext get playbackContext {
    final item = currentItem;
    if (item == null) {
      return const PlaybackContext(
        contentType: PlaybackContentType.vod,
        itemId: '',
        title: 'Conteudo on demand',
        capabilities: PlaybackSessionCapabilities.onDemand(),
      );
    }

    return item.playbackContext;
  }

  PlayerOnDemandNavigation forItemIndex(int index) {
    if (items.isEmpty) {
      return this;
    }

    final boundedIndex = index.clamp(0, items.length - 1);
    return PlayerOnDemandNavigation(items: items, currentIndex: boundedIndex);
  }
}

class PlayerLiveNavigationItem {
  const PlayerLiveNavigationItem({
    required this.itemId,
    required this.title,
    this.containerExtension,
    this.artworkUrl,
    this.hasArchive = false,
  });

  final String itemId;
  final String title;
  final String? containerExtension;
  final String? artworkUrl;
  final bool hasArchive;
}

class PlayerLiveNavigation {
  const PlayerLiveNavigation({
    required this.channels,
    required this.currentIndex,
  });

  final List<PlayerLiveNavigationItem> channels;
  final int currentIndex;

  int get boundedCurrentIndex {
    if (channels.isEmpty) {
      return 0;
    }
    return currentIndex.clamp(0, channels.length - 1);
  }

  PlayerLiveNavigationItem? get currentChannel {
    if (channels.isEmpty) {
      return null;
    }
    return channels[boundedCurrentIndex];
  }

  bool get hasChannelNavigation => channels.length > 1;

  PlayerLiveNavigationItem? get previousChannel {
    if (!hasChannelNavigation || boundedCurrentIndex <= 0) {
      return null;
    }
    return channels[boundedCurrentIndex - 1];
  }

  PlayerLiveNavigationItem? get nextChannel {
    if (!hasChannelNavigation || boundedCurrentIndex >= channels.length - 1) {
      return null;
    }
    return channels[boundedCurrentIndex + 1];
  }

  PlaybackContext get playbackContext {
    final channel = currentChannel;
    if (channel == null) {
      return const PlaybackContext(
        contentType: PlaybackContentType.live,
        itemId: '',
        title: 'Canal ao vivo',
        capabilities: PlaybackSessionCapabilities.liveLinear(),
      );
    }

    return PlaybackContext(
      contentType: PlaybackContentType.live,
      itemId: channel.itemId,
      title: channel.title,
      containerExtension: channel.containerExtension,
      artworkUrl: channel.artworkUrl,
      capabilities: channel.hasArchive
          ? const PlaybackSessionCapabilities.liveReplayAvailable()
          : const PlaybackSessionCapabilities.liveLinear(),
    );
  }

  PlayerLiveNavigation forChannelIndex(int index) {
    if (channels.isEmpty) {
      return this;
    }

    final boundedIndex = index.clamp(0, channels.length - 1);
    return PlayerLiveNavigation(channels: channels, currentIndex: boundedIndex);
  }
}

class PlayerScreenArguments {
  const PlayerScreenArguments._({
    PlaybackContext? standalonePlaybackContext,
    this.liveNavigation,
    this.onDemandNavigation,
  }) : _standalonePlaybackContext = standalonePlaybackContext,
       assert(
         (standalonePlaybackContext != null ? 1 : 0) +
                 (liveNavigation != null ? 1 : 0) +
                 (onDemandNavigation != null ? 1 : 0) ==
             1,
         'PlayerScreenArguments requires either a standalone playback context '
         'or a navigation source.',
       );

  const PlayerScreenArguments.standalone(PlaybackContext playbackContext)
    : this._(standalonePlaybackContext: playbackContext);

  const PlayerScreenArguments.live(PlayerLiveNavigation liveNavigation)
    : this._(liveNavigation: liveNavigation);

  const PlayerScreenArguments.onDemand(
    PlayerOnDemandNavigation onDemandNavigation,
  ) : this._(onDemandNavigation: onDemandNavigation);

  final PlaybackContext? _standalonePlaybackContext;
  final PlayerLiveNavigation? liveNavigation;
  final PlayerOnDemandNavigation? onDemandNavigation;

  bool get isLiveNavigationSession => liveNavigation != null;
  bool get isOnDemandNavigationSession => onDemandNavigation != null;

  PlaybackContext get playbackContext =>
      liveNavigation?.playbackContext ??
      onDemandNavigation?.playbackContext ??
      _standalonePlaybackContext!;
}
