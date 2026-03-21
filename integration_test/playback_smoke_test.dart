import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiviplayer/main.dart' as app;
import 'package:tiviplayer/shared/widgets/content_list_tile.dart';

const _baseUrl = String.fromEnvironment('XTREAM_BASE_URL');
const _username = String.fromEnvironment('XTREAM_USERNAME');
const _password = String.fromEnvironment('XTREAM_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login and open VOD playback on Android', (tester) async {
    expect(_baseUrl, isNotEmpty, reason: 'XTREAM_BASE_URL ausente.');
    expect(_username, isNotEmpty, reason: 'XTREAM_USERNAME ausente.');
    expect(_password, isNotEmpty, reason: 'XTREAM_PASSWORD ausente.');

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    if (find.text('Sair').evaluate().isNotEmpty &&
        find.byType(TextFormField).evaluate().isEmpty) {
      await tester.tap(find.text('Sair').first);
      await tester.pump();
      await _pumpUntilFound(
        tester,
        find.text('Conectar'),
        timeout: const Duration(seconds: 10),
      );
    }

    await tester.enterText(find.byType(TextFormField).at(0), _baseUrl);
    await tester.enterText(find.byType(TextFormField).at(1), _username);
    await tester.enterText(find.byType(TextFormField).at(2), _password);

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    await _pumpUntilFound(
      tester,
      find.text('Live'),
      timeout: const Duration(seconds: 30),
    );

    await tester.tap(find.text('Filmes').first);
    await tester.pump();

    await _pumpUntilFound(
      tester,
      find.text('Todos'),
      timeout: const Duration(seconds: 20),
    );

    await tester.tap(find.text('Todos').first);
    await tester.pump();

    await _pumpUntilFound(
      tester,
      find.byType(ContentListTile),
      timeout: const Duration(seconds: 30),
    );

    await tester.tap(find.byType(ContentListTile).first);
    await tester.pump();

    await _pumpUntilFound(
      tester,
      find.text('Reproduzir'),
      timeout: const Duration(seconds: 30),
    );

    await tester.tap(find.text('Reproduzir').first);
    await tester.pump();

    await _pumpUntilFound(
      tester,
      find.text('Sair'),
      timeout: const Duration(seconds: 45),
    );

    expect(find.text('Sair'), findsOneWidget);
  });
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
