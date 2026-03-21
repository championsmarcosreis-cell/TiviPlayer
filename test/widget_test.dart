import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiviplayer/app/app.dart';
import 'package:tiviplayer/core/di/providers.dart';

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

    expect(find.text('Conectar'), findsOneWidget);
    expect(find.text('Base URL'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
