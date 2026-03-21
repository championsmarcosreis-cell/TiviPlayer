import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_credentials.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_session.dart';
import 'package:tiviplayer/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tiviplayer/features/auth/presentation/screens/account_screen.dart';

void main() {
  const session = XtreamSession(
    credentials: XtreamCredentials(
      baseUrl: 'http://provider.example:8080',
      username: 'marcos',
      password: 'secret',
    ),
    accountStatus: 'Active',
    serverUrl: 'http://provider.example:8080',
    serverTimezone: 'America/Sao_Paulo',
    serverTimeNow: '1798761600',
    expirationDate: '1798761600',
    isTrial: true,
    activeConnections: 1,
    maxConnections: 3,
    message: 'Conta pronta',
  );

  testWidgets('exibe status e vencimento quando disponíveis', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentSessionProvider.overrideWith((ref) => session)],
        child: const MaterialApp(home: AccountScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Minha assinatura'), findsOneWidget);
    expect(find.text('Conta pronta'), findsOneWidget);
    expect(find.text('Vencimento'), findsOneWidget);
    expect(find.text('Período de teste'), findsOneWidget);
    expect(find.text('Conexões ativas'), findsOneWidget);
    expect(find.text('America/Sao_Paulo'), findsOneWidget);
    expect(find.textContaining('provider.example'), findsNothing);
    expect(find.textContaining('8080'), findsNothing);
  });
}
