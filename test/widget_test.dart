import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiviplayer/app/app.dart';
import 'package:tiviplayer/core/di/providers.dart';
import 'package:tiviplayer/shared/testing/app_test_keys.dart';

void main() {
  testWidgets('renderiza tela de login sem sessão salva', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const TiviPlayerApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Acesso').evaluate().isNotEmpty ||
          find.text('Entrar').evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.byKey(AppTestKeys.loginSubmitButton), findsOneWidget);
  });

  testWidgets('mantém o botão Entrar visível em viewport compacta', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(960, 540);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const TiviPlayerApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(AppTestKeys.loginSubmitButton), findsOneWidget);
    expect(find.text('Entrar'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
