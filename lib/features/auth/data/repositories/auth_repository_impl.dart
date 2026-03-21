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
        response.userInfo.message ?? 'A autenticação foi rejeitada.',
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
      serverTimeNow:
          response.serverInfo?.timestampNow ?? response.serverInfo?.timeNow,
      serverProtocol: response.serverInfo?.serverProtocol,
      message: response.userInfo.message,
      expirationDate: response.userInfo.expirationDate,
      isTrial: response.userInfo.isTrial,
      activeConnections: response.userInfo.activeConnections,
      maxConnections: response.userInfo.maxConnections,
    );
  }

  @override
  XtreamSession? readSavedSession() {
    final saved = _sessionStorage.load();

    if (saved == null ||
        saved.baseUrl.trim().isEmpty ||
        saved.username.trim().isEmpty ||
        saved.password.trim().isEmpty) {
      return null;
    }

    return XtreamSession(
      credentials: XtreamCredentials(
        baseUrl: saved.baseUrl,
        username: saved.username,
        password: saved.password,
      ),
      accountStatus: saved.accountStatus ?? 'cached',
      serverUrl: saved.serverUrl,
      serverTimezone: saved.serverTimezone,
      serverTimeNow: saved.serverTimeNow,
      serverProtocol: saved.serverProtocol,
      message: saved.message,
      expirationDate: saved.expirationDate,
      isTrial: saved.isTrial,
      activeConnections: saved.activeConnections,
      maxConnections: saved.maxConnections,
    );
  }

  @override
  Future<void> saveSession(XtreamSession session) {
    return _sessionStorage.save(
      SavedSessionData(
        baseUrl: session.credentials.normalizedBaseUrl,
        username: session.credentials.username,
        password: session.credentials.password,
        accountStatus: session.accountStatus,
        serverUrl: session.serverUrl,
        serverTimezone: session.serverTimezone,
        serverTimeNow: session.serverTimeNow,
        serverProtocol: session.serverProtocol,
        message: session.message,
        expirationDate: session.expirationDate,
        isTrial: session.isTrial,
        activeConnections: session.activeConnections,
        maxConnections: session.maxConnections,
      ),
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
