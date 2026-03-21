enum PlaybackContentType { live, vod, seriesEpisode }

class PlaybackContext {
  const PlaybackContext({
    required this.contentType,
    required this.itemId,
    required this.title,
    this.containerExtension,
    this.notes,
  });

  final PlaybackContentType contentType;
  final String itemId;
  final String title;
  final String? containerExtension;
  final String? notes;

  bool get isLive => contentType == PlaybackContentType.live;
  bool get isSeekable => !isLive;
}
