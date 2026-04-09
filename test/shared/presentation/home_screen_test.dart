import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_credentials.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_session.dart';
import 'package:tiviplayer/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tiviplayer/features/home/data/models/home_discovery_dto.dart';
import 'package:tiviplayer/features/home/presentation/providers/home_discovery_providers.dart';
import 'package:tiviplayer/features/live/domain/entities/live_epg_entry.dart';
import 'package:tiviplayer/features/live/domain/entities/live_stream.dart';
import 'package:tiviplayer/features/live/presentation/providers/live_providers.dart';
import 'package:tiviplayer/features/series/domain/entities/series_item.dart';
import 'package:tiviplayer/features/series/presentation/providers/series_providers.dart';
import 'package:tiviplayer/features/vod/domain/entities/vod_category.dart';
import 'package:tiviplayer/features/vod/domain/entities/vod_stream.dart';
import 'package:tiviplayer/features/vod/presentation/providers/vod_providers.dart';
import 'package:tiviplayer/shared/presentation/layout/interface_mode_scope.dart';
import 'package:tiviplayer/shared/presentation/screens/home_screen.dart';
import 'package:tiviplayer/shared/testing/app_test_keys.dart';

const _session = XtreamSession(
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

void main() {
  test('segura hero mobile enquanto o discovery ainda está carregando', () {
    expect(
      shouldHoldMobileHeroForDiscovery(
        const AsyncValue<HomeDiscoveryDto?>.loading(),
        discoveryHome: null,
      ),
      isTrue,
    );
    expect(
      shouldHoldMobileHeroForDiscovery(
        const AsyncValue<HomeDiscoveryDto?>.data(null),
        discoveryHome: null,
      ),
      isFalse,
    );
  });

  test(
    'resolve playback live do discovery com fallback estável no cliente',
    () {
      const discoveryItem = HomeDiscoveryItemDto(
        id: 'live-41',
        title: 'DISCOVERY TURBO',
        subtitle: 'Ao vivo',
        description: null,
        image: 'https://example.com/discoveryturbo.png',
        backdrop: null,
        mediaType: 'TV',
        contentId: '999',
        tmdbId: null,
        rating: null,
        year: null,
        genres: <String>[],
        runtime: null,
        provider: null,
        channelNumber: 148,
        progress: null,
        badges: <String>['LIVE'],
        genreIds: <int>[],
      );
      const liveStreams = <LiveStream>[
        LiveStream(
          id: '41',
          name: 'DISCOVERY TURBO',
          hasArchive: false,
          isAdult: false,
        ),
      ];

      expect(
        resolveDiscoveryLivePlaybackItemId(discoveryItem, liveStreams),
        '41',
      );
      expect(
        resolveDiscoveryLivePlaybackItemId(discoveryItem, const <LiveStream>[]),
        '41',
      );
    },
  );

  test('prioriza series_id para abrir detalhe de serie do discovery', () {
    const discoveryItem = HomeDiscoveryItemDto(
      id: 'content-46',
      seriesId: '2',
      title: 'A Knight of the Seven Kingdoms',
      subtitle: 'TV Series',
      description: 'Serie',
      image: 'https://example.com/series.jpg',
      backdrop: null,
      mediaType: 'Series',
      contentId: '46',
      tmdbId: null,
      rating: null,
      year: 2026,
      genres: <String>[],
      runtime: null,
      provider: null,
      channelNumber: null,
      progress: null,
      badges: <String>[],
      genreIds: <int>[],
    );

    expect(resolveDiscoverySeriesNavigationId(discoveryItem), '2');
  });

  test('mantem fallback para content_id quando series_id nao vier', () {
    const discoveryItem = HomeDiscoveryItemDto(
      id: 'content-201',
      title: 'Nebula 9',
      subtitle: 'TV Series',
      description: 'Serie',
      image: 'https://example.com/series.jpg',
      backdrop: null,
      mediaType: 'Series',
      contentId: '201',
      tmdbId: null,
      rating: null,
      year: 2026,
      genres: <String>[],
      runtime: null,
      provider: null,
      channelNumber: null,
      progress: null,
      badges: <String>[],
      genreIds: <int>[],
    );

    expect(resolveDiscoverySeriesNavigationId(discoveryItem), '201');
  });

  testWidgets('home mostra status da assinatura sem expor URL técnica', (
    tester,
  ) async {
    await _pumpHomeScreen(tester);

    await tester.pumpAndSettle();

    expect(find.text('Minha assinatura'), findsNothing);
    expect(find.textContaining('Ativa'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Busca'), findsOneWidget);
    expect(find.text('Conta'), findsOneWidget);
    expect(find.textContaining('provider.example'), findsNothing);
    expect(find.textContaining('8080'), findsNothing);
    expect(find.textContaining('http://'), findsNothing);
  });

  testWidgets('home mobile oculta Kids quando nao ha conteudo kids acessivel', (
    tester,
  ) async {
    await _pumpHomeScreen(
      tester,
      discoveryHome: HomeDiscoveryDto(
        generatedAt: '2026-04-04T02:00:00Z',
        heroSlider: null,
        hero: null,
        highlights: null,
        continueWatching: null,
        hasContinueWatchingField: true,
        moviesLibrary: const HomeDiscoveryRailDto(
          slug: 'movies-library',
          title: 'Filmes',
          description: 'Filmes do catálogo.',
          layout: 'poster',
          libraryKind: 'movies',
          items: <HomeDiscoveryItemDto>[],
        ),
        seriesLibrary: const HomeDiscoveryRailDto(
          slug: 'series-library',
          title: 'Séries',
          description: 'Séries do catálogo.',
          layout: 'poster',
          libraryKind: 'series',
          items: <HomeDiscoveryItemDto>[],
        ),
        animeLibrary: const HomeDiscoveryRailDto(
          slug: 'anime-library',
          title: 'Anime',
          description: 'Anime do catálogo.',
          layout: 'poster',
          libraryKind: 'anime',
          items: <HomeDiscoveryItemDto>[],
        ),
        liveLibrary: null,
        libraries: const <HomeDiscoveryRailDto>[],
        liveNow: null,
        trendingNow: null,
        moviesForToday: null,
        seriesToBinge: null,
        animeSpotlight: null,
        rails: const <HomeDiscoveryRailDto>[],
      ),
      vodItems: const <VodStream>[
        VodStream(id: '1', name: 'Missão Final', libraryKind: 'movies'),
      ],
      seriesItems: const <SeriesItem>[
        SeriesItem(id: '2', name: 'Nebula 9', libraryKind: 'series'),
      ],
    );

    await tester.pumpAndSettle();

    expect(find.byKey(AppTestKeys.homeKidsCard), findsNothing);
  });

  testWidgets(
    'home mobile nao promove Kids apenas por slug ou texto sem library_kind',
    (tester) async {
      await _pumpHomeScreen(
        tester,
        discoveryHome: HomeDiscoveryDto(
          generatedAt: '2026-04-04T02:05:00Z',
          heroSlider: null,
          hero: null,
          highlights: null,
          continueWatching: null,
          hasContinueWatchingField: true,
          moviesLibrary: null,
          seriesLibrary: null,
          animeLibrary: null,
          liveLibrary: null,
          libraries: const <HomeDiscoveryRailDto>[
            HomeDiscoveryRailDto(
              slug: 'kids',
              title: 'Kids',
              description: 'Rail legado sem sinal canônico.',
              layout: 'poster',
              items: <HomeDiscoveryItemDto>[
                HomeDiscoveryItemDto(
                  id: 'kids-legacy-1',
                  title: 'Turma da Floresta',
                  subtitle: 'Infantil',
                  description:
                      'Conteúdo com cara de kids, mas sem library_kind.',
                  image: null,
                  backdrop: null,
                  mediaType: 'VOD',
                  contentId: '701',
                  tmdbId: null,
                  rating: null,
                  year: null,
                  genres: <String>[],
                  runtime: null,
                  provider: null,
                  channelNumber: null,
                  progress: null,
                  badges: <String>[],
                  genreIds: <int>[],
                ),
              ],
            ),
          ],
          liveNow: null,
          trendingNow: null,
          moviesForToday: null,
          seriesToBinge: null,
          animeSpotlight: null,
          rails: const <HomeDiscoveryRailDto>[],
        ),
        vodItems: const <VodStream>[
          VodStream(id: '91', name: 'Clube da Aventura Infantil'),
        ],
        seriesItems: const <SeriesItem>[
          SeriesItem(id: '92', name: 'Patrulha Mirim', plot: 'Série infantil.'),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.byKey(AppTestKeys.homeKidsCard), findsNothing);
    },
  );

  testWidgets(
    'home mobile mostra Kids quando ha conteudo kids real no payload',
    (tester) async {
      await _pumpHomeScreen(
        tester,
        vodItems: const <VodStream>[
          VodStream(id: '77', name: 'Turma da Floresta', libraryKind: 'kids'),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.byKey(AppTestKeys.homeKidsCard), findsOneWidget);
    },
  );

  testWidgets('home tv mostra programa atual e faixa horaria nos destaques', (
    tester,
  ) async {
    final now = DateTime.now();
    final current = LiveEpgEntry(
      title: 'Jornal da Manha',
      startAt: now.subtract(const Duration(minutes: 12)),
      endAt: now.add(const Duration(minutes: 18)),
    );
    final next = LiveEpgEntry(
      title: 'Giro do Esporte',
      startAt: now.add(const Duration(minutes: 18)),
      endAt: now.add(const Duration(minutes: 58)),
    );

    await _pumpHomeScreen(
      tester,
      interfaceMode: InterfaceMode.tv,
      streams: _sampleStreams(),
      epgByStreamId: {
        'stream-1': [current, next],
      },
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Canal Centro'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Agora: Jornal da Manha'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('Giro do Esporte'), findsNothing);
  });

  testWidgets('home tv usa fallback limpo quando o canal nao tem EPG', (
    tester,
  ) async {
    await _pumpHomeScreen(
      tester,
      interfaceMode: InterfaceMode.tv,
      streams: [_sampleStreams().last],
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Ao vivo agora'), findsOneWidget);
    expect(find.text('Canal Sul'), findsAtLeastNWidgets(1));
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets(
    'home tv padroniza continuar assistindo em rail com multiplos cards',
    (tester) async {
      await _pumpHomeScreen(
        tester,
        interfaceMode: InterfaceMode.tv,
        discoveryHome: HomeDiscoveryDto(
          generatedAt: '2026-04-08T03:30:00Z',
          heroSlider: null,
          hero: null,
          highlights: null,
          continueWatching: const HomeDiscoveryRailDto(
            slug: 'continue-watching',
            title: 'Continuar assistindo',
            description: 'Retome filmes e episódios recentes.',
            layout: 'continue-watching',
            items: <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'continue-vod-44',
                title: 'Missão Final',
                subtitle: 'VOD',
                description: 'Filme em andamento.',
                image: 'https://example.com/missao-poster.jpg',
                backdrop: 'https://example.com/missao-backdrop.jpg',
                mediaType: 'VOD',
                contentId: '44',
                tmdbId: null,
                rating: 7.1,
                year: 2025,
                genres: <String>['Ação'],
                runtime: 112,
                provider: null,
                channelNumber: null,
                progress: 0.42,
                badges: <String>[],
                genreIds: <int>[28],
              ),
              HomeDiscoveryItemDto(
                id: 'continue-series-201',
                seriesId: '201',
                title: 'Nebula 9',
                subtitle: 'TV Series',
                description: 'Série em andamento.',
                image: 'https://example.com/nebula-poster.jpg',
                backdrop: 'https://example.com/nebula-backdrop.jpg',
                mediaType: 'Series',
                contentId: '201',
                tmdbId: null,
                rating: null,
                year: 2026,
                genres: <String>['Drama'],
                runtime: null,
                provider: null,
                channelNumber: null,
                progress: 0.68,
                badges: <String>[],
                genreIds: <int>[18],
              ),
            ],
          ),
          hasContinueWatchingField: true,
          moviesLibrary: null,
          seriesLibrary: null,
          animeLibrary: null,
          liveLibrary: null,
          libraries: const <HomeDiscoveryRailDto>[],
          liveNow: null,
          trendingNow: null,
          moviesForToday: null,
          seriesToBinge: null,
          animeSpotlight: null,
          rails: const <HomeDiscoveryRailDto>[],
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 700));

      expect(
        find.byKey(const ValueKey<String>('home.continue.section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('home.continue.card.vod:44')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('home.continue.card.series:201')),
        findsOneWidget,
      );
      expect(find.text('Missão Final'), findsOneWidget);
      expect(find.text('Nebula 9'), findsOneWidget);
    },
  );

  testWidgets(
    'home tv preserva a backdrop do discovery ao promover destaque para o hero',
    (tester) async {
      const posterUrl = 'https://example.com/resgate-poster.jpg';
      const backdropUrl = 'https://example.com/resgate-backdrop.jpg';

      await _pumpHomeScreen(
        tester,
        interfaceMode: InterfaceMode.tv,
        discoveryHome: HomeDiscoveryDto(
          generatedAt: '2026-04-08T03:30:00Z',
          heroSlider: null,
          hero: null,
          highlights: HomeDiscoveryRailDto(
            slug: 'highlights',
            title: 'Destaques',
            description: 'Top vistos com arte limpa.',
            layout: 'poster',
            items: const <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'highlight-44',
                title: 'Resgate Implacável',
                subtitle: 'VOD',
                description: 'Ação para abrir a sessão.',
                image: posterUrl,
                backdrop: backdropUrl,
                mediaType: 'VOD',
                contentId: '44',
                tmdbId: null,
                rating: 6.7,
                year: 2025,
                genres: <String>['Ação'],
                runtime: 116,
                provider: null,
                channelNumber: null,
                progress: null,
                badges: <String>['TOP'],
                genreIds: <int>[28],
              ),
            ],
          ),
          continueWatching: null,
          hasContinueWatchingField: true,
          moviesLibrary: null,
          seriesLibrary: null,
          animeLibrary: null,
          liveLibrary: null,
          libraries: const <HomeDiscoveryRailDto>[],
          liveNow: null,
          trendingNow: null,
          moviesForToday: null,
          seriesToBinge: null,
          animeSpotlight: null,
          rails: const <HomeDiscoveryRailDto>[],
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 700));

      final heroArtworkFinder = find.byKey(
        const ValueKey<String>('home.tv.hero.artwork'),
      );
      expect(heroArtworkFinder, findsOneWidget);

      final heroArtwork = tester.widget<Image>(heroArtworkFinder);
      expect((heroArtwork.image as NetworkImage).url, backdropUrl);
      expect(find.text('Resgate Implacável'), findsAtLeastNWidgets(1));
      expect(find.text('TV ao vivo'), findsNothing);
    },
  );

  testWidgets(
    'home tv mantém a artwork do hero acima da paginação e do primeiro ver tudo',
    (tester) async {
      const firstBackdropUrl = 'https://example.com/zona-backdrop.jpg';
      const secondBackdropUrl = 'https://example.com/solo-backdrop.jpg';

      await _pumpHomeScreen(
        tester,
        interfaceMode: InterfaceMode.tv,
        streams: _sampleStreams(),
        discoveryHome: HomeDiscoveryDto(
          generatedAt: '2026-04-08T03:30:00Z',
          heroSlider: const HomeDiscoveryRailDto(
            slug: 'hero-slider',
            title: 'Hero slider',
            description: 'Slides principais para a vitrine.',
            layout: 'hero',
            items: <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'hero-1',
                title: 'Zona de Caça',
                subtitle: 'VOD',
                description: 'Filme para abrir a home.',
                image: 'https://example.com/zona-poster.jpg',
                backdrop: firstBackdropUrl,
                mediaType: 'VOD',
                contentId: '501',
                tmdbId: null,
                rating: 6.4,
                year: 2025,
                genres: <String>['Ação'],
                runtime: 101,
                provider: null,
                channelNumber: null,
                progress: null,
                badges: <String>['NOVO'],
                genreIds: <int>[28],
              ),
              HomeDiscoveryItemDto(
                id: 'hero-2',
                title: 'Solo Leveling',
                subtitle: 'Anime',
                description: 'Anime em destaque.',
                image: 'https://example.com/solo-poster.jpg',
                backdrop: secondBackdropUrl,
                mediaType: 'SERIES',
                contentId: '777',
                tmdbId: null,
                rating: 8.7,
                year: 2024,
                genres: <String>['Anime'],
                runtime: 24,
                provider: null,
                channelNumber: null,
                progress: null,
                badges: <String>['TOP'],
                genreIds: <int>[16],
              ),
            ],
          ),
          hero: null,
          highlights: null,
          continueWatching: null,
          hasContinueWatchingField: true,
          moviesLibrary: null,
          seriesLibrary: null,
          animeLibrary: null,
          liveLibrary: null,
          libraries: const <HomeDiscoveryRailDto>[],
          liveNow: null,
          trendingNow: null,
          moviesForToday: null,
          seriesToBinge: null,
          animeSpotlight: null,
          rails: const <HomeDiscoveryRailDto>[],
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 700));

      final heroArtworkFinder = find.byKey(
        const ValueKey<String>('home.tv.hero.artwork'),
      );
      final paginationFinder = find.byKey(
        const ValueKey<String>('home.tv.hero.pagination'),
      );
      final liveViewAllFinder = find.byKey(
        const ValueKey<String>('home.tv.rail.viewAll.Canais ao vivo'),
      );

      expect(heroArtworkFinder, findsOneWidget);
      expect(paginationFinder, findsOneWidget);
      expect(liveViewAllFinder, findsOneWidget);

      final heroArtworkRect = tester.getRect(heroArtworkFinder);
      final paginationRect = tester.getRect(paginationFinder);
      final liveViewAllRect = tester.getRect(liveViewAllFinder);

      expect(heroArtworkRect.bottom, lessThan(paginationRect.top - 12));
      expect(heroArtworkRect.bottom, lessThan(liveViewAllRect.top - 12));
    },
  );

  testWidgets(
    'home mobile mostra EPG compacto nos cards live quando houver grade',
    (tester) async {
      final now = DateTime.now();
      final current = LiveEpgEntry(
        title: 'Jornal da Manha',
        startAt: now.subtract(const Duration(minutes: 12)),
        endAt: now.add(const Duration(minutes: 18)),
      );
      final next = LiveEpgEntry(
        title: 'Giro do Esporte',
        startAt: now.add(const Duration(minutes: 18)),
        endAt: now.add(const Duration(minutes: 58)),
      );

      await _pumpHomeScreen(
        tester,
        streams: _sampleStreams(),
        epgByStreamId: {
          'stream-1': [current, next],
        },
      );

      await tester.pumpAndSettle();

      expect(find.text('Jornal da Manha'), findsOneWidget);
      expect(
        find.text(_formatRange(current.startAt, current.endAt)),
        findsOneWidget,
      );
      expect(
        find.text('Depois ${_formatClock(next.startAt)} • Giro do Esporte'),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    },
  );

  testWidgets(
    'home mobile usa id live do discovery para renderizar EPG compacto',
    (tester) async {
      final now = DateTime.now();
      final current = LiveEpgEntry(
        title: 'Pesca Mortal',
        startAt: now.subtract(const Duration(minutes: 8)),
        endAt: now.add(const Duration(minutes: 22)),
      );
      final next = LiveEpgEntry(
        title: 'Patrulheiros da Natureza',
        startAt: now.add(const Duration(minutes: 22)),
        endAt: now.add(const Duration(minutes: 62)),
      );

      await _pumpHomeScreen(
        tester,
        discoveryHome: HomeDiscoveryDto(
          generatedAt: '2026-04-04T02:10:00Z',
          heroSlider: null,
          hero: null,
          highlights: null,
          continueWatching: null,
          hasContinueWatchingField: true,
          moviesLibrary: null,
          seriesLibrary: null,
          animeLibrary: null,
          liveLibrary: const HomeDiscoveryRailDto(
            slug: 'live-library',
            title: 'TV ao vivo',
            description: 'Canais ao vivo para assistir agora.',
            layout: 'carousel',
            items: <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'live-999',
                title: 'ANIMAL PLANET',
                subtitle: 'TV',
                description: 'Canal ao vivo',
                image: 'https://example.com/animal-planet.png',
                backdrop: null,
                mediaType: 'TV',
                contentId: '999',
                tmdbId: null,
                rating: null,
                year: null,
                genres: <String>[],
                runtime: null,
                provider: null,
                channelNumber: 50,
                progress: null,
                badges: <String>['LIVE'],
                genreIds: <int>[],
              ),
            ],
          ),
          libraries: const <HomeDiscoveryRailDto>[],
          liveNow: null,
          trendingNow: null,
          moviesForToday: null,
          seriesToBinge: null,
          animeSpotlight: null,
          rails: const <HomeDiscoveryRailDto>[],
        ),
        streams: const <LiveStream>[],
        epgByStreamId: {
          '999': [current, next],
        },
      );

      await tester.pumpAndSettle();

      expect(find.text('Pesca Mortal'), findsOneWidget);
      expect(
        find.text(_formatRange(current.startAt, current.endAt)),
        findsOneWidget,
      );
      expect(
        find.text(
          'Depois ${_formatClock(next.startAt)} • Patrulheiros da Natureza',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'home mobile traduz copy técnica do discovery para linguagem de produto',
    (tester) async {
      await _pumpHomeScreen(
        tester,
        discoveryHome: HomeDiscoveryDto(
          generatedAt: '2026-04-04T01:03:13Z',
          heroSlider: HomeDiscoveryRailDto(
            slug: 'hero-slider',
            title: 'Novidades',
            description: 'Slider principal baseado em últimos adicionados.',
            layout: 'hero',
            items: const <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'slider-1',
                title: 'Zona de Caça',
                subtitle: 'VOD',
                description: 'Ação para abrir a sessão.',
                image: 'https://example.com/slider-1.jpg',
                backdrop: 'https://example.com/slider-1-backdrop.jpg',
                mediaType: 'VOD',
                contentId: '91',
                tmdbId: null,
                rating: 7.4,
                year: 2025,
                genres: <String>['Ação'],
                runtime: null,
                provider: null,
                channelNumber: null,
                progress: null,
                badges: <String>['TRENDING'],
                genreIds: <int>[28],
              ),
              HomeDiscoveryItemDto(
                id: 'slider-2',
                title: 'Solo Leveling',
                subtitle: 'Anime',
                description: 'Fantasia para maratonar.',
                image: 'https://example.com/slider-2.jpg',
                backdrop: 'https://example.com/slider-2-backdrop.jpg',
                mediaType: 'Anime',
                contentId: '47',
                tmdbId: null,
                rating: 8.0,
                year: 2024,
                genres: <String>['Animação'],
                runtime: null,
                provider: null,
                channelNumber: null,
                progress: null,
                badges: <String>['ANIME'],
                genreIds: <int>[16],
              ),
            ],
          ),
          hero: HomeDiscoveryHeroDto(
            item: const HomeDiscoveryItemDto(
              id: 'trending-44',
              title: 'Resgate Implacável',
              subtitle: 'VOD',
              description: 'Ação para começar a sessão.',
              image: 'https://example.com/hero.jpg',
              backdrop: 'https://example.com/hero_backdrop.jpg',
              mediaType: 'VOD',
              contentId: '44',
              tmdbId: null,
              rating: 7.8,
              year: 2026,
              genres: <String>['Ação'],
              runtime: null,
              provider: null,
              channelNumber: null,
              progress: null,
              badges: <String>['TRENDING'],
              genreIds: <int>[28],
            ),
            source: 'TRENDING_NOW',
            rationale: 'Prioriza catálogo recente com apoio do TMDB.',
          ),
          highlights: null,
          continueWatching: null,
          hasContinueWatchingField: true,
          moviesLibrary: HomeDiscoveryRailDto(
            slug: 'movies-library',
            title: 'Filmes',
            description:
                'Filmes adicionados recentemente ao catálogo com apoio do TMDB.',
            layout: 'poster',
            items: const <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'movie-1',
                title: 'Resgate Implacável',
                subtitle: 'VOD',
                description: 'Filme de ação.',
                image: 'https://example.com/vod.jpg',
                backdrop: null,
                mediaType: 'VOD',
                contentId: '44',
                tmdbId: null,
                rating: 7.8,
                year: 2026,
                genres: <String>['Ação'],
                runtime: null,
                provider: null,
                channelNumber: null,
                progress: null,
                badges: <String>['TRENDING'],
                genreIds: <int>[28],
              ),
            ],
          ),
          seriesLibrary: HomeDiscoveryRailDto(
            slug: 'series-library',
            title: 'Séries',
            description:
                'Séries recentes organizadas pelo servidor com fallback TMDB.',
            layout: 'poster',
            items: const <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'series-1',
                title: 'Nebula 9',
                subtitle: 'TV Series',
                description: 'Thriller futurista.',
                image: 'https://example.com/series.jpg',
                backdrop: null,
                mediaType: 'Series',
                contentId: '201',
                tmdbId: null,
                rating: null,
                year: 2026,
                genres: <String>['Drama'],
                runtime: null,
                provider: null,
                channelNumber: null,
                progress: null,
                badges: <String>[],
                genreIds: <int>[18],
              ),
            ],
          ),
          animeLibrary: HomeDiscoveryRailDto(
            slug: 'anime-library',
            title: 'Anime',
            description:
                'Animes recentes do catálogo com apoio de tendências TMDB.',
            layout: 'poster',
            items: const <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'anime-1',
                title: 'Solo Leveling',
                subtitle: 'Anime',
                description: 'Aventura fantástica.',
                image: 'https://example.com/anime.jpg',
                backdrop: null,
                mediaType: 'Anime',
                contentId: '47',
                tmdbId: null,
                rating: null,
                year: 2024,
                genres: <String>['Animação'],
                runtime: null,
                provider: null,
                channelNumber: null,
                progress: null,
                badges: <String>[],
                genreIds: <int>[16],
              ),
            ],
          ),
          liveLibrary: HomeDiscoveryRailDto(
            slug: 'live-library',
            title: 'TV ao vivo',
            description: 'Canais ao vivo com contexto EPG em tempo real.',
            layout: 'carousel',
            items: const <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'live-1',
                title: 'Canal Centro',
                subtitle: 'TV',
                description: 'Canal principal.',
                image: 'https://example.com/live.jpg',
                backdrop: null,
                mediaType: 'TV',
                contentId: 'stream-1',
                tmdbId: null,
                rating: null,
                year: null,
                genres: <String>[],
                runtime: null,
                provider: null,
                channelNumber: 12,
                progress: null,
                badges: <String>['LIVE'],
                genreIds: <int>[],
              ),
            ],
          ),
          libraries: const <HomeDiscoveryRailDto>[],
          liveNow: HomeDiscoveryRailDto(
            slug: 'live-now',
            title: 'No ar agora',
            description: 'Canais ao vivo com contexto EPG em tempo real.',
            layout: 'carousel',
            items: const <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'live-1',
                title: 'Canal Centro',
                subtitle: 'TV',
                description: 'Canal principal.',
                image: 'https://example.com/live.jpg',
                backdrop: null,
                mediaType: 'TV',
                contentId: 'stream-1',
                tmdbId: null,
                rating: null,
                year: null,
                genres: <String>[],
                runtime: null,
                provider: null,
                channelNumber: 12,
                progress: null,
                badges: <String>['LIVE'],
                genreIds: <int>[],
              ),
            ],
          ),
          trendingNow: HomeDiscoveryRailDto(
            slug: 'trending-now',
            title: 'TRENDING_NOW',
            description: 'Ranking real de visualizações dos últimos 7 dias.',
            layout: 'carousel',
            items: const <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'vod-1',
                title: 'Resgate Implacável',
                subtitle: 'VOD',
                description: 'Filme de ação.',
                image: 'https://example.com/vod.jpg',
                backdrop: null,
                mediaType: 'VOD',
                contentId: '44',
                tmdbId: null,
                rating: 7.8,
                year: 2026,
                genres: <String>['Ação'],
                runtime: null,
                provider: null,
                channelNumber: null,
                progress: null,
                badges: <String>['TRENDING'],
                genreIds: <int>[28],
              ),
            ],
          ),
          moviesForToday: HomeDiscoveryRailDto(
            slug: 'movies-for-today',
            title: 'Filmes para hoje',
            description:
                'Prioriza VOD recente do catálogo; completa com populares TMDB.',
            layout: 'poster',
            items: const <HomeDiscoveryItemDto>[],
          ),
          seriesToBinge: HomeDiscoveryRailDto(
            slug: 'series-to-binge',
            title: 'Séries para maratonar',
            description:
                'Prioriza séries recentes do catálogo; fallback em trending TV TMDB.',
            layout: 'poster',
            items: const <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'series-1',
                title: 'Nebula 9',
                subtitle: 'TV Series',
                description: 'Thriller futurista.',
                image: 'https://example.com/series.jpg',
                backdrop: null,
                mediaType: 'Series',
                contentId: '201',
                tmdbId: null,
                rating: null,
                year: 2026,
                genres: <String>['Drama'],
                runtime: null,
                provider: null,
                channelNumber: null,
                progress: null,
                badges: <String>[],
                genreIds: <int>[18],
              ),
            ],
          ),
          animeSpotlight: HomeDiscoveryRailDto(
            slug: 'anime-spotlight',
            title: 'Anime Spotlight',
            description:
                'Animes recentes do catálogo com apoio de tendências Animation do TMDB.',
            layout: 'poster',
            items: const <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'anime-1',
                title: 'Solo Leveling',
                subtitle: 'Anime',
                description: 'Aventura fantástica.',
                image: 'https://example.com/anime.jpg',
                backdrop: null,
                mediaType: 'Anime',
                contentId: '47',
                tmdbId: null,
                rating: null,
                year: 2024,
                genres: <String>['Animação'],
                runtime: null,
                provider: null,
                channelNumber: null,
                progress: null,
                badges: <String>[],
                genreIds: <int>[16],
              ),
            ],
          ),
          rails: const <HomeDiscoveryRailDto>[],
        ),
        streams: _sampleStreams(),
      );

      await tester.pumpAndSettle();

      expect(find.text('TRENDING_NOW'), findsNothing);
      expect(find.textContaining('TMDB'), findsNothing);
      expect(find.textContaining('EPG em tempo real'), findsNothing);
      expect(find.text('TV Series'), findsNothing);
      expect(find.text('Acesso rápido'), findsNothing);
      expect(find.text('Destaques'), findsNothing);
      expect(find.text('FILME EM DESTAQUE'), findsNothing);
      expect(find.text('SÉRIE EM DESTAQUE'), findsNothing);
      expect(find.text('ANIME EM DESTAQUE'), findsNothing);
      expect(find.text('NOVIDADE'), findsOneWidget);
      expect(find.text('Zona de Caça'), findsOneWidget);
      expect(find.text('TV ao vivo'), findsWidgets);
      expect(find.text('Filmes'), findsWidgets);
      expect(find.text('Anime'), findsWidgets);
      expect(find.text('Série'), findsWidgets);
    },
  );

  testWidgets(
    'home mobile esconde hero editorial e trilhos vazios em servidor live-only',
    (tester) async {
      await _pumpHomeScreen(
        tester,
        discoveryHome: HomeDiscoveryDto(
          generatedAt: '2026-04-04T02:00:00Z',
          heroSlider: null,
          hero: null,
          highlights: null,
          continueWatching: null,
          hasContinueWatchingField: true,
          moviesLibrary: const HomeDiscoveryRailDto(
            slug: 'movies-library',
            title: 'Filmes',
            description: 'Filmes do catálogo.',
            layout: 'poster',
            items: <HomeDiscoveryItemDto>[],
          ),
          seriesLibrary: const HomeDiscoveryRailDto(
            slug: 'series-library',
            title: 'Séries',
            description: 'Séries do catálogo.',
            layout: 'poster',
            items: <HomeDiscoveryItemDto>[],
          ),
          animeLibrary: const HomeDiscoveryRailDto(
            slug: 'anime-library',
            title: 'Anime',
            description: 'Anime do catálogo.',
            layout: 'poster',
            items: <HomeDiscoveryItemDto>[],
          ),
          liveLibrary: const HomeDiscoveryRailDto(
            slug: 'live-library',
            title: 'TV ao vivo',
            description: 'Canais ao vivo para assistir agora.',
            layout: 'carousel',
            items: <HomeDiscoveryItemDto>[
              HomeDiscoveryItemDto(
                id: 'live-1',
                title: 'Canal Centro',
                subtitle: 'TV',
                description: 'Canal principal.',
                image: 'https://example.com/live.jpg',
                backdrop: null,
                mediaType: 'TV',
                contentId: 'stream-1',
                tmdbId: null,
                rating: null,
                year: null,
                genres: <String>[],
                runtime: null,
                provider: null,
                channelNumber: 12,
                progress: null,
                badges: <String>['LIVE'],
                genreIds: <int>[],
              ),
            ],
          ),
          libraries: const <HomeDiscoveryRailDto>[],
          liveNow: null,
          trendingNow: null,
          moviesForToday: null,
          seriesToBinge: null,
          animeSpotlight: null,
          rails: const <HomeDiscoveryRailDto>[],
        ),
        streams: _sampleStreams(),
      );

      await tester.pumpAndSettle();

      expect(find.text('Canal Centro'), findsOneWidget);
      expect(find.text('Filmes'), findsNothing);
      expect(find.text('Séries'), findsNothing);
      expect(find.text('Anime'), findsNothing);
      expect(
        find.text('Nenhum item disponivel nesta secao agora.'),
        findsNothing,
      );
      expect(find.text('TV ao vivo'), findsWidgets);
    },
  );
}

Future<void> _pumpHomeScreen(
  WidgetTester tester, {
  InterfaceMode interfaceMode = InterfaceMode.mobile,
  List<LiveStream> streams = const <LiveStream>[],
  List<VodStream> vodItems = const <VodStream>[],
  List<SeriesItem> seriesItems = const <SeriesItem>[],
  Map<String, List<LiveEpgEntry>> epgByStreamId =
      const <String, List<LiveEpgEntry>>{},
  HomeDiscoveryDto? discoveryHome,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = interfaceMode == InterfaceMode.tv
      ? const Size(1920, 1080)
      : const Size(1280, 720);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentSessionProvider.overrideWith((ref) => _session),
        liveStreamsProvider.overrideWith((ref, categoryId) async => streams),
        liveShortEpgProvider.overrideWith((ref, streamId) async {
          return epgByStreamId[streamId] ?? const <LiveEpgEntry>[];
        }),
        vodCategoriesProvider.overrideWith(
          (ref) async => const <VodCategory>[],
        ),
        vodStreamsProvider.overrideWith((ref, categoryId) async {
          return vodItems;
        }),
        seriesItemsProvider.overrideWith((ref, categoryId) async {
          return seriesItems;
        }),
        homeDiscoveryProvider.overrideWith((ref, limit) async => discoveryHome),
      ],
      child: InterfaceModeScope(
        mode: interfaceMode,
        child: const MaterialApp(home: HomeScreen()),
      ),
    ),
  );
}

List<LiveStream> _sampleStreams() {
  return const [
    LiveStream(
      id: 'stream-1',
      name: 'Canal Centro',
      hasArchive: true,
      isAdult: false,
      epgChannelId: 'epg-1',
      iconUrl: 'https://example.com/logo.png',
    ),
    LiveStream(
      id: 'stream-2',
      name: 'Canal Sul',
      hasArchive: false,
      isAdult: false,
    ),
  ];
}

String _formatRange(DateTime startAt, DateTime endAt) {
  return '${_formatClock(startAt)} - ${_formatClock(endAt)}';
}

String _formatClock(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
