class VodInfo {
  const VodInfo({
    required this.id,
    required this.name,
    this.plot,
    this.genre,
    this.cast,
    this.director,
    this.duration,
    this.releaseDate,
    this.coverUrl,
    this.backdropUrl,
    this.rating,
    this.containerExtension,
  });

  final String id;
  final String name;
  final String? plot;
  final String? genre;
  final String? cast;
  final String? director;
  final String? duration;
  final String? releaseDate;
  final String? coverUrl;
  final String? backdropUrl;
  final String? rating;
  final String? containerExtension;
}
