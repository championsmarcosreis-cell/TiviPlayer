import 'dart:convert';
import 'dart:developer' as developer;

import '../../domain/observability/player_telemetry.dart';

class DebugPlayerTelemetrySink implements PlayerTelemetrySink {
  const DebugPlayerTelemetrySink();

  @override
  void record(PlayerTelemetryEvent event) {
    developer.log(
      event.message,
      name: 'tiviplayer.player',
      error: jsonEncode(<String, Object?>{
        'type': event.type.name,
        ..._sanitizeAttributes(event.attributes),
      }),
    );
  }

  Map<String, Object?> _sanitizeAttributes(Map<String, Object?> attributes) {
    if (attributes.isEmpty) {
      return const <String, Object?>{};
    }

    final sanitized = <String, Object?>{};
    for (final entry in attributes.entries) {
      sanitized[entry.key] = _sanitizeValue(entry.key, entry.value);
    }
    return sanitized;
  }

  Object? _sanitizeValue(String key, Object? value) {
    if (value is Map<String, Object?>) {
      return _sanitizeAttributes(value);
    }
    if (value is Iterable<Object?>) {
      return value
          .map((item) => _sanitizeValue(key, item))
          .toList(growable: false);
    }
    if (value is String && _shouldSanitizeKey(key)) {
      return _sanitizeUriString(value);
    }
    return value;
  }

  bool _shouldSanitizeKey(String key) {
    final normalized = key.trim().toLowerCase();
    return normalized == 'uri' || normalized == 'url';
  }

  String _sanitizeUriString(String value) {
    final parsed = Uri.tryParse(value);
    if (parsed == null || (!parsed.hasScheme && parsed.host.isEmpty)) {
      return value;
    }

    final host = parsed.host.trim().isEmpty ? 'unknown-host' : parsed.host;
    final pathSegments = parsed.pathSegments.where(
      (segment) => segment.isNotEmpty,
    );
    final lastSegment = pathSegments.isEmpty ? 'unknown' : pathSegments.last;
    final scheme = parsed.scheme.trim().isEmpty ? 'unknown' : parsed.scheme;
    return '$scheme://$host/.../$lastSegment';
  }
}
