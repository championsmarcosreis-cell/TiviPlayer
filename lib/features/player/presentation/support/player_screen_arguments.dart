import '../../domain/entities/playback_context.dart';

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
  }) : _standalonePlaybackContext = standalonePlaybackContext,
       assert(
         (standalonePlaybackContext == null) != (liveNavigation == null),
         'PlayerScreenArguments requires either a standalone playback context '
         'or a live navigation source.',
       );

  const PlayerScreenArguments.standalone(PlaybackContext playbackContext)
    : this._(standalonePlaybackContext: playbackContext);

  const PlayerScreenArguments.live(PlayerLiveNavigation liveNavigation)
    : this._(liveNavigation: liveNavigation);

  final PlaybackContext? _standalonePlaybackContext;
  final PlayerLiveNavigation? liveNavigation;

  bool get isLiveNavigationSession => liveNavigation != null;

  PlaybackContext get playbackContext =>
      liveNavigation?.playbackContext ?? _standalonePlaybackContext!;
}
