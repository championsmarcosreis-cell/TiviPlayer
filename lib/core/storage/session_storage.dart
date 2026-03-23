import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SecureSessionStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureSessionStore implements SecureSessionStore {
  FlutterSecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SessionStorage {
  SessionStorage(this._preferences, this._secureStorage);

  final SharedPreferences _preferences;
  final SecureSessionStore _secureStorage;

  static const _securePayloadKey = 'session.payload.secure';
  static const _sessionPayloadKey = 'session.payload';
  static const _baseUrlKey = 'session.baseUrl';
  static const _usernameKey = 'session.username';
  static const _passwordKey = 'session.password';

  Future<SavedSessionData?> load() async {
    final securePayload = await _readSecurePayload();
    if (securePayload != null) {
      return securePayload;
    }

    final legacyPayload = _readLegacyPayload();
    if (legacyPayload == null) {
      return null;
    }

    final migrated = await _writeSecurePayload(legacyPayload);
    if (migrated) {
      await _clearLegacyPayload();
    }

    return legacyPayload;
  }

  Future<void> save(SavedSessionData session) async {
    final writtenSecurely = await _writeSecurePayload(session);
    if (writtenSecurely) {
      await _clearLegacyPayload();
      return;
    }

    // Fallback defensivo: mantém sessão funcional quando o secure storage
    // não está disponível no device/bridge.
    await _writeLegacyPayload(session);
  }

  Future<void> clear() async {
    await _deleteSecurePayload();
    await _clearLegacyPayload();
  }

  Future<SavedSessionData?> _readSecurePayload() async {
    try {
      final payload = await _secureStorage.read(_securePayloadKey);
      return _decodePayload(payload);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<bool> _writeSecurePayload(SavedSessionData session) async {
    try {
      await _secureStorage.write(
        _securePayloadKey,
        jsonEncode(session.toJson()),
      );
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> _deleteSecurePayload() async {
    try {
      await _secureStorage.delete(_securePayloadKey);
    } on PlatformException {
      // Ignora falhas de bridge para manter logout funcional.
    } on MissingPluginException {
      // Ignora falhas quando o plugin não está disponível.
    }
  }

  SavedSessionData? _readLegacyPayload() {
    final payload = _preferences.getString(_sessionPayloadKey);
    final decoded = _decodePayload(payload);
    if (decoded != null) {
      return decoded;
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

  Future<void> _clearLegacyPayload() async {
    await _preferences.remove(_sessionPayloadKey);
    await _preferences.remove(_baseUrlKey);
    await _preferences.remove(_usernameKey);
    await _preferences.remove(_passwordKey);
  }

  Future<void> _writeLegacyPayload(SavedSessionData session) async {
    await _preferences.setString(
      _sessionPayloadKey,
      jsonEncode(session.toJson()),
    );
    await _preferences.setString(_baseUrlKey, session.baseUrl);
    await _preferences.setString(_usernameKey, session.username);
    await _preferences.setString(_passwordKey, session.password);
  }

  SavedSessionData? _decodePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return SavedSessionData.fromJson(decoded);
      }

      if (decoded is Map) {
        return SavedSessionData.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } on FormatException {
      return null;
    }

    return null;
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
