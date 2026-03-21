class PlaybackContext {
  const PlaybackContext({
    required this.contentType,
    required this.itemId,
    required this.title,
    this.notes,
  });

  final String contentType;
  final String itemId;
  final String title;
  final String? notes;
}
