import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_credentials.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_session.dart';
import 'package:tiviplayer/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tiviplayer/features/vod/domain/entities/vod_stream.dart';
import 'package:tiviplayer/features/vod/presentation/providers/vod_providers.dart';
import 'package:tiviplayer/features/vod/presentation/screens/vod_streams_screen.dart';
import 'package:tiviplayer/shared/widgets/branded_artwork.dart';

void main() {
  const session = XtreamSession(
    credentials: XtreamCredentials(
      baseUrl: 'http://provider.example:8080',
      username: 'marcos',
      password: 'secret',
    ),
    accountStatus: 'Active',
  );

  testWidgets('lista VOD renderiza artwork e fallback branded', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionProvider.overrideWith((ref) => session),
          vodStreamsProvider.overrideWith(
            (ref, categoryId) async => const [
              VodStream(
                id: '10',
                name: 'Filme 1',
                coverUrl: null,
                containerExtension: 'mp4',
                rating: '8.5',
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: VodStreamsScreen(categoryId: 'all')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Filme 1'), findsOneWidget);
    expect(find.byType(BrandedArtwork), findsOneWidget);
  });

  testWidgets('fallback branded mostra placeholder em tamanho confortável', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: BrandedArtwork(
                imageUrl: null,
                placeholderLabel: 'Poster indisponível',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Poster indisponível'), findsOneWidget);
  });
}
