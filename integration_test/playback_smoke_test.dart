import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiviplayer/main.dart' as app;
import 'package:tiviplayer/shared/widgets/content_list_tile.dart';
import 'package:tiviplayer/shared/widgets/section_card.dart';

const _rawBaseUrl = String.fromEnvironment('XTREAM_BASE_URL');
const _username = String.fromEnvironment('XTREAM_USERNAME');
const _password = String.fromEnvironment('XTREAM_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login and open VOD playback on Android', (tester) async {
    expect(_rawBaseUrl, isNotEmpty, reason: 'XTREAM_BASE_URL ausente.');
    expect(_username, isNotEmpty, reason: 'XTREAM_USERNAME ausente.');
    expect(_password, isNotEmpty, reason: 'XTREAM_PASSWORD ausente.');

    final baseUrl = _normalizeBaseUrl(_rawBaseUrl);

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    if (find.text('Sair').evaluate().isNotEmpty &&
        find.byType(TextFormField).evaluate().isEmpty) {
      await _tapVisible(tester, find.widgetWithText(FilledButton, 'Sair'));
      await tester.pump();
      await _pumpUntilFound(
        tester,
        find.text('Conectar'),
        timeout: const Duration(seconds: 10),
      );
    }

    await tester.enterText(find.byType(TextFormField).at(0), baseUrl);
    await tester.enterText(find.byType(TextFormField).at(1), _username);
    await tester.enterText(find.byType(TextFormField).at(2), _password);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    if (find.text('Live').evaluate().isEmpty) {
      await _dismissTextInput(tester);
      await _tapVisible(tester, find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    await _pumpUntilFound(
      tester,
      find.text('Live'),
      timeout: const Duration(seconds: 30),
    );

    await _tapVisible(tester, find.widgetWithText(SectionCard, 'Filmes'));
    await tester.pump();

    await _pumpUntilFound(
      tester,
      find.text('Todos'),
      timeout: const Duration(seconds: 20),
    );

    await _tapVisible(
      tester,
      find.widgetWithText(SectionCard, 'Todos'),
    );
    await tester.pump();

    await _pumpUntilFound(
      tester,
      find.byType(ContentListTile),
      timeout: const Duration(seconds: 30),
    );

    await _tapVisible(tester, find.byType(ContentListTile).first);
    await tester.pump();

    await _pumpUntilFound(
      tester,
      find.text('Reproduzir'),
      timeout: const Duration(seconds: 30),
    );

    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Reproduzir'));
    await tester.pump();

    await _pumpUntilAnyFound(tester, [
      find.text('Sair'),
      find.text('Tentar novamente'),
    ], timeout: const Duration(seconds: 45));

    expect(
      find.text('Sair').evaluate().isNotEmpty ||
          find.text('Tentar novamente').evaluate().isNotEmpty,
      isTrue,
    );
  });
}

String _normalizeBaseUrl(String value) {
  final trimmed = value.trim();
  final uri = Uri.tryParse(trimmed);

  if (trimmed.isEmpty || uri == null || uri.hasScheme) {
    return trimmed;
  }

  return 'http://$trimmed';
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
  await tester.tap(finder);
}

Future<void> _dismissTextInput(WidgetTester tester) async {
  await tester.tapAt(const Offset(16, 16));
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  Duration step = const Duration(milliseconds: 500),
}) async {
  final end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  throw TestFailure('Elemento não encontrado: $finder');
}

Future<void> _pumpUntilAnyFound(
  WidgetTester tester,
  List<Finder> finders, {
  required Duration timeout,
  Duration step = const Duration(milliseconds: 500),
}) async {
  final end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finders.any((finder) => finder.evaluate().isNotEmpty)) {
      return;
    }
  }

  throw TestFailure('Nenhum dos elementos esperados foi encontrado.');
}
