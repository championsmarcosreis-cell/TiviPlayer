import 'dart:convert';

import '../../../../core/network/xtream_parsers.dart';

class LiveEpgDto {
  const LiveEpgDto({
    required this.title,
    required this.startAt,
    required this.endAt,
    this.description,
  });

  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String? description;

  static List<LiveEpgDto> fromApi(dynamic payload) {
    final root = XtreamParsers.asMap(payload);
    final listings = XtreamParsers.asList(root?['epg_listings']);

    final items = <LiveEpgDto>[];
    for (final raw in listings) {
      final item = XtreamParsers.asMap(raw);
      if (item == null) {
        continue;
      }
      final parsed = _fromApiItem(item);
      if (parsed != null) {
        items.add(parsed);
      }
    }

    items.sort((a, b) => a.startAt.compareTo(b.startAt));
    return items;
  }

  static LiveEpgDto? _fromApiItem(Map<String, dynamic> item) {
    final startAt =
        _parseEpoch(item['start_timestamp']) ??
        _parseDate(item['start']) ??
        _parseDate(item['start_datetime']);
    final endAt =
        _parseEpoch(item['stop_timestamp']) ??
        _parseDate(item['stop']) ??
        _parseDate(item['end']) ??
        _parseDate(item['end_datetime']);

    if (startAt == null || endAt == null || !endAt.isAfter(startAt)) {
      return null;
    }

    final title = _decodeMaybeBase64(item['title']) ?? 'Programacao ao vivo';
    final description = _decodeMaybeBase64(item['description']);

    return LiveEpgDto(
      title: title,
      startAt: startAt,
      endAt: endAt,
      description: description,
    );
  }

  static DateTime? _parseEpoch(dynamic value) {
    final seconds = XtreamParsers.asInt(value);
    if (seconds == null || seconds <= 0) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  static DateTime? _parseDate(dynamic value) {
    final raw = XtreamParsers.asString(value);
    if (raw == null) {
      return null;
    }

    final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  static String? _decodeMaybeBase64(dynamic value) {
    final raw = XtreamParsers.asString(value);
    if (raw == null) {
      return null;
    }

    try {
      final normalized = base64.normalize(raw);
      final decodedBytes = base64Decode(normalized);
      final decoded = utf8.decode(decodedBytes).trim();
      if (decoded.isNotEmpty) {
        return decoded;
      }
    } catch (_) {
      // Keep the original value when the provider sends plain text.
    }

    return raw;
  }
}
