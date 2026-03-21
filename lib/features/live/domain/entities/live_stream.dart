class LiveStream {
  const LiveStream({
    required this.id,
    required this.name,
    this.categoryId,
    this.iconUrl,
    this.epgChannelId,
    required this.hasArchive,
    required this.isAdult,
  });

  final String id;
  final String name;
  final String? categoryId;
  final String? iconUrl;
  final String? epgChannelId;
  final bool hasArchive;
  final bool isAdult;
}
