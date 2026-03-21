abstract final class XtreamParsers {
  static Map<String, dynamic>? asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }

    return null;
  }

  static List<dynamic> asList(dynamic value) {
    if (value is List) {
      return value;
    }

    return const <dynamic>[];
  }

  static String? asString(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (value is num || value is bool) {
      return value.toString();
    }

    return null;
  }

  static int? asInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(asString(value) ?? '');
  }

  static bool asBool(dynamic value, {bool fallback = false}) {
    if (value == null) {
      return fallback;
    }

    if (value is bool) {
      return value;
    }

    final normalized = asString(value)?.toLowerCase();

    switch (normalized) {
      case '1':
      case 'true':
      case 'yes':
      case 'active':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'inactive':
        return false;
      default:
        return fallback;
    }
  }
}
