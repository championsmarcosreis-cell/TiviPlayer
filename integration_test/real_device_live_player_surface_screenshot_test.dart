import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
  final isTvCapture = _captureMode.toLowerCase() == 'tv';

  testWidgets(
    'captura real: superficie do player Live',
    (tester) async {
      await launchAndLogin(tester);
      await binding.convertFlutterSurfaceToImage();

      final loaded = await _openLivePlayerWithRetry(
        tester,
        tvMode: isTvCapture,
      );
      await tester.pump(const Duration(seconds: 6));
      await _capture(
        binding,
        loaded
            ? _name('live_player_surface')
            : _name('live_player_error_surface'),
      );
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}

Future<bool> _openLivePlayerWithRetry(
  WidgetTester tester, {
  required bool tvMode,
}) async {
  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.homeLiveCard),
    timeout: const Duration(seconds: 20),
    description: 'atalho ao vivo na home',
  );
  await tapVisible(tester, find.byKey(AppTestKeys.homeLiveCard));

  final categoryState = await pumpUntilAnyFound(
    tester,
    [
      find.text('Todos'),
      find.text('Sem categorias disponíveis'),
      find.text('Falha ao carregar'),
    ],
    timeout: const Duration(seconds: 30),
    description: 'abertura de categorias ao vivo',
  );
  if (categoryState == 1) {
    throw TestFailure(
      'abertura de categorias ao vivo: tela abriu em empty-state válido.',
    );
  }
  if (categoryState == 2) {
    throw TestFailure('abertura de categorias ao vivo: tela abriu em erro.');
  }

  await tapVisible(tester, find.text('Todos').first);
  await _waitForLiveGrid(tester, tvMode: tvMode);

  if (tvMode) {
    return _openLiveByDpadWithRetry(tester);
  }
  return _openLiveByTapWithRetry(tester);
}

Future<void> _waitForLiveGrid(
  WidgetTester tester, {
  required bool tvMode,
}) async {
  final streamsState = await pumpUntilAnyFound(
    tester,
    [
      if (tvMode)
        find.textContaining('Canais disponíveis')
      else
        find.byType(ContentListTile),
      find.text('Sem canais disponíveis'),
      find.text('Falha ao carregar'),
    ],
    timeout: const Duration(seconds: 35),
    description: 'abertura da grade de canais ao vivo',
  );
  if (streamsState == 1) {
    throw TestFailure(
      'abertura da grade de canais ao vivo: grade abriu em empty-state válido.',
    );
  }
  if (streamsState == 2) {
    throw TestFailure(
      'abertura da grade de canais ao vivo: grade abriu em erro.',
    );
  }
}

Future<bool> _openLiveByTapWithRetry(WidgetTester tester) async {
  const maxAttempts = 6;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final tiles = find.byType(ContentListTile);
    if (tiles.evaluate().isEmpty) {
      throw TestFailure('grade live mobile sem itens selecionáveis.');
    }

    final tileIndex = attempt % tiles.evaluate().length;
    await tapVisible(tester, tiles.at(tileIndex));

    final loaded = await _waitForPlayerLoadedOrError(tester);
    if (loaded) {
      return true;
    }

    // ignore: avoid_print
    print('[live-capture] stream nao reproduziu, tentando proximo item.');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    if (tileIndex == tiles.evaluate().length - 1) {
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -280));
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
      }
    }
  }

  return false;
}

Future<bool> _openLiveByDpadWithRetry(WidgetTester tester) async {
  const maxAttempts = 6;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    await sendRemoteKey(tester, LogicalKeyboardKey.enter);
    final loaded = await _waitForPlayerLoadedOrError(tester);
    if (loaded) {
      return true;
    }

    // ignore: avoid_print
    print('[live-capture] stream nao reproduziu na TV, avancando foco.');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await sendRemoteKey(tester, LogicalKeyboardKey.arrowRight);
  }

  return false;
}

Future<bool> _waitForPlayerLoadedOrError(WidgetTester tester) async {
  final state = await pumpUntilAnyFound(
    tester,
    [
      find.byKey(AppTestKeys.playerLoadedState),
      find.byKey(AppTestKeys.playerErrorState),
    ],
    timeout: const Duration(seconds: 45),
    description: 'estado final do player live',
  );
  return state == 0;
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  final bytes = await binding.takeScreenshot(name);
  final directory = Directory(
    '${Directory.systemTemp.path}/tiviplayer_captures',
  );
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
  final file = File('${directory.path}/$name.png');
  file.writeAsBytesSync(bytes, flush: true);
  // ignore: avoid_print
  print('[capture] ${file.path}');
}

String _name(String screen) {
  final mode = _captureMode.toLowerCase();
  if (_captureTag.trim().isEmpty) {
    return '${mode}_real_$screen';
  }
  return '${mode}_${_captureTag.trim()}_$screen';
}
