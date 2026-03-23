import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../network/xtream_client.dart';
import '../storage/session_storage.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences override ausente.'),
);

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final secureStorageProvider = Provider<SecureSessionStore>((ref) {
  return FlutterSecureSessionStore();
});

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 8),
      responseType: ResponseType.plain,
    ),
  );
});

final xtreamClientProvider = Provider<XtreamClient>((ref) {
  return XtreamClient(ref.watch(dioProvider));
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(
    ref.watch(sharedPreferencesProvider),
    ref.watch(secureStorageProvider),
  );
});
