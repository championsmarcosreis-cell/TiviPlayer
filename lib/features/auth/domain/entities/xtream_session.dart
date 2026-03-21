import 'xtream_credentials.dart';

class XtreamSession {
  const XtreamSession({
    required this.credentials,
    required this.accountStatus,
    this.serverUrl,
    this.serverTimezone,
    this.serverProtocol,
    this.message,
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
  final String? serverProtocol;
  final String? message;

  String get displayServer => serverUrl?.isNotEmpty == true
      ? serverUrl!
      : credentials.normalizedBaseUrl;
}
