import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_credentials.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_session.dart';
import 'package:tiviplayer/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tiviplayer/shared/presentation/screens/home_screen.dart';

void main() {
  const session = XtreamSession(
    credentials: XtreamCredentials(
      baseUrl: 'http://provider.example:8080',
      username: 'marcos',
      password: 'secret',
    ),
    accountStatus: 'Active',
    serverUrl: 'http://provider.example:8080',
    expirationDate: '1798761600',
    activeConnections: 1,
    maxConnections: 3,
  );

  testWidgets('home mostra resumo da assinatura sem expor URL técnica', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentSessionProvider.overrideWith((ref) => session)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Minha assinatura'), findsOneWidget);
    expect(find.textContaining('Vence em'), findsWidgets);
    expect(find.textContaining('provider.example'), findsNothing);
    expect(find.textContaining('8080'), findsNothing);
    expect(find.textContaining('http://'), findsNothing);
  });
}
