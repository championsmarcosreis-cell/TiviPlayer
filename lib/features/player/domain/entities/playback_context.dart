import 'playback_manifest.dart';

enum PlaybackContentType { live, vod, seriesEpisode }

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
  });

  final PlaybackContentType contentType;
  final String itemId;
  final String title;
  final String? containerExtension;
  final String? artworkUrl;
  final Duration? resumePosition;
  final String? notes;
  final PlaybackManifest manifest;

  bool get isLive => contentType == PlaybackContentType.live;
  bool get isSeekable => !isLive;
}
