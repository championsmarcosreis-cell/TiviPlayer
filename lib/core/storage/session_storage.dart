import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  SessionStorage(this._preferences);

  final SharedPreferences _preferences;

  static const _baseUrlKey = 'session.baseUrl';
  static const _usernameKey = 'session.username';
  static const _passwordKey = 'session.password';

  SavedSessionData? load() {
    final baseUrl = _preferences.getString(_baseUrlKey);
    final username = _preferences.getString(_usernameKey);
    final password = _preferences.getString(_passwordKey);

    if (baseUrl == null || username == null || password == null) {
      return null;
    }

    return SavedSessionData(
      baseUrl: baseUrl,
      username: username,
      password: password,
    );
  }

  Future<void> save({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    await _preferences.setString(_baseUrlKey, baseUrl);
    await _preferences.setString(_usernameKey, username);
    await _preferences.setString(_passwordKey, password);
  }

  Future<void> clear() async {
    await _preferences.remove(_baseUrlKey);
    await _preferences.remove(_usernameKey);
    await _preferences.remove(_passwordKey);
  }
}

class SavedSessionData {
  const SavedSessionData({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  final String baseUrl;
  final String username;
  final String password;
}
