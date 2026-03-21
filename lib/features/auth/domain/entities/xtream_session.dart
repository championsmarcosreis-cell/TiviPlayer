import 'xtream_credentials.dart';

class XtreamSession {
  const XtreamSession({
    required this.credentials,
    required this.accountStatus,
    this.serverUrl,
    this.serverTimezone,
    this.serverTimeNow,
    this.serverProtocol,
    this.message,
    this.expirationDate,
    this.isTrial,
    this.activeConnections,
    this.maxConnections,
  });

  factory XtreamSession.cached(XtreamCredentials credentials) {
    return XtreamSession(
      credentials: credentials,
      accountStatus: 'cached',
      serverUrl: credentials.normalizedBaseUrl,
    );
  }

  final XtreamCredentials credentials;
  final String accountStatus;
  final String? serverUrl;
  final String? serverTimezone;
  final String? serverTimeNow;
  final String? serverProtocol;
  final String? message;
  final String? expirationDate;
  final bool? isTrial;
  final int? activeConnections;
  final int? maxConnections;

  String get displayServer => serverUrl?.isNotEmpty == true
      ? serverUrl!
      : credentials.normalizedBaseUrl;
}
