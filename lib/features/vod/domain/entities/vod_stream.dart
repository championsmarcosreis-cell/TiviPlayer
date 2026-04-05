class VodStream {
  const VodStream({
    required this.id,
    required this.name,
    this.categoryId,
    this.coverUrl,
    this.containerExtension,
    this.rating,
    this.libraryKind,
  });

  final String id;
  final String name;
  final String? categoryId;
  final String? coverUrl;
  final String? containerExtension;
  final String? rating;
  final String? libraryKind;
}
