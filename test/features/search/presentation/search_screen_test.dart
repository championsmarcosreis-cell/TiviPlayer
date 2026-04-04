import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/live/domain/entities/live_stream.dart';
import 'package:tiviplayer/features/live/presentation/providers/live_providers.dart';
import 'package:tiviplayer/features/search/presentation/screens/search_screen.dart';
import 'package:tiviplayer/features/series/domain/entities/series_item.dart';
import 'package:tiviplayer/features/series/presentation/providers/series_providers.dart';
import 'package:tiviplayer/features/vod/domain/entities/vod_stream.dart';
import 'package:tiviplayer/features/vod/presentation/providers/vod_providers.dart';
import 'package:tiviplayer/shared/widgets/mobile_primary_dock.dart';

void main() {
  testWidgets(
    'busca geral só carrega catálogos após query mínima com debounce',
    (tester) async {
      var liveRequested = false;
      var vodRequested = false;
      var seriesRequested = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveStreamsProvider.overrideWith((ref, categoryId) async {
              liveRequested = true;
              return const <LiveStream>[];
            }),
            vodStreamsProvider.overrideWith((ref, categoryId) async {
              vodRequested = true;
              return const <VodStream>[];
            }),
            seriesItemsProvider.overrideWith((ref, categoryId) async {
              seriesRequested = true;
              return const <SeriesItem>[];
            }),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );

      await tester.pump();

      expect(liveRequested, isFalse);
      expect(vodRequested, isFalse);
      expect(seriesRequested, isFalse);

      await tester.enterText(find.byType(TextField), 's');
      await tester.pump(const Duration(milliseconds: 400));

      expect(liveRequested, isFalse);
      expect(vodRequested, isFalse);
      expect(seriesRequested, isFalse);
      expect(find.text('Digite mais um pouco'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'so');
      await tester.pump(const Duration(milliseconds: 100));

      expect(liveRequested, isFalse);
      expect(vodRequested, isFalse);
      expect(seriesRequested, isFalse);

      await tester.pump(const Duration(milliseconds: 300));

      expect(liveRequested, isTrue);
      expect(vodRequested, isTrue);
      expect(seriesRequested, isTrue);
    },
  );

  test('dock trata live, vod e séries como contexto de home', () {
    expect(
      resolveMobilePrimaryDockSection('/home'),
      MobilePrimaryDockSection.home,
    );
    expect(
      resolveMobilePrimaryDockSection('/live'),
      MobilePrimaryDockSection.home,
    );
    expect(
      resolveMobilePrimaryDockSection('/live/category/9'),
      MobilePrimaryDockSection.home,
    );
    expect(
      resolveMobilePrimaryDockSection('/vod/details/44'),
      MobilePrimaryDockSection.home,
    );
    expect(
      resolveMobilePrimaryDockSection('/series/category/all'),
      MobilePrimaryDockSection.home,
    );
    expect(
      resolveMobilePrimaryDockSection('/search'),
      MobilePrimaryDockSection.search,
    );
    expect(
      resolveMobilePrimaryDockSection('/account'),
      MobilePrimaryDockSection.account,
    );
  });
}
