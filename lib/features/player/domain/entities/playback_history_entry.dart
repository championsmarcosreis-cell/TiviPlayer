import 'dart:convert';

import 'playback_context.dart';

class PlaybackHistoryEntry {
  const PlaybackHistoryEntry({
    required this.contentType,
    required this.itemId,
    required this.title,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAtEpochMs,
    this.containerExtension,
    this.artworkUrl,
    this.seriesId,
  });

  final PlaybackContentType contentType;
  final String itemId;
  final String title;
  final int positionMs;
  final int durationMs;
  final int updatedAtEpochMs;
  final String? containerExtension;
  final String? artworkUrl;
  final String? seriesId;

  String get key => '${contentType.name}:$itemId';

  Map<String, dynamic> toJson() {
    return {
      'contentType': contentType.name,
      'itemId': itemId,
      'title': title,
      'positionMs': positionMs,
      'durationMs': durationMs,
      'updatedAtEpochMs': updatedAtEpochMs,
      'containerExtension': containerExtension,
      'artworkUrl': artworkUrl,
      'seriesId': seriesId,
    };
  }

  String encode() => jsonEncode(toJson());

  factory PlaybackHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PlaybackHistoryEntry(
      contentType: _decodeContentType(json['contentType'] as String?),
      itemId: json['itemId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      positionMs: json['positionMs'] as int? ?? 0,
      durationMs: json['durationMs'] as int? ?? 0,
      updatedAtEpochMs: json['updatedAtEpochMs'] as int? ?? 0,
      containerExtension: json['containerExtension'] as String?,
      artworkUrl: json['artworkUrl'] as String?,
      seriesId: json['seriesId'] as String?,
    );
  }

  factory PlaybackHistoryEntry.decode(String value) {
    return PlaybackHistoryEntry.fromJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
  }

  static PlaybackContentType _decodeContentType(String? value) {
    return PlaybackContentType.values.firstWhere(
      (entry) => entry.name == value,
      orElse: () => PlaybackContentType.vod,
    );
  }
}
