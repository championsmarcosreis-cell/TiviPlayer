class SeriesEpisode {
  const SeriesEpisode({
    required this.id,
    required this.title,
    required this.seasonNumber,
    this.episodeNumber,
    this.plot,
    this.duration,
    this.containerExtension,
  });

  final String id;
  final String title;
  final int seasonNumber;
  final int? episodeNumber;
  final String? plot;
  final String? duration;
  final String? containerExtension;
}
