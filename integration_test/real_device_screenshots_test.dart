import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiviplayer/main.dart' as app;
import 'package:tiviplayer/shared/testing/app_test_keys.dart';
import 'package:tiviplayer/shared/widgets/content_list_tile.dart';

import 'support/smoke_harness.dart';

const _captureMode = String.fromEnvironment(
  'CAPTURE_MODE',
  defaultValue: 'mobile',
);
const _captureTag = String.fromEnvironment('CAPTURE_TAG', defaultValue: '');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'captura real: login, detalhe e player',
    (tester) async {
      final config = requireSmokeConfig();
      var playerClosed = false;
      final isMobileCapture = _captureMode.toLowerCase() == 'mobile';
      final previousImageHttpClientProvider =
          debugNetworkImageHttpClientProvider;

      // Keep API networking intact and harden only image fetching.
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
      await binding.convertFlutterSurfaceToImage();

      final startState = await pumpUntilAnyFound(
        tester,
        [
          find.byKey(AppTestKeys.loginUsernameField),
          find.byKey(AppTestKeys.homeLogoutButton),
        ],
        timeout: const Duration(seconds: 20),
        description: 'estado inicial login/home',
      );

      if (startState == 1) {
        await tapVisible(
          tester,
          find.byKey(AppTestKeys.homeLogoutButton).hitTestable(),
        );
        await pumpUntilFound(
          tester,
          find.byKey(AppTestKeys.loginUsernameField).hitTestable(),
          timeout: const Duration(seconds: 10),
          description: 'retorno ao login',
        );
      }

      await pumpUntilFound(
        tester,
        find.byKey(AppTestKeys.loginUsernameField),
        timeout: const Duration(seconds: 10),
        description: 'campo usuário no login',
      );
      await pumpUntilFound(
        tester,
        find.byKey(AppTestKeys.loginPasswordField),
        timeout: const Duration(seconds: 10),
        description: 'campo senha no login',
      );

      await _capture(binding, _name('login'));

      final homeVisibleBeforeSubmit =
          find.text('Sair').evaluate().isNotEmpty ||
          find.byKey(AppTestKeys.homeLogoutButton).evaluate().isNotEmpty;

      if (!homeVisibleBeforeSubmit) {
        final baseUrlField = find.byKey(AppTestKeys.loginBaseUrlField);
        if (baseUrlField.evaluate().isNotEmpty) {
          expect(
            config.baseUrl,
            isNotEmpty,
            reason:
                'XTREAM_BASE_URL ausente. Necessario quando a tela exigir servidor manual.',
          );
          await setFormFieldText(
            tester,
            baseUrlField,
            config.baseUrl,
            description: 'campo servidor',
          );
        }
        await setFormFieldText(
          tester,
          find.byKey(AppTestKeys.loginUsernameField),
          config.username,
          description: 'campo usuario',
        );
        await setFormFieldText(
          tester,
          find.byKey(AppTestKeys.loginPasswordField),
          config.password,
          description: 'campo senha',
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await dismissTextInput(tester);

        final homeVisibleNow =
            find.text('Sair').evaluate().isNotEmpty ||
            find.byKey(AppTestKeys.homeLogoutButton).evaluate().isNotEmpty;
        if (!homeVisibleNow) {
          await _tapLoginSubmit(tester);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }

        await pumpUntilAnyFound(
          tester,
          [
            find.byKey(AppTestKeys.homeMoviesCard),
            find.text('Ver filmes'),
            find.text('Sair'),
          ],
          timeout: const Duration(seconds: 30),
          description: 'home após login',
        );
      }

      await pumpUntilAnyFound(
        tester,
        [find.byKey(AppTestKeys.homeMoviesCard), find.text('Ver filmes')],
        timeout: const Duration(seconds: 30),
        description: 'atalho para Filmes na home',
      );

      try {
        await _openMoviesFromHome(tester);

        await pumpUntilFound(
          tester,
          find.byKey(AppTestKeys.vodCategoryAll).hitTestable(),
          timeout: const Duration(seconds: 20),
          description: 'entrada em Filmes',
        );
        await tapVisible(
          tester,
          find.byKey(AppTestKeys.vodCategoryAll).hitTestable(),
        );

        final openedByHero = await _tryOpenFeaturedDetails(tester);
        if (!openedByHero) {
          await openVodDetailsByTap(tester, vodId: config.strictVodId);
        }

        await tester.pumpAndSettle(const Duration(seconds: 1));
        await _capture(binding, _name('detail'));

        await openPlayerByTap(tester);
        await expectPlayerLoadedStrict(tester);
        await tester.pump(const Duration(seconds: 1));
        await _capture(binding, _name('player'));

        await closePlayerAndReturnToVodDetailsByTap(tester);
        playerClosed = true;
      } finally {
        if (!playerClosed) {
          await ensurePlayerClosedIfVisible(
            tester,
            directionalNavigation: false,
          );
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

String _name(String screen) {
  final mode = _captureMode.toLowerCase();
  if (_captureTag.trim().isEmpty) {
    return '${mode}_real_$screen';
  }
  return '${mode}_${_captureTag.trim()}_$screen';
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  await binding.takeScreenshot(name);
}

Future<bool> _tryOpenFeaturedDetails(WidgetTester tester) async {
  final result = await pumpUntilAnyFound(
    tester,
    [find.text('Abrir destaque'), find.byType(ContentListTile)],
    timeout: const Duration(seconds: 30),
    description: 'abertura do catálogo VOD',
  );

  if (result == 0) {
    await tapVisible(tester, find.text('Abrir destaque').first);
    await pumpUntilFound(
      tester,
      find.byKey(AppTestKeys.vodPlayButton),
      timeout: const Duration(seconds: 30),
      description: 'abertura de detalhe via destaque',
    );
    return true;
  }

  return false;
}

Future<void> _tapLoginSubmit(WidgetTester tester) async {
  final byKey = find.byKey(AppTestKeys.loginSubmitButton);
  if (byKey.evaluate().isNotEmpty) {
    await tapVisible(tester, byKey);
    return;
  }

  final byEntrar = find.text('Entrar');
  if (byEntrar.evaluate().isNotEmpty) {
    await tapVisible(tester, byEntrar.first);
    return;
  }

  final byConectar = find.text('Conectar');
  if (byConectar.evaluate().isNotEmpty) {
    await tapVisible(tester, byConectar.first);
    return;
  }

  await pumpUntilFound(
    tester,
    byKey,
    timeout: const Duration(seconds: 10),
    description: 'botão Entrar',
  );
  await tapVisible(tester, byKey);
}

Future<void> _openMoviesFromHome(WidgetTester tester) async {
  final byKey = find.byKey(AppTestKeys.homeMoviesCard).hitTestable();
  if (byKey.evaluate().isNotEmpty) {
    await tapVisible(tester, byKey);
    return;
  }

  final byText = find.text('Ver filmes');
  if (byText.evaluate().isNotEmpty) {
    await tapVisible(tester, byText.first);
    return;
  }

  await pumpUntilFound(
    tester,
    byKey,
    timeout: const Duration(seconds: 10),
    description: 'atalho Filmes',
  );
  await tapVisible(tester, byKey);
}

class _NoAutoUncompressHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.autoUncompress = false;
    return client;
  }
}
