class VodCategory {
  const VodCategory({
    required this.id,
    required this.name,
    this.parentId,
    this.libraryKind,
  });

  final String id;
  final String name;
  final String? parentId;
  final String? libraryKind;
}
