import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiviplayer/core/storage/session_storage.dart';

void main() {
  test('migra sessão legada para secure storage e limpa texto puro', () async {
    final preferences = await _preferencesWith({
      'session.baseUrl': 'http://example.com',
      'session.username': 'sergio',
      'session.password': '123456',
    });
    final secureStore = _FakeSecureSessionStore();
    final storage = SessionStorage(preferences, secureStore);

    final loaded = await storage.load();

    expect(loaded, isNotNull);
    expect(loaded!.username, 'sergio');
    expect(secureStore.values.containsKey('session.payload.secure'), isTrue);
    expect(preferences.getString('session.baseUrl'), isNull);
    expect(preferences.getString('session.username'), isNull);
    expect(preferences.getString('session.password'), isNull);
  });

  test('grava fallback em SharedPreferences quando secure falha', () async {
    final preferences = await _preferencesWith({});
    final secureStore = _FakeSecureSessionStore(throwOnWrite: true);
    final storage = SessionStorage(preferences, secureStore);

    await storage.save(
      const SavedSessionData(
        baseUrl: 'http://example.com',
        username: 'sergio',
        password: '123456',
      ),
    );

    expect(preferences.getString('session.payload'), isNotNull);
    expect(preferences.getString('session.baseUrl'), 'http://example.com');
    expect(preferences.getString('session.username'), 'sergio');
    expect(preferences.getString('session.password'), '123456');
    expect(secureStore.values, isEmpty);
  });

  test('carrega legado quando secure indisponível', () async {
    final preferences = await _preferencesWith({
      'session.baseUrl': 'http://example.com',
      'session.username': 'sergio',
      'session.password': '123456',
    });
    final secureStore = _FakeSecureSessionStore(
      throwOnRead: true,
      throwOnWrite: true,
    );
    final storage = SessionStorage(preferences, secureStore);

    final loaded = await storage.load();

    expect(loaded, isNotNull);
    expect(loaded!.baseUrl, 'http://example.com');
    expect(preferences.getString('session.baseUrl'), 'http://example.com');
  });
}

Future<SharedPreferences> _preferencesWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

class _FakeSecureSessionStore implements SecureSessionStore {
  _FakeSecureSessionStore({
    this.throwOnRead = false,
    this.throwOnWrite = false,
  });

  final bool throwOnRead;
  final bool throwOnWrite;
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    if (throwOnRead) {
      throw MissingPluginException('Secure storage indisponível');
    }

    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (throwOnWrite) {
      throw MissingPluginException('Secure storage indisponível');
    }

    values[key] = value;
  }
}
