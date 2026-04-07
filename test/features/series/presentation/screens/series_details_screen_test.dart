import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiviplayer/core/di/providers.dart';
import 'package:tiviplayer/features/series/domain/entities/series_episode.dart';
import 'package:tiviplayer/features/series/domain/entities/series_info.dart';
import 'package:tiviplayer/features/series/presentation/providers/series_providers.dart';
import 'package:tiviplayer/features/series/presentation/screens/series_details_screen.dart';
import 'package:tiviplayer/shared/presentation/layout/interface_mode_scope.dart';

void main() {
  testWidgets(
    'detalhes de serie usam seletor compacto de temporada e exibem plot do episodio selecionado',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSeriesDetails(
        tester,
        preferences: preferences,
        info: _sampleInfo,
      );

      await tester.pumpAndSettle();

      expect(find.text('Panorama da série'), findsNothing);
      expect(find.text('Próximo episódio'), findsNothing);
      expect(
        find.text('A equipe encontra o primeiro sinal vindo da nebulosa.'),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.text(
          'A nova temporada abre com a cidade orbital em alerta maximo.',
        ),
        findsNothing,
      );

      final seasonSelector = find.text('Temporada 1 • 2 eps');
      await tester.ensureVisible(seasonSelector);
      await tester.tap(seasonSelector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Temporada 2 • 1 eps').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'A nova temporada abre com a cidade orbital em alerta maximo.',
        ),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.text('A equipe encontra o primeiro sinal vindo da nebulosa.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'detalhes de serie na TV usam seletor compacto de temporada e mantem plot visivel',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1920, 1080);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSeriesDetails(
        tester,
        preferences: preferences,
        info: _sampleInfo,
        interfaceMode: InterfaceMode.tv,
      );

      expect(find.text('Temporadas e episódios'), findsNothing);
      expect(find.text('TEMPORADAS'), findsOneWidget);
      expect(find.text('ESCOLHA A TEMPORADA'), findsOneWidget);
      expect(find.text('Temporada 2'), findsNothing);
      expect(
        find.text('A equipe encontra o primeiro sinal vindo da nebulosa.'),
        findsAtLeastNWidgets(1),
      );

      await tester.tap(find.text('Temporada 1').last);
      await tester.pumpAndSettle();
      expect(find.text('Temporada 2'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Temporada 2').first);
      await tester.pumpAndSettle();

      expect(find.text('Retomar em Episódio 1'), findsNothing);
      expect(find.text('Entrada sugerida: Episódio 1'), findsOneWidget);
      expect(find.text('Temporada 2'), findsAtLeastNWidgets(1));
      expect(
        find.text(
          'A nova temporada abre com a cidade orbital em alerta maximo.',
        ),
        findsAtLeastNWidgets(1),
      );
    },
  );
}

const _sampleInfo = SeriesInfo(
  id: 'series-1',
  name: 'Galaxia Aurora',
  plot: 'Uma tripulacao atravessa mundos desconhecidos.',
  genre: 'Anime',
  seasonCount: 2,
  episodeCount: 3,
  episodes: [
    SeriesEpisode(
      id: 'ep-1',
      title: 'Primeiro contato',
      seasonNumber: 1,
      episodeNumber: 1,
      plot: 'A equipe encontra o primeiro sinal vindo da nebulosa.',
      duration: '24 min',
    ),
    SeriesEpisode(
      id: 'ep-2',
      title: 'Rastro lunar',
      seasonNumber: 1,
      episodeNumber: 2,
      plot: 'Uma pista antiga leva a tripulacao ate uma base esquecida.',
      duration: '24 min',
    ),
    SeriesEpisode(
      id: 'ep-3',
      title: 'A queda do cometa',
      seasonNumber: 2,
      episodeNumber: 1,
      plot: 'A nova temporada abre com a cidade orbital em alerta maximo.',
      duration: '25 min',
    ),
  ],
);

Future<void> _pumpSeriesDetails(
  WidgetTester tester, {
  required SharedPreferences preferences,
  required SeriesInfo info,
  InterfaceMode interfaceMode = InterfaceMode.mobile,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => preferences),
        seriesInfoProvider.overrideWith((ref, seriesId) async => info),
        seriesItemsProvider.overrideWith((ref, categoryId) async => const []),
      ],
      child: InterfaceModeScope(
        mode: interfaceMode,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: SeriesDetailsScreen.buildLocation('series-1'),
            routes: [
              GoRoute(
                path: SeriesDetailsScreen.routePath,
                builder: (context, state) =>
                    const SeriesDetailsScreen(seriesId: 'series-1'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}
