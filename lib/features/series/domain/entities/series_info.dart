class SeriesInfo {
  const SeriesInfo({
    required this.id,
    required this.name,
    this.plot,
    this.genre,
    this.cast,
    this.coverUrl,
    required this.seasonCount,
    required this.episodeCount,
  });

  final String id;
  final String name;
  final String? plot;
  final String? genre;
  final String? cast;
  final String? coverUrl;
  final int seasonCount;
  final int episodeCount;
}
