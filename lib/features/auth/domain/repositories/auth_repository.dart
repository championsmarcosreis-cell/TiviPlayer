import '../entities/xtream_credentials.dart';
import '../entities/xtream_session.dart';

abstract class AuthRepository {
  Future<XtreamSession> login(XtreamCredentials credentials);
  Future<void> saveCredentials(XtreamCredentials credentials);
  XtreamCredentials? readSavedCredentials();
  Future<void> clearSession();
}
