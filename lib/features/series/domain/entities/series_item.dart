class SeriesItem {
  const SeriesItem({
    required this.id,
    required this.name,
    this.categoryId,
    this.coverUrl,
    this.plot,
    this.libraryKind,
  });

  final String id;
  final String name;
  final String? categoryId;
  final String? coverUrl;
  final String? plot;
  final String? libraryKind;
}
