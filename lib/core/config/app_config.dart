class AppConfig {
  const AppConfig({
    required this.defaultBaseUrl,
    required this.defaultUsername,
    required this.defaultPassword,
    required this.allowAdvancedServer,
  });

  final String defaultBaseUrl;
  final String defaultUsername;
  final String defaultPassword;
  final bool allowAdvancedServer;

  bool get hasDefaultBaseUrl => defaultBaseUrl.trim().isNotEmpty;

  static const _xtreamBaseUrl = String.fromEnvironment('XTREAM_BASE_URL');
  static const _legacyBaseUrl = String.fromEnvironment('TIVIPLAYER_BASE_URL');
  static const _embeddedBaseUrlFallback =
      'https://api-tiviplayer.vorbio.me:443';
  static const _defaultUsername = String.fromEnvironment(
    'XTREAM_DEFAULT_USERNAME',
  );
  static const _defaultPassword = String.fromEnvironment(
    'XTREAM_DEFAULT_PASSWORD',
  );
  static const _allowAdvancedServer = bool.fromEnvironment(
    'XTREAM_ALLOW_ADVANCED_SERVER',
    defaultValue: true,
  );

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      defaultBaseUrl: _firstNonEmpty(
        _xtreamBaseUrl,
        _legacyBaseUrl,
        _embeddedBaseUrlFallback,
      ),
      defaultUsername: _defaultUsername.trim(),
      defaultPassword: _defaultPassword.trim(),
      allowAdvancedServer: _allowAdvancedServer,
    );
  }

  static String _firstNonEmpty(
    String primary,
    String fallback,
    String fallbackDefault,
  ) {
    final normalizedPrimary = primary.trim();
    if (normalizedPrimary.isNotEmpty) {
      return normalizedPrimary;
    }

    final normalizedFallback = fallback.trim();
    if (normalizedFallback.isNotEmpty) {
      return normalizedFallback;
    }

    return fallbackDefault.trim();
  }
}
