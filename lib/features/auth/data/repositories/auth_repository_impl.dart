import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/session_storage.dart';
import '../../domain/entities/xtream_credentials.dart';
import '../../domain/entities/xtream_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_response_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource, this._sessionStorage);

  final AuthRemoteDataSource _remoteDataSource;
  final SessionStorage _sessionStorage;

  @override
  Future<void> clearSession() => _sessionStorage.clear();

  @override
  Future<XtreamSession> login(XtreamCredentials credentials) async {
    final response = await _remoteDataSource.login(credentials);

    if (!_isAuthorized(response)) {
      throw XtreamUnauthorizedException(
        response.userInfo.message ?? 'Login rejeitado pelo servidor Xtream.',
      );
    }

    final serverUrl = _resolveServerUrl(
      response.serverInfo,
      credentials.normalizedBaseUrl,
    );

    return XtreamSession(
      credentials: credentials,
      accountStatus: response.userInfo.status ?? 'Active',
      serverUrl: serverUrl,
      serverTimezone: response.serverInfo?.timezone,
      serverProtocol: response.serverInfo?.serverProtocol,
      message: response.userInfo.message,
    );
  }

  @override
  XtreamCredentials? readSavedCredentials() {
    final saved = _sessionStorage.load();

    if (saved == null) {
      return null;
    }

    return XtreamCredentials(
      baseUrl: saved.baseUrl,
      username: saved.username,
      password: saved.password,
    );
  }

  @override
  Future<void> saveCredentials(XtreamCredentials credentials) {
    return _sessionStorage.save(
      baseUrl: credentials.normalizedBaseUrl,
      username: credentials.username,
      password: credentials.password,
    );
  }

  bool _isAuthorized(AuthResponseDto response) {
    final status = response.userInfo.status?.toLowerCase();
    final activeStatus =
        status == null ||
        status.isEmpty ||
        status == 'active' ||
        status == 'enabled';

    return response.userInfo.auth && activeStatus;
  }

  String _resolveServerUrl(ServerInfoDto? serverInfo, String fallback) {
    if (serverInfo == null ||
        serverInfo.url == null ||
        serverInfo.url!.isEmpty) {
      return fallback;
    }

    final protocol = serverInfo.serverProtocol ?? 'http';
    final port = protocol == 'https' ? serverInfo.httpsPort : serverInfo.port;

    if (port == null || port.isEmpty) {
      return '$protocol://${serverInfo.url}';
    }

    return '$protocol://${serverInfo.url}:$port';
  }
}
