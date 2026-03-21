import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  SessionStorage(this._preferences);

  final SharedPreferences _preferences;

  static const _sessionPayloadKey = 'session.payload';
  static const _baseUrlKey = 'session.baseUrl';
  static const _usernameKey = 'session.username';
  static const _passwordKey = 'session.password';

  SavedSessionData? load() {
    final payload = _preferences.getString(_sessionPayloadKey);
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic>) {
          return SavedSessionData.fromJson(data);
        }

        if (data is Map) {
          return SavedSessionData.fromJson(
            data.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      } on FormatException {
        // Fall back to the legacy keys below.
      }
    }

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

  Future<void> save(SavedSessionData session) async {
    await _preferences.setString(_sessionPayloadKey, jsonEncode(session));
    await _preferences.setString(_baseUrlKey, session.baseUrl);
    await _preferences.setString(_usernameKey, session.username);
    await _preferences.setString(_passwordKey, session.password);
  }

  Future<void> clear() async {
    await _preferences.remove(_sessionPayloadKey);
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
    this.accountStatus,
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

  final String baseUrl;
  final String username;
  final String password;
  final String? accountStatus;
  final String? serverUrl;
  final String? serverTimezone;
  final String? serverTimeNow;
  final String? serverProtocol;
  final String? message;
  final String? expirationDate;
  final bool? isTrial;
  final int? activeConnections;
  final int? maxConnections;

  factory SavedSessionData.fromJson(Map<String, dynamic> json) {
    return SavedSessionData(
      baseUrl: json['baseUrl'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      accountStatus: json['accountStatus'] as String?,
      serverUrl: json['serverUrl'] as String?,
      serverTimezone: json['serverTimezone'] as String?,
      serverTimeNow: json['serverTimeNow'] as String?,
      serverProtocol: json['serverProtocol'] as String?,
      message: json['message'] as String?,
      expirationDate: json['expirationDate'] as String?,
      isTrial: json['isTrial'] as bool?,
      activeConnections: (json['activeConnections'] as num?)?.toInt(),
      maxConnections: (json['maxConnections'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'username': username,
      'password': password,
      'accountStatus': accountStatus,
      'serverUrl': serverUrl,
      'serverTimezone': serverTimezone,
      'serverTimeNow': serverTimeNow,
      'serverProtocol': serverProtocol,
      'message': message,
      'expirationDate': expirationDate,
      'isTrial': isTrial,
      'activeConnections': activeConnections,
      'maxConnections': maxConnections,
    };
  }
}
