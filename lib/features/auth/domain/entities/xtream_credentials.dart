import '../../../../core/network/xtream_client.dart';

class XtreamCredentials {
  const XtreamCredentials({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  final String baseUrl;
  final String username;
  final String password;

  String get normalizedBaseUrl => XtreamClient.normalizeBaseUrl(baseUrl);
}
