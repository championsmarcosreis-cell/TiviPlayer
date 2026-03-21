abstract final class DisplayFormatters {
  static String? humanizeDate(String? rawValue) {
    final parsed = parseFlexibleDate(rawValue);
    if (parsed == null) {
      final cleaned = _clean(rawValue);
      return cleaned;
    }

    final twoDigitsDay = parsed.day.toString().padLeft(2, '0');
    final twoDigitsMonth = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hasExplicitTime =
        parsed.hour != 0 || parsed.minute != 0 || parsed.second != 0;

    if (!hasExplicitTime) {
      return '$twoDigitsDay/$twoDigitsMonth/$year';
    }

    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$twoDigitsDay/$twoDigitsMonth/$year às $hour:$minute';
  }

  static DateTime? parseFlexibleDate(String? rawValue) {
    final cleaned = _clean(rawValue);
    if (cleaned == null) {
      return null;
    }

    if (RegExp(r'^\d+$').hasMatch(cleaned)) {
      final numeric = int.tryParse(cleaned);
      if (numeric == null || numeric <= 0) {
        return null;
      }

      final milliseconds = cleaned.length >= 13 ? numeric : numeric * 1000;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }

    return DateTime.tryParse(cleaned);
  }

  static String humanizeAccountStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return switch (normalized) {
      'active' || 'enabled' => 'Ativa',
      'disabled' || 'inactive' => 'Inativa',
      'expired' => 'Expirada',
      'banned' => 'Bloqueada',
      'trial' => 'Trial',
      'cached' => 'Sessão salva',
      _ => _sentenceCase(status),
    };
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null ||
        trimmed.isEmpty ||
        trimmed == '0' ||
        trimmed.toLowerCase() == 'null') {
      return null;
    }

    return trimmed;
  }

  static String _sentenceCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return value;
    }

    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }
}
