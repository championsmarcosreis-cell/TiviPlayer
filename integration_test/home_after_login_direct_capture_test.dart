import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiviplayer/main.dart' as app;
import 'package:tiviplayer/shared/testing/app_test_keys.dart';

import 'support/smoke_harness.dart';

const _username = String.fromEnvironment('XTREAM_USERNAME');
const _password = String.fromEnvironment('XTREAM_PASSWORD');
const _captureMode = String.fromEnvironment(
  'CAPTURE_MODE',
  defaultValue: 'mobile',
);
const _captureTag = String.fromEnvironment('CAPTURE_TAG', defaultValue: '');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captura direta: home apos login', (tester) async {
    expect(_username, isNotEmpty, reason: 'XTREAM_USERNAME ausente.');
    expect(_password, isNotEmpty, reason: 'XTREAM_PASSWORD ausente.');

    final isMobileCapture = _captureMode.toLowerCase() == 'mobile';
    final previousImageHttpClientProvider = debugNetworkImageHttpClientProvider;
    debugNetworkImageHttpClientProvider = () {
      final client = HttpClient();
      client.autoUncompress = false;
      return client;
    };
    if (isMobileCapture) {
      HttpOverrides.global = _NoAutoUncompressHttpOverrides();
    }
    addTearDown(() {
      debugNetworkImageHttpClientProvider = previousImageHttpClientProvider;
      HttpOverrides.global = null;
    });

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final initial = await pumpUntilAnyFound(
      tester,
      [
        find.byKey(AppTestKeys.homeLiveCard),
        find.byKey(AppTestKeys.loginUsernameField),
      ],
      timeout: const Duration(seconds: 20),
      description: 'estado inicial home/login',
    );

    if (initial == 0) {
      await pumpUntilFound(
        tester,
        find.byKey(AppTestKeys.homeLogoutButton),
        timeout: const Duration(seconds: 10),
        description: 'botao sair',
      );
      await tapVisible(tester, find.byKey(AppTestKeys.homeLogoutButton));
      await pumpUntilFound(
        tester,
        find.byKey(AppTestKeys.loginUsernameField),
        timeout: const Duration(seconds: 10),
        description: 'retorno ao login',
      );
    }

    await _fillAndSubmit(tester);

    final postSubmit = await pumpUntilAnyFound(
      tester,
      [
        find.byKey(AppTestKeys.homeLiveCard),
        find.byKey(AppTestKeys.homeMoviesCard),
        find.text('Campo obrigatorio.'),
      ],
      timeout: const Duration(seconds: 25),
      description: 'resultado do login',
    );

    if (postSubmit == 2) {
      await _fillAndSubmit(tester);
    }

    await pumpUntilAnyFound(
      tester,
      [
        find.byKey(AppTestKeys.homeLiveCard),
        find.byKey(AppTestKeys.homeMoviesCard),
        find.byKey(AppTestKeys.homeSeriesCard),
      ],
      timeout: const Duration(seconds: 35),
      description: 'home carregada',
    );

    await tester.pump(const Duration(seconds: 1));
    await binding.convertFlutterSurfaceToImage();
    await binding.takeScreenshot(_name('home'));
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.loginUsernameField),
    timeout: const Duration(seconds: 10),
    description: 'campo usuario',
  );
  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.loginPasswordField),
    timeout: const Duration(seconds: 10),
    description: 'campo senha',
  );

  await setFormFieldText(
    tester,
    find.byKey(AppTestKeys.loginUsernameField),
    _username,
    description: 'preenchimento do usuario',
  );
  await setFormFieldText(
    tester,
    find.byKey(AppTestKeys.loginPasswordField),
    _password,
    description: 'preenchimento da senha',
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
  await dismissTextInput(tester);
  await tapVisible(tester, find.byKey(AppTestKeys.loginSubmitButton));
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

String _name(String screen) {
  final mode = _captureMode.toLowerCase();
  if (_captureTag.trim().isEmpty) {
    return '${mode}_real_$screen';
  }
  return '${mode}_${_captureTag.trim()}_$screen';
}

class _NoAutoUncompressHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.autoUncompress = false;
    return client;
  }
}
