import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/providers.dart';
import '../layout/interface_mode_scope.dart';

const _interfaceModePreferenceKey = 'ui.interface_mode';

final interfaceModeControllerProvider =
    NotifierProvider<InterfaceModeController, InterfaceMode>(
      InterfaceModeController.new,
    );

class InterfaceModeController extends Notifier<InterfaceMode> {
  SharedPreferences? _preferences;

  @override
  InterfaceMode build() {
    try {
      _preferences = ref.watch(sharedPreferencesProvider);
    } on UnimplementedError {
      _preferences = null;
    }

    return _restoreStoredMode(_preferences);
  }

  Future<void> setMode(InterfaceMode mode) async {
    if (state == mode) {
      return;
    }
    state = mode;
    await _preferences?.setString(_interfaceModePreferenceKey, mode.name);
  }

  static InterfaceMode _restoreStoredMode(SharedPreferences? preferences) {
    final raw = preferences?.getString(_interfaceModePreferenceKey);
    return switch (raw) {
      'mobile' => InterfaceMode.mobile,
      'tv' => InterfaceMode.tv,
      _ => InterfaceMode.auto,
    };
  }
}
