import 'dart:convert';

class FavoriteItem {
  const FavoriteItem({
    required this.contentType,
    required this.contentId,
    required this.title,
  });

  final String contentType;
  final String contentId;
  final String title;

  String get key => '$contentType:$contentId';

  Map<String, dynamic> toJson() {
    return {'contentType': contentType, 'contentId': contentId, 'title': title};
  }

  String encode() => jsonEncode(toJson());

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      contentType: json['contentType'] as String? ?? '',
      contentId: json['contentId'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }

  factory FavoriteItem.decode(String value) {
    return FavoriteItem.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }
}
