import '../entities/xtream_credentials.dart';
import '../entities/xtream_session.dart';

abstract class AuthRepository {
  Future<XtreamSession> login(XtreamCredentials credentials);
  Future<void> saveSession(XtreamSession session);
  XtreamSession? readSavedSession();
  Future<void> clearSession();
}
