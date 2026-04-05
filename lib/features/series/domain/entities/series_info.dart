import 'series_episode.dart';

class SeriesInfo {
  const SeriesInfo({
    required this.id,
    required this.name,
    this.plot,
    this.genre,
    this.cast,
    this.coverUrl,
    this.backdropUrl,
    required this.seasonCount,
    required this.episodeCount,
    required this.episodes,
  });

  final String id;
  final String name;
  final String? plot;
  final String? genre;
  final String? cast;
  final String? coverUrl;
  final String? backdropUrl;
  final int seasonCount;
  final int episodeCount;
  final List<SeriesEpisode> episodes;
}
