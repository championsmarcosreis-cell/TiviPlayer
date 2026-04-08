import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/tv/tv_focusable.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../features/auth/presentation/screens/account_screen.dart';
import '../../../features/home/data/models/home_discovery_dto.dart';
import '../../../features/home/presentation/providers/home_discovery_providers.dart';
import '../../../features/kids/presentation/screens/kids_library_screen.dart';
import '../../../features/live/domain/entities/live_epg_entry.dart';
import '../../../features/live/domain/entities/live_stream.dart';
import '../../../features/live/presentation/providers/live_providers.dart';
import '../../../features/live/presentation/screens/live_categories_screen.dart';
import '../../../features/live/presentation/support/live_playback_context.dart';
import '../../../features/player/domain/entities/playback_context.dart';
import '../../../features/player/domain/entities/playback_history_entry.dart';
import '../../../features/player/presentation/controllers/playback_history_controller.dart';
import '../../../features/player/presentation/screens/player_screen.dart';
import '../../../features/player/presentation/support/player_screen_arguments.dart';
import '../../../features/search/presentation/screens/search_screen.dart';
import '../../../features/series/domain/entities/series_item.dart';
import '../../../features/series/presentation/providers/series_providers.dart';
import '../../../features/series/presentation/screens/series_categories_screen.dart';
import '../../../features/series/presentation/screens/series_details_screen.dart';
import '../../../features/series/presentation/screens/series_items_screen.dart';
import '../../../features/vod/domain/entities/vod_stream.dart';
import '../../../features/vod/presentation/providers/vod_providers.dart';
import '../../../features/vod/presentation/screens/vod_categories_screen.dart';
import '../../../features/vod/presentation/screens/vod_details_screen.dart';
import '../../../features/vod/presentation/screens/vod_streams_screen.dart';
import '../../testing/app_test_keys.dart';
import '../layout/device_layout.dart';
import '../support/on_demand_library.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/branded_artwork.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/mobile_primary_dock.dart';
import '../../widgets/tv_stage.dart';

const _kHomeTvFocusColor = Color(0xFFAF7BFF);
const _kHomeTvFocusGlow = Color(0x66AF7BFF);
const _kMobileContinueWatchingMaxItems = 6;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerLayout = DeviceLayout.of(context);
    final session = ref.watch(currentSessionProvider);
    if (session == null) {
      if (headerLayout.isTv) {
        return const TvStageScaffold(
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return const AppScaffold(
        title: 'Inicio',
        subtitle: 'Preparando seu painel de conteudo.',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final livePreview = ref.watch(liveStreamsProvider(null));
    final vodPreview = ref.watch(vodStreamsProvider(null));
    final seriesPreview = ref.watch(seriesItemsProvider(null));
    final homeDiscoveryState = ref.watch(homeDiscoveryProvider(12));
    final playbackHistory = ref.watch(playbackHistoryControllerProvider);

    final mobilePrimaryActions = [
      _HomeQuickAction(
        title: 'Filmes',
        description: 'Biblioteca',
        icon: Icons.movie_creation_outlined,
        interactiveKey: AppTestKeys.homeMoviesCard,
        testId: AppTestKeys.homeMoviesCardId,
        onTap: () => _openOnDemandLibraryDestination(
          context,
          VodStreamsScreen.buildLocation(
            'all',
            library: OnDemandLibraryKind.movies,
          ),
        ),
      ),
      _HomeQuickAction(
        title: 'Séries',
        description: 'Biblioteca',
        icon: Icons.tv_rounded,
        interactiveKey: AppTestKeys.homeSeriesCard,
        testId: AppTestKeys.homeSeriesCardId,
        onTap: () => _openOnDemandLibraryDestination(
          context,
          SeriesItemsScreen.buildLocation(
            'all',
            library: OnDemandLibraryKind.series,
          ),
        ),
      ),
      _HomeQuickAction(
        title: 'Anime',
        description: 'Biblioteca',
        icon: Icons.auto_awesome_rounded,
        badge: 'ANIME',
        onTap: () => _openOnDemandLibraryDestination(
          context,
          SeriesItemsScreen.buildLocation(
            'all',
            library: OnDemandLibraryKind.anime,
          ),
        ),
      ),
      _HomeQuickAction(
        title: 'Kids',
        description: 'Biblioteca',
        icon: Icons.rocket_launch_rounded,
        interactiveKey: AppTestKeys.homeKidsCard,
        testId: AppTestKeys.homeKidsCardId,
        badge: 'KIDS',
        onTap: () => _openOnDemandLibraryDestination(
          context,
          KidsLibraryScreen.routePath,
        ),
      ),
      _HomeQuickAction(
        title: 'TV ao vivo',
        description: 'Canais',
        icon: Icons.live_tv_rounded,
        interactiveKey: AppTestKeys.homeLiveCard,
        testId: AppTestKeys.homeLiveCardId,
        badge: 'LIVE',
        onTap: () =>
            _openPrimaryDestination(context, LiveCategoriesScreen.routePath),
      ),
    ];

    final tvSidebarItems = <_TvNavigationItem>[
      _TvNavigationItem(
        label: 'Home',
        icon: Icons.home_rounded,
        selected: true,
        onTap: () => context.go(HomeScreen.routePath),
      ),
      _TvNavigationItem(
        label: 'Busca',
        icon: Icons.search_rounded,
        onTap: () => context.go(SearchScreen.routePath),
      ),
      _TvNavigationItem(
        label: 'Conta',
        icon: Icons.verified_user_rounded,
        interactiveKey: AppTestKeys.homeAccountAction,
        onTap: () => context.go(AccountScreen.routePath),
      ),
    ];

    final resolvedVod = _asyncDataOrNull(vodPreview);
    final resolvedSeries = _asyncDataOrNull(seriesPreview);
    final resolvedLive = _asyncDataOrNull(livePreview);
    final discoveryHome = _asyncDataOrNull(homeDiscoveryState);
    final rawVodCards = _buildVodCards(resolvedVod, context);
    final rawSeriesCards = _buildSeriesCards(resolvedSeries, context);
    final vodCards = _filterHomeCardsByLibrary(
      rawVodCards,
      OnDemandLibraryKind.movies,
    );
    final seriesCards = _filterHomeCardsByLibrary(
      rawSeriesCards,
      OnDemandLibraryKind.series,
    );
    final liveCards = _buildLiveCards(resolvedLive, context);
    final animeCards = _buildAnimeCards(
      vodCards: rawVodCards,
      seriesCards: rawSeriesCards,
    );
    final hero = _resolveMobileHeroChoice(
      context: context,
      liveCards: liveCards,
      vodCards: vodCards,
      seriesCards: seriesCards,
      animeCards: animeCards,
    );
    final continueItem = _resolveContinueItem(playbackHistory, context);
    final localContinueItems = _resolveContinueItems(
      playbackHistory,
      context,
      limit: _kMobileContinueWatchingMaxItems,
    );
    final discoveryHeroSliderRail = _resolveDiscoveryLibraryRail(
      home: discoveryHome,
      primary: discoveryHome?.heroSlider,
      slug: 'hero-slider',
    );
    final discoveryHighlightsRail = _resolveDiscoveryLibraryRail(
      home: discoveryHome,
      primary: discoveryHome?.highlights,
      slug: 'highlights',
    );
    final discoveryLiveRail = _resolveDiscoveryLibraryRail(
      home: discoveryHome,
      primary: discoveryHome?.liveLibrary,
      slug: 'live-library',
    );
    final discoveryMoviesRail = _resolveDiscoveryLibraryRail(
      home: discoveryHome,
      primary: discoveryHome?.moviesLibrary,
      slug: 'movies-library',
      libraryKind: OnDemandLibraryKind.movies,
    );
    final discoverySeriesRail = _resolveDiscoveryLibraryRail(
      home: discoveryHome,
      primary: discoveryHome?.seriesLibrary,
      slug: 'series-library',
      libraryKind: OnDemandLibraryKind.series,
    );
    final discoveryAnimeRail = _resolveDiscoveryLibraryRail(
      home: discoveryHome,
      primary: discoveryHome?.animeLibrary,
      slug: 'anime-library',
      libraryKind: OnDemandLibraryKind.anime,
    );
    final discoveryKidsRail = _resolveDiscoveryLibraryRail(
      home: discoveryHome,
      primary: null,
      slug: 'kids',
      libraryKind: OnDemandLibraryKind.kids,
    );
    final fallbackLiveRail = _resolveDiscoveryRail(
      home: discoveryHome,
      primary: discoveryHome?.liveNow,
      slug: 'live-now',
    );
    final fallbackMoviesRail = _resolveDiscoveryRail(
      home: discoveryHome,
      primary: discoveryHome?.moviesForToday,
      slug: 'movies-for-today',
    );
    final fallbackSeriesRail = _resolveDiscoveryRail(
      home: discoveryHome,
      primary: discoveryHome?.seriesToBinge,
      slug: 'series-to-binge',
    );
    final fallbackAnimeRail = _resolveDiscoveryRail(
      home: discoveryHome,
      primary: discoveryHome?.animeSpotlight,
      slug: 'anime-spotlight',
    );

    final discoveryHeroSliderChoices = _buildDiscoveryHeroSliderChoices(
      rail: discoveryHeroSliderRail,
      context: context,
      liveStreams: resolvedLive ?? const <LiveStream>[],
    );
    final discoveryHighlightsCards = _buildDiscoveryRailCards(
      rail: discoveryHighlightsRail,
      context: context,
      liveStreams: resolvedLive ?? const <LiveStream>[],
    );
    final discoveryLiveCards = _buildDiscoveryRailCards(
      rail: discoveryLiveRail,
      context: context,
      liveStreams: resolvedLive ?? const <LiveStream>[],
    );
    final discoveryMoviesCards = _buildDiscoveryRailCards(
      rail: discoveryMoviesRail,
      context: context,
      liveStreams: resolvedLive ?? const <LiveStream>[],
    );
    final discoverySeriesCards = _buildDiscoveryRailCards(
      rail: discoverySeriesRail,
      context: context,
      liveStreams: resolvedLive ?? const <LiveStream>[],
    );
    final discoveryAnimeCards = _buildDiscoveryRailCards(
      rail: discoveryAnimeRail,
      context: context,
      liveStreams: resolvedLive ?? const <LiveStream>[],
    );
    final fallbackDiscoveryLiveCards = _buildDiscoveryRailCards(
      rail: fallbackLiveRail,
      context: context,
      liveStreams: resolvedLive ?? const <LiveStream>[],
    );
    final fallbackDiscoveryMoviesCards = _buildDiscoveryRailCards(
      rail: fallbackMoviesRail,
      context: context,
      liveStreams: resolvedLive ?? const <LiveStream>[],
    );
    final fallbackDiscoverySeriesCards = _buildDiscoveryRailCards(
      rail: fallbackSeriesRail,
      context: context,
      liveStreams: resolvedLive ?? const <LiveStream>[],
    );
    final fallbackDiscoveryAnimeCards = _buildDiscoveryRailCards(
      rail: fallbackAnimeRail,
      context: context,
      liveStreams: resolvedLive ?? const <LiveStream>[],
    );
    final useDiscoveryHeroSlider = discoveryHeroSliderChoices.isNotEmpty;
    final useDiscoveryHighlights = discoveryHighlightsCards.isNotEmpty;
    final useDiscoveryLive = discoveryLiveCards.isNotEmpty;
    final useDiscoveryMovies = discoveryMoviesCards.isNotEmpty;
    final useDiscoverySeries = discoverySeriesCards.isNotEmpty;
    final useDiscoveryAnime = discoveryAnimeCards.isNotEmpty;

    final shouldHoldHeroForDiscovery = shouldHoldMobileHeroForDiscovery(
      homeDiscoveryState,
      discoveryHome: discoveryHome,
    );
    final effectiveHero = shouldHoldHeroForDiscovery
        ? _buildPendingDiscoveryHeroChoice()
        : (_resolveMobileHeroChoiceFromDiscovery(
                hero: discoveryHome?.hero,
                context: context,
                liveStreams: resolvedLive ?? const <LiveStream>[],
              ) ??
              hero);
    final effectiveContinueSection = _resolveMobileContinueWatchingSection(
      discoveryRail: discoveryHome?.continueWatching,
      hasDiscoveryField: discoveryHome?.hasContinueWatchingField == true,
      localItems: localContinueItems,
      playbackHistory: playbackHistory,
      context: context,
      liveStreams: resolvedLive ?? const <LiveStream>[],
    );
    final effectiveLiveCards = useDiscoveryLive
        ? discoveryLiveCards
        : fallbackDiscoveryLiveCards.isNotEmpty
        ? fallbackDiscoveryLiveCards
        : liveCards;
    final effectiveMoviesCards = useDiscoveryMovies
        ? discoveryMoviesCards
        : fallbackDiscoveryMoviesCards.isNotEmpty
        ? fallbackDiscoveryMoviesCards
        : vodCards;
    final effectiveSeriesCards = useDiscoverySeries
        ? discoverySeriesCards
        : fallbackDiscoverySeriesCards.isNotEmpty
        ? fallbackDiscoverySeriesCards
        : seriesCards;
    final effectiveAnimeCards = useDiscoveryAnime
        ? discoveryAnimeCards
        : fallbackDiscoveryAnimeCards.isNotEmpty
        ? fallbackDiscoveryAnimeCards
        : animeCards;
    final discoveryAdditionalRails = _buildAdditionalDiscoveryRails(
      home: discoveryHome,
      context: context,
      liveStreams: resolvedLive ?? const <LiveStream>[],
      discoveryState: homeDiscoveryState,
    );
    final effectiveTvHero = _resolveTvHeroChoice(
      context: context,
      heroSliderChoices: discoveryHeroSliderChoices,
      highlightsCards: discoveryHighlightsCards,
      vodCards: effectiveMoviesCards,
      seriesCards: effectiveSeriesCards,
      animeCards: effectiveAnimeCards,
      additionalRails: discoveryAdditionalRails,
      fallbackHero: effectiveHero,
    );
    final effectiveTvContinueItem = _resolveTvContinueItem(
      continueSection: effectiveContinueSection,
      fallback: continueItem,
    );
    final effectiveTvHeroSlider = _resolveTvHeroSliderChoices(
      context: context,
      heroSliderChoices: discoveryHeroSliderChoices,
      highlightsCards: discoveryHighlightsCards,
      vodCards: effectiveMoviesCards,
      seriesCards: effectiveSeriesCards,
      animeCards: effectiveAnimeCards,
      additionalRails: discoveryAdditionalRails,
      fallbackHero: effectiveTvHero,
    );
    final showMobileLiveRail = effectiveLiveCards.isNotEmpty;
    final showMobileMoviesRail = effectiveMoviesCards.isNotEmpty;
    final showMobileSeriesRail = effectiveSeriesCards.isNotEmpty;
    final showMobileAnimeRail = effectiveAnimeCards.isNotEmpty;
    final showMobileKidsRail = _shouldShowKidsLibraryEntry(
      discoveryKidsRail: discoveryKidsRail,
      vodItems: resolvedVod,
      seriesItems: resolvedSeries,
    );
    final showMobileHero =
        shouldHoldHeroForDiscovery ||
        useDiscoveryHeroSlider ||
        effectiveMoviesCards.isNotEmpty ||
        effectiveSeriesCards.isNotEmpty ||
        effectiveAnimeCards.isNotEmpty;
    final effectivePrimaryActions = <_HomeQuickAction>[
      if (showMobileMoviesRail) mobilePrimaryActions[0],
      if (showMobileSeriesRail) mobilePrimaryActions[1],
      if (showMobileAnimeRail) mobilePrimaryActions[2],
      if (showMobileKidsRail) mobilePrimaryActions[3],
      if (showMobileLiveRail) mobilePrimaryActions[4],
    ];
    final effectiveTvPrimaryNavigationItems = _buildTvPrimaryNavigationItems(
      effectivePrimaryActions,
    );
    final effectiveTvHighlightsCards = _filterNonLiveHomeCards(
      discoveryHighlightsCards,
    );

    if (headerLayout.isTv) {
      return WillPopScope(
        onWillPop: () => _handleHomeExitRequest(context),
        child: _TvHomeSurface(
          primaryNavItems: effectiveTvPrimaryNavigationItems,
          utilityNavItems: tvSidebarItems,
          hero: effectiveTvHero,
          heroSlider: effectiveTvHeroSlider,
          continueItem: effectiveTvContinueItem,
          highlightsHeading: _resolveMobileRailTitle(
            slug: discoveryHighlightsRail?.slug,
            rawTitle: discoveryHighlightsRail?.title,
            fallback: 'Destaques',
          ),
          highlightsSubtitle: _resolveMobileRailSubtitle(
            slug: discoveryHighlightsRail?.slug,
            rawDescription: discoveryHighlightsRail?.description,
            fallback: 'Os títulos mais acessados com base no uso real.',
          ),
          highlightsCards: effectiveTvHighlightsCards,
          liveHeading: _resolveMobileRailTitle(
            slug: discoveryLiveRail?.slug ?? fallbackLiveRail?.slug,
            rawTitle: discoveryLiveRail?.title ?? fallbackLiveRail?.title,
            fallback: 'TV ao vivo',
          ),
          liveSubtitle: _resolveMobileRailSubtitle(
            slug: discoveryLiveRail?.slug ?? fallbackLiveRail?.slug,
            rawDescription:
                discoveryLiveRail?.description ?? fallbackLiveRail?.description,
            fallback: 'Canais ao vivo para assistir agora.',
          ),
          liveCards: effectiveLiveCards,
          vodHeading: _resolveMobileRailTitle(
            slug: discoveryMoviesRail?.slug ?? fallbackMoviesRail?.slug,
            rawTitle: discoveryMoviesRail?.title ?? fallbackMoviesRail?.title,
            fallback: 'Filmes',
          ),
          vodSubtitle: _resolveMobileRailSubtitle(
            slug: discoveryMoviesRail?.slug ?? fallbackMoviesRail?.slug,
            rawDescription:
                discoveryMoviesRail?.description ??
                fallbackMoviesRail?.description,
            fallback: 'Filmes para escolher e assistir agora.',
          ),
          vodCards: effectiveMoviesCards,
          seriesHeading: _resolveMobileRailTitle(
            slug: discoverySeriesRail?.slug ?? fallbackSeriesRail?.slug,
            rawTitle: discoverySeriesRail?.title ?? fallbackSeriesRail?.title,
            fallback: 'Séries',
          ),
          seriesSubtitle: _resolveMobileRailSubtitle(
            slug: discoverySeriesRail?.slug ?? fallbackSeriesRail?.slug,
            rawDescription:
                discoverySeriesRail?.description ??
                fallbackSeriesRail?.description,
            fallback: 'Séries para seguir episódio após episódio.',
          ),
          seriesCards: effectiveSeriesCards,
          animeHeading: _resolveMobileRailTitle(
            slug: discoveryAnimeRail?.slug ?? fallbackAnimeRail?.slug,
            rawTitle: discoveryAnimeRail?.title ?? fallbackAnimeRail?.title,
            fallback: 'Anime',
          ),
          animeSubtitle: _resolveMobileRailSubtitle(
            slug: discoveryAnimeRail?.slug ?? fallbackAnimeRail?.slug,
            rawDescription:
                discoveryAnimeRail?.description ??
                fallbackAnimeRail?.description,
            fallback: 'Uma seleção para entrar no universo anime.',
          ),
          animeCards: effectiveAnimeCards,
          liveState: useDiscoveryLive ? homeDiscoveryState : livePreview,
          highlightsState: useDiscoveryHighlights
              ? homeDiscoveryState
              : const AsyncValue.data(null),
          vodState: useDiscoveryMovies ? homeDiscoveryState : vodPreview,
          seriesState: useDiscoverySeries ? homeDiscoveryState : seriesPreview,
          animeState: useDiscoveryAnime
              ? homeDiscoveryState
              : _combineRailStates([vodPreview, seriesPreview]),
          additionalRails: discoveryAdditionalRails,
        ),
      );
    }

    return WillPopScope(
      onWillPop: () => _handleHomeExitRequest(context),
      child: AppScaffold(
        title: '',
        decoratedHeader: false,
        showBrand: false,
        showHeader: false,
        actions: const [],
        mobileBottomBar: const MobilePrimaryDock(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = DeviceLayout.of(context, constraints: constraints);
            final homeBody = _MobileHomeExperience(
              layout: layout,
              showHero: showMobileHero,
              fallbackHero: effectiveHero,
              heroSlider: useDiscoveryHeroSlider
                  ? discoveryHeroSliderChoices
                  : const <_HomeHeroChoice>[],
              primaryActions: effectivePrimaryActions,
              continueSection: effectiveContinueSection,
              liveHeading: _resolveMobileRailTitle(
                slug: discoveryLiveRail?.slug ?? fallbackLiveRail?.slug,
                rawTitle: discoveryLiveRail?.title ?? fallbackLiveRail?.title,
                fallback: 'TV ao vivo',
              ),
              liveSubtitle: _resolveMobileRailSubtitle(
                slug: discoveryLiveRail?.slug ?? fallbackLiveRail?.slug,
                rawDescription:
                    discoveryLiveRail?.description ??
                    fallbackLiveRail?.description,
                fallback: 'Canais ao vivo para assistir agora.',
              ),
              liveCards: effectiveLiveCards,
              highlightsHeading: _resolveMobileRailTitle(
                slug: discoveryHighlightsRail?.slug,
                rawTitle: discoveryHighlightsRail?.title,
                fallback: 'Destaques',
              ),
              highlightsSubtitle: _resolveMobileRailSubtitle(
                slug: discoveryHighlightsRail?.slug,
                rawDescription: discoveryHighlightsRail?.description,
                fallback: 'Uma seleção editorial para começar a sessão.',
              ),
              highlightsCards: discoveryHighlightsCards,
              vodHeading: _resolveMobileRailTitle(
                slug: discoveryMoviesRail?.slug ?? fallbackMoviesRail?.slug,
                rawTitle:
                    discoveryMoviesRail?.title ?? fallbackMoviesRail?.title,
                fallback: 'Filmes',
              ),
              vodSubtitle: _resolveMobileRailSubtitle(
                slug: discoveryMoviesRail?.slug ?? fallbackMoviesRail?.slug,
                rawDescription:
                    discoveryMoviesRail?.description ??
                    fallbackMoviesRail?.description,
                fallback: 'Filmes para escolher e assistir agora.',
              ),
              vodCards: effectiveMoviesCards,
              seriesHeading: _resolveMobileRailTitle(
                slug: discoverySeriesRail?.slug ?? fallbackSeriesRail?.slug,
                rawTitle:
                    discoverySeriesRail?.title ?? fallbackSeriesRail?.title,
                fallback: 'Séries',
              ),
              seriesSubtitle: _resolveMobileRailSubtitle(
                slug: discoverySeriesRail?.slug ?? fallbackSeriesRail?.slug,
                rawDescription:
                    discoverySeriesRail?.description ??
                    fallbackSeriesRail?.description,
                fallback: 'Séries para seguir episódio após episódio.',
              ),
              seriesCards: effectiveSeriesCards,
              animeHeading: _resolveMobileRailTitle(
                slug: discoveryAnimeRail?.slug ?? fallbackAnimeRail?.slug,
                rawTitle: discoveryAnimeRail?.title ?? fallbackAnimeRail?.title,
                fallback: 'Anime',
              ),
              animeSubtitle: _resolveMobileRailSubtitle(
                slug: discoveryAnimeRail?.slug ?? fallbackAnimeRail?.slug,
                rawDescription:
                    discoveryAnimeRail?.description ??
                    fallbackAnimeRail?.description,
                fallback: 'Uma seleção para entrar no universo anime.',
              ),
              animeCards: effectiveAnimeCards,
              liveState: useDiscoveryLive ? homeDiscoveryState : livePreview,
              highlightsState: homeDiscoveryState,
              vodState: useDiscoveryMovies ? homeDiscoveryState : vodPreview,
              seriesState: useDiscoverySeries
                  ? homeDiscoveryState
                  : seriesPreview,
              animeState: useDiscoveryAnime
                  ? homeDiscoveryState
                  : _combineRailStates([vodPreview, seriesPreview]),
              showHighlights: useDiscoveryHighlights,
              additionalRails: discoveryAdditionalRails,
            );

            return Scrollbar(
              thumbVisibility: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
                child: homeBody,
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<bool> _handleHomeExitRequest(BuildContext context) async {
  final route = ModalRoute.of(context);
  if (route?.isCurrent != true) {
    return true;
  }

  final router = GoRouter.of(context);
  if (router.canPop() || Navigator.of(context).canPop()) {
    return true;
  }

  final currentLocation = router.routeInformationProvider.value.uri.path;
  if (currentLocation != HomeScreen.routePath) {
    return true;
  }

  final shouldExit = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Sair do app?'),
        content: const Text('Deseja sair mesmo do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sair'),
          ),
        ],
      );
    },
  );

  if (shouldExit == true) {
    await SystemNavigator.pop();
  }

  return false;
}

class _HomeHeroChoice {
  const _HomeHeroChoice({
    required this.title,
    required this.kicker,
    required this.description,
    required this.imageUrl,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    this.metadata = const <String>[],
    this.isLive = false,
    this.hasBackdropArtwork = false,
    this.backdropImageUrl,
    this.contentId,
    this.seriesId,
  });

  final String title;
  final String kicker;
  final String description;
  final String? imageUrl;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final List<String> metadata;
  final bool isLive;
  final bool hasBackdropArtwork;
  final String? backdropImageUrl;
  final String? contentId;
  final String? seriesId;
}

class _DiscoveryLiveMatch {
  const _DiscoveryLiveMatch({
    required this.streamIndex,
    required this.stream,
    required this.playbackItemId,
  });

  final int streamIndex;
  final LiveStream? stream;
  final String? playbackItemId;
}

T? _asyncDataOrNull<T>(AsyncValue<T> value) {
  return value.when(
    data: (data) => data,
    loading: () => null,
    error: (_, _) => null,
  );
}

void _openPrimaryDestination(BuildContext context, String routePath) {
  final layout = DeviceLayout.of(context);
  if (layout.isTv) {
    context.push(routePath);
    return;
  }
  context.go(routePath);
}

void _openOnDemandLibraryDestination(BuildContext context, String routePath) {
  context.push(routePath);
}

_ContinueWatchingData? _resolveContinueItem(
  List<PlaybackHistoryEntry> history,
  BuildContext context,
) {
  final items = _resolveContinueItems(history, context, limit: 1);
  if (items.isEmpty) {
    return null;
  }
  return items.first;
}

List<_ContinueWatchingData> _resolveContinueItems(
  List<PlaybackHistoryEntry> history,
  BuildContext context, {
  int limit = _kMobileContinueWatchingMaxItems,
}) {
  if (history.isEmpty || limit <= 0) {
    return const [];
  }

  final items = <_ContinueWatchingData>[];
  final seenKeys = <String>{};
  for (final entry in history) {
    final item = _buildContinueItemFromHistoryEntry(entry, context);
    if (item == null) {
      continue;
    }
    if (seenKeys.contains(item.dedupeKey)) {
      continue;
    }
    seenKeys.add(item.dedupeKey);
    items.add(item);
    if (items.length >= limit) {
      break;
    }
  }
  return items;
}

_ContinueWatchingData? _buildContinueItemFromHistoryEntry(
  PlaybackHistoryEntry entry,
  BuildContext context, {
  String? dedupeKeyOverride,
  String? titleOverride,
  String? subtitleOverride,
  String? imageUrlOverride,
  String? posterImageUrlOverride,
}) {
  final safeDurationMs = entry.durationMs <= 0 ? 1 : entry.durationMs;
  final safePositionMs = entry.positionMs.clamp(0, safeDurationMs).toInt();
  final remainingMs = (safeDurationMs - safePositionMs).clamp(
    0,
    safeDurationMs,
  );
  final progress = (safePositionMs / safeDurationMs).clamp(0, 1).toDouble();

  final remaining = Duration(milliseconds: remainingMs);
  final resumeAt = Duration(milliseconds: safePositionMs);
  final typeLabel = switch (entry.contentType) {
    PlaybackContentType.vod => 'Filme',
    PlaybackContentType.seriesEpisode => 'Episódio',
    PlaybackContentType.live => 'Ao vivo',
  };

  return _ContinueWatchingData(
    dedupeKey: dedupeKeyOverride ?? _resolveContinueHistoryDedupeKey(entry),
    title: titleOverride ?? entry.title,
    subtitle: subtitleOverride ?? typeLabel,
    progress: progress,
    remainingLabel: _formatRemaining(remaining),
    imageUrl:
        imageUrlOverride ??
        entry.backdropUrl ??
        posterImageUrlOverride ??
        entry.artworkUrl,
    posterImageUrl: posterImageUrlOverride ?? entry.artworkUrl,
    seriesId: entry.seriesId,
    icon: switch (entry.contentType) {
      PlaybackContentType.vod => Icons.movie_creation_outlined,
      PlaybackContentType.seriesEpisode => Icons.tv_rounded,
      PlaybackContentType.live => Icons.live_tv_rounded,
    },
    removableContentType: entry.contentType,
    removableItemId: entry.itemId,
    onPressed: () => context.push(
      PlayerScreen.routePath,
      extra: PlaybackContext(
        contentType: entry.contentType,
        itemId: entry.itemId,
        title: entry.title,
        containerExtension: entry.containerExtension,
        artworkUrl: entry.artworkUrl,
        backdropUrl: entry.backdropUrl,
        seriesId: entry.seriesId,
        resumePosition: resumeAt,
        capabilities: switch (entry.contentType) {
          PlaybackContentType.live =>
            const PlaybackSessionCapabilities.liveLinear(),
          PlaybackContentType.vod || PlaybackContentType.seriesEpisode =>
            const PlaybackSessionCapabilities.onDemand(),
        },
      ),
    ),
  );
}

_ContinueWatchingSectionData? _resolveMobileContinueWatchingSection({
  required HomeDiscoveryRailDto? discoveryRail,
  required bool hasDiscoveryField,
  required List<_ContinueWatchingData> localItems,
  required List<PlaybackHistoryEntry> playbackHistory,
  required BuildContext context,
  required List<LiveStream> liveStreams,
}) {
  final discoveryItems = hasDiscoveryField
      ? _resolveContinueItemsFromDiscovery(
          rail: discoveryRail,
          playbackHistory: playbackHistory,
          context: context,
          liveStreams: liveStreams,
          limit: _kMobileContinueWatchingMaxItems,
        )
      : const <_ContinueWatchingData>[];
  final effectiveItems = hasDiscoveryField
      ? _mergeContinueItems(
          primary: discoveryItems,
          fallback: localItems,
          limit: _kMobileContinueWatchingMaxItems,
        )
      : localItems;
  if (effectiveItems.isEmpty) {
    return null;
  }

  return _ContinueWatchingSectionData(
    title: _cleanDiscoveryText(discoveryRail?.title) ?? 'Continuar assistindo',
    subtitle:
        _cleanDiscoveryText(discoveryRail?.description) ??
        'Retome filmes e episódios recentes.',
    items: effectiveItems,
  );
}

List<_ContinueWatchingData> _mergeContinueItems({
  required List<_ContinueWatchingData> primary,
  required List<_ContinueWatchingData> fallback,
  required int limit,
}) {
  final merged = <_ContinueWatchingData>[];
  final seenKeys = <String>{};

  for (final item in [...primary, ...fallback]) {
    final dedupeKey = item.dedupeKey.trim();
    if (dedupeKey.isEmpty || seenKeys.contains(dedupeKey)) {
      continue;
    }
    seenKeys.add(dedupeKey);
    merged.add(item);
    if (merged.length >= limit) {
      break;
    }
  }

  return merged;
}

String _resolveContinueHistoryDedupeKey(PlaybackHistoryEntry entry) {
  if (entry.contentType != PlaybackContentType.seriesEpisode) {
    return entry.key;
  }

  final seriesId = entry.seriesId?.trim();
  if (seriesId != null && seriesId.isNotEmpty) {
    return 'series:$seriesId';
  }

  final seriesTitle = _extractSeriesTitleFromPlaybackHistory(entry.title);
  if (seriesTitle.isNotEmpty) {
    return 'series-title:${_normalizeSeriesLegacyTitleBase(seriesTitle)}';
  }

  return entry.key;
}

String _extractSeriesTitleFromPlaybackHistory(String value) {
  final separators = [' • ', ' - ', ': '];
  for (final separator in separators) {
    final index = value.indexOf(separator);
    if (index > 0) {
      return value.substring(0, index).trim();
    }
  }
  return value.trim();
}

String _extractSeriesTitleFromDiscovery(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  var normalized = trimmed.replaceAll(RegExp(r'\s+'), ' ').trim();
  normalized = normalized.replaceAll(
    RegExp(
      r'\s+(s(?:eason)?\s*\d+\s*[-: ]*\s*e(?:p(?:isodio|isódio)?|pisode)?\s*\d+)$',
      caseSensitive: false,
    ),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(
      r'\s+(t(?:emporada)?\s*\d+\s*[-: ]*\s*(?:ep|e|episodio|episódio)\s*\d+)$',
      caseSensitive: false,
    ),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(r'\s+[-–]\s*(?:s|t)\s*\d+\s*[-–]\s*e\s*\d+$', caseSensitive: false),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(r'\s+(?:s|t)\s*\d+\s*[- ]*\s*e\s*\d+$', caseSensitive: false),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(r'\s+(?:ep|e)\s*\d+$', caseSensitive: false),
    '',
  );

  return normalized.trim();
}

String _normalizeSeriesLegacyTitleBase(String value) {
  return _normalizeDiscoveryLiveKey(value);
}

String _formatRemaining(Duration remaining) {
  final totalMinutes = remaining.inMinutes;
  if (totalMinutes <= 0) {
    return '< 1min';
  }
  if (totalMinutes < 60) {
    return '${totalMinutes}min';
  }

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (minutes == 0) {
    return '${hours}h';
  }
  return '${hours}h ${minutes}min';
}

String _formatContinueRemainingText(String remainingLabel) {
  final normalized = remainingLabel.trim();
  if (normalized.isEmpty) {
    return '';
  }

  final lower = normalized.toLowerCase();
  if (lower.contains('restant') || lower.contains('retomar')) {
    return normalized;
  }

  return 'Restam $normalized';
}

class _TvHomeSurface extends StatefulWidget {
  const _TvHomeSurface({
    required this.primaryNavItems,
    required this.utilityNavItems,
    required this.hero,
    required this.heroSlider,
    required this.continueItem,
    required this.highlightsHeading,
    required this.highlightsSubtitle,
    required this.highlightsCards,
    required this.highlightsState,
    required this.liveHeading,
    required this.liveSubtitle,
    required this.liveCards,
    required this.vodHeading,
    required this.vodSubtitle,
    required this.vodCards,
    required this.seriesHeading,
    required this.seriesSubtitle,
    required this.seriesCards,
    required this.animeHeading,
    required this.animeSubtitle,
    required this.animeCards,
    required this.liveState,
    required this.vodState,
    required this.seriesState,
    required this.animeState,
    required this.additionalRails,
  });

  final List<_TvNavigationItem> primaryNavItems;
  final List<_TvNavigationItem> utilityNavItems;
  final _HomeHeroChoice hero;
  final List<_HomeHeroChoice> heroSlider;
  final _ContinueWatchingData? continueItem;
  final String highlightsHeading;
  final String highlightsSubtitle;
  final List<_HomeRailCardData> highlightsCards;
  final AsyncValue<dynamic> highlightsState;
  final String liveHeading;
  final String liveSubtitle;
  final List<_HomeRailCardData> liveCards;
  final String vodHeading;
  final String vodSubtitle;
  final List<_HomeRailCardData> vodCards;
  final String seriesHeading;
  final String seriesSubtitle;
  final List<_HomeRailCardData> seriesCards;
  final String animeHeading;
  final String animeSubtitle;
  final List<_HomeRailCardData> animeCards;
  final AsyncValue<dynamic> liveState;
  final AsyncValue<dynamic> vodState;
  final AsyncValue<dynamic> seriesState;
  final AsyncValue<dynamic> animeState;
  final List<_DiscoveryAdditionalRail> additionalRails;

  @override
  State<_TvHomeSurface> createState() => _TvHomeSurfaceState();
}

class _TvHomeSurfaceState extends State<_TvHomeSurface> {
  late final FocusNode _heroEntryFocusNode = FocusNode(
    debugLabel: 'tv.home.hero.primary',
  );
  late final FocusNode _primaryNavEntryFocusNode = FocusNode(
    debugLabel: 'tv.home.primaryNav.entry',
  );

  @override
  void initState() {
    super.initState();
    _scheduleEntryFocus();
    _scheduleEntryFocus(const Duration(milliseconds: 220));
    _scheduleEntryFocus(const Duration(milliseconds: 650));
  }

  @override
  void dispose() {
    _heroEntryFocusNode.dispose();
    _primaryNavEntryFocusNode.dispose();
    super.dispose();
  }

  void _scheduleEntryFocus([Duration delay = Duration.zero]) {
    Future<void>.delayed(delay, () {
      if (!mounted || _heroEntryFocusNode.hasFocus) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _heroEntryFocusNode.hasFocus) {
          return;
        }
        _heroEntryFocusNode.requestFocus();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TvStageScaffold(
      padding: const EdgeInsets.fromLTRB(16, 10, 2, 18),
      backdrop: const TvStageBackdrop(
        gradientColors: [
          Color(0xFF020305),
          Color(0xFF060A12),
          Color(0xFF020305),
        ],
        topGlowColor: Color(0x2E355E9A),
        bottomGlowColor: Color(0x223A2211),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final resolvedLayout = DeviceLayout.of(
            context,
            constraints: constraints,
          );
          final sidebarWidth = resolvedLayout.isTvCompact ? 72.0 : 80.0;
          final contentGap = resolvedLayout.isTvCompact ? 12.0 : 14.0;
          final contentInset = sidebarWidth + contentGap;

          return Stack(
            children: [
              Positioned.fill(
                child: Scrollbar(
                  thumbVisibility: false,
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: resolvedLayout.isTvCompact ? 4 : 6,
                      bottom: resolvedLayout.pageBottomPadding,
                    ),
                    children: [
                      _TvHomeExperience(
                        layout: resolvedLayout,
                        contentInset: contentInset,
                        hero: widget.hero,
                        heroSlider: widget.heroSlider,
                        heroFocusNode: _heroEntryFocusNode,
                        primaryNavEntryFocusNode: _primaryNavEntryFocusNode,
                        primaryNavItems: widget.primaryNavItems,
                        continueItem: widget.continueItem,
                        highlightsHeading: widget.highlightsHeading,
                        highlightsSubtitle: widget.highlightsSubtitle,
                        highlightsCards: widget.highlightsCards,
                        highlightsState: widget.highlightsState,
                        liveHeading: widget.liveHeading,
                        liveSubtitle: widget.liveSubtitle,
                        liveCards: widget.liveCards,
                        vodHeading: widget.vodHeading,
                        vodSubtitle: widget.vodSubtitle,
                        vodCards: widget.vodCards,
                        seriesHeading: widget.seriesHeading,
                        seriesSubtitle: widget.seriesSubtitle,
                        seriesCards: widget.seriesCards,
                        animeHeading: widget.animeHeading,
                        animeSubtitle: widget.animeSubtitle,
                        animeCards: widget.animeCards,
                        liveState: widget.liveState,
                        vodState: widget.vodState,
                        seriesState: widget.seriesState,
                        animeState: widget.animeState,
                        additionalRails: widget.additionalRails,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                width: sidebarWidth,
                child: _TvHomeSidebar(
                  layout: resolvedLayout,
                  items: widget.utilityNavItems,
                  rightFocusNode: _primaryNavEntryFocusNode,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TvHomeSidebar extends StatelessWidget {
  const _TvHomeSidebar({
    required this.layout,
    required this.items,
    this.rightFocusNode,
  });

  final DeviceLayout layout;
  final List<_TvNavigationItem> items;
  final FocusNode? rightFocusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: BrandLogo(
            variant: BrandLogoVariant.icon,
            width: 34,
            height: 34,
          ),
        ),
        SizedBox(height: layout.isTvCompact ? 26 : 30),
        for (final item in items) ...[
          _TvHomeSidebarItem(
            layout: layout,
            item: item,
            rightFocusNode: rightFocusNode,
          ),
          SizedBox(height: layout.isTvCompact ? 18 : 20),
        ],
      ],
    );
  }
}

class _TvHomeSidebarItem extends StatelessWidget {
  const _TvHomeSidebarItem({
    required this.layout,
    required this.item,
    this.rightFocusNode,
  });

  final DeviceLayout layout;
  final _TvNavigationItem item;
  final FocusNode? rightFocusNode;

  @override
  Widget build(BuildContext context) {
    final bool selected = item.selected;
    return TvFocusable(
      onPressed: item.onTap,
      interactiveKey: item.interactiveKey,
      testId: item.testId,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent ||
            event.logicalKey != LogicalKeyboardKey.arrowRight ||
            rightFocusNode == null) {
          return KeyEventResult.ignored;
        }

        rightFocusNode!.requestFocus();
        return KeyEventResult.handled;
      },
      builder: (context, focused) {
        final isEmphasized = focused || selected;
        final itemExtent = layout.isTvCompact ? 54.0 : 58.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: itemExtent,
          height: itemExtent,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isEmphasized
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: _kHomeTvFocusGlow.withValues(alpha: 0.26),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : const [],
          ),
          child: Icon(
            item.icon,
            size: 23,
            color: isEmphasized
                ? Colors.white
                : Colors.white.withValues(alpha: 0.74),
          ),
        );
      },
    );
  }
}

class _TvHomePrimaryActions extends StatelessWidget {
  const _TvHomePrimaryActions({
    required this.layout,
    required this.items,
    this.entryFocusNode,
    this.downFocusNode,
  });

  final DeviceLayout layout;
  final List<_TvNavigationItem> items;
  final FocusNode? entryFocusNode;
  final FocusNode? downFocusNode;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return TvStagePanel(
      padding: EdgeInsets.zero,
      radius: 0,
      borderColor: Colors.transparent,
      gradientColors: const [Colors.transparent, Colors.transparent],
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Wrap(
          spacing: layout.isTvCompact ? 16 : 18,
          runSpacing: 10,
          children: [
            for (var index = 0; index < items.length; index++)
              FocusTraversalOrder(
                order: NumericFocusOrder(index + 1),
                child: _TvHomePrimaryTile(
                  item: items[index],
                  compact: layout.isTvCompact,
                  focusNode: index == 0 ? entryFocusNode : null,
                  downFocusNode: downFocusNode,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TvHomePrimaryTile extends StatelessWidget {
  const _TvHomePrimaryTile({
    required this.item,
    required this.compact,
    this.focusNode,
    this.downFocusNode,
  });

  final _TvNavigationItem item;
  final bool compact;
  final FocusNode? focusNode;
  final FocusNode? downFocusNode;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      focusNode: focusNode,
      onPressed: item.onTap,
      interactiveKey: item.interactiveKey,
      testId: item.testId,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent ||
            event.logicalKey != LogicalKeyboardKey.arrowDown ||
            downFocusNode == null) {
          return KeyEventResult.ignored;
        }

        downFocusNode!.requestFocus();
        return KeyEventResult.handled;
      },
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: focused
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: focused
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TvHomeExperience extends StatelessWidget {
  const _TvHomeExperience({
    required this.layout,
    required this.contentInset,
    required this.hero,
    required this.heroSlider,
    required this.heroFocusNode,
    required this.primaryNavEntryFocusNode,
    required this.primaryNavItems,
    required this.continueItem,
    required this.highlightsHeading,
    required this.highlightsSubtitle,
    required this.highlightsCards,
    required this.highlightsState,
    required this.liveHeading,
    required this.liveSubtitle,
    required this.liveCards,
    required this.vodHeading,
    required this.vodSubtitle,
    required this.vodCards,
    required this.seriesHeading,
    required this.seriesSubtitle,
    required this.seriesCards,
    required this.animeHeading,
    required this.animeSubtitle,
    required this.animeCards,
    required this.liveState,
    required this.vodState,
    required this.seriesState,
    required this.animeState,
    required this.additionalRails,
  });

  final DeviceLayout layout;
  final double contentInset;
  final _HomeHeroChoice hero;
  final List<_HomeHeroChoice> heroSlider;
  final FocusNode heroFocusNode;
  final FocusNode primaryNavEntryFocusNode;
  final List<_TvNavigationItem> primaryNavItems;
  final _ContinueWatchingData? continueItem;
  final String highlightsHeading;
  final String highlightsSubtitle;
  final List<_HomeRailCardData> highlightsCards;
  final AsyncValue<dynamic> highlightsState;
  final String liveHeading;
  final String liveSubtitle;
  final List<_HomeRailCardData> liveCards;
  final String vodHeading;
  final String vodSubtitle;
  final List<_HomeRailCardData> vodCards;
  final String seriesHeading;
  final String seriesSubtitle;
  final List<_HomeRailCardData> seriesCards;
  final String animeHeading;
  final String animeSubtitle;
  final List<_HomeRailCardData> animeCards;
  final AsyncValue<dynamic> liveState;
  final AsyncValue<dynamic> vodState;
  final AsyncValue<dynamic> seriesState;
  final AsyncValue<dynamic> animeState;
  final List<_DiscoveryAdditionalRail> additionalRails;

  @override
  Widget build(BuildContext context) {
    final hasContinue = continueItem != null;
    final showHighlights = _shouldShowMobileRail(
      cards: highlightsCards,
      state: highlightsState,
    );
    final showLive = _shouldShowMobileRail(cards: liveCards, state: liveState);
    final showVod = _shouldShowMobileRail(cards: vodCards, state: vodState);
    final showSeries = _shouldShowMobileRail(
      cards: seriesCards,
      state: seriesState,
    );
    final showAnime = _shouldShowMobileRail(
      cards: animeCards,
      state: animeState,
    );
    final heroStageAspectRatio = layout.isTvCompact ? 16 / 6.5 : 16 / 6.8;
    final heroRailOverlap = layout.isTvCompact ? 60.0 : 68.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final heroHeight = availableWidth / heroStageAspectRatio;
        final heroSpacerHeight = heroHeight > heroRailOverlap
            ? heroHeight - heroRailOverlap
            : 0.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: double.infinity,
              height: heroHeight,
              child: _TvHeroCarousel(
                layout: layout,
                contentSafeLeftInset: contentInset,
                slides: heroSlider,
                fallbackHero: hero,
                heroFocusNode: heroFocusNode,
                primaryNavEntryFocusNode: primaryNavEntryFocusNode,
                primaryNavItems: primaryNavItems,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: heroSpacerHeight),
                Padding(
                  padding: EdgeInsets.only(left: contentInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasContinue) ...[
                        SizedBox(height: layout.sectionSpacing),
                        _ContinueWatchingCard(
                          layout: layout,
                          item: continueItem,
                          compactTvCard: true,
                          heading: 'Continuar assistindo',
                        ),
                      ],
                      if (showHighlights) ...[
                        SizedBox(height: layout.sectionSpacing + 2),
                        _HomeRailSection(
                          layout: layout,
                          title: highlightsHeading,
                          subtitle: highlightsSubtitle,
                          icon: Icons.auto_awesome_rounded,
                          onViewAll: () => _openPrimaryDestination(
                            context,
                            VodCategoriesScreen.routePath,
                          ),
                          cards: highlightsCards,
                          state: highlightsState,
                          collapseWhenEmptyOnTv: true,
                        ),
                      ],
                      if (showLive) ...[
                        SizedBox(height: layout.sectionSpacing),
                        _HomeRailSection(
                          layout: layout,
                          title: 'Canais ao vivo',
                          subtitle: '',
                          icon: Icons.live_tv_rounded,
                          onViewAll: () => _openPrimaryDestination(
                            context,
                            LiveCategoriesScreen.routePath,
                          ),
                          cards: liveCards,
                          state: liveState,
                          collapseWhenEmptyOnTv: true,
                          compactTvHeader: true,
                          tvCardScale: 0.64,
                        ),
                      ],
                      if (showVod) ...[
                        SizedBox(height: layout.sectionSpacing + 4),
                        _HomeRailSection(
                          layout: layout,
                          title: vodHeading,
                          subtitle: vodSubtitle,
                          icon: Icons.local_movies_rounded,
                          onViewAll: () => _openPrimaryDestination(
                            context,
                            VodCategoriesScreen.routePath,
                          ),
                          cards: vodCards,
                          state: vodState,
                          collapseWhenEmptyOnTv: true,
                        ),
                      ],
                      if (showSeries) ...[
                        SizedBox(height: layout.sectionSpacing + 4),
                        _HomeRailSection(
                          layout: layout,
                          title: seriesHeading,
                          subtitle: seriesSubtitle,
                          icon: Icons.tv_rounded,
                          onViewAll: () => _openPrimaryDestination(
                            context,
                            SeriesCategoriesScreen.routePath,
                          ),
                          cards: seriesCards,
                          state: seriesState,
                          collapseWhenEmptyOnTv: true,
                        ),
                      ],
                      if (showAnime) ...[
                        SizedBox(height: layout.sectionSpacing + 4),
                        _HomeRailSection(
                          layout: layout,
                          title: animeHeading,
                          subtitle: animeSubtitle,
                          icon: Icons.auto_awesome_rounded,
                          onViewAll: () => _openPrimaryDestination(
                            context,
                            SeriesCategoriesScreen.routePath,
                          ),
                          cards: animeCards,
                          state: animeState,
                          collapseWhenEmptyOnTv: true,
                        ),
                      ],
                      for (final rail in additionalRails) ...[
                        SizedBox(height: layout.sectionSpacing + 4),
                        _HomeRailSection(
                          layout: layout,
                          title: rail.title,
                          subtitle: rail.subtitle,
                          icon: rail.icon,
                          onViewAll: rail.onViewAll,
                          cards: rail.cards,
                          state: rail.state,
                          collapseWhenEmptyOnTv: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

List<_HomeRailCardData> _buildAnimeCards({
  required List<_HomeRailCardData> vodCards,
  required List<_HomeRailCardData> seriesCards,
}) {
  final candidates = <_HomeRailCardData>[...seriesCards, ...vodCards];

  return candidates
      .where(
        (card) =>
            card.libraryKind == OnDemandLibraryKind.anime ||
            (card.libraryKind == null &&
                _looksLikeAnime(card.title, card.subtitle)),
      )
      .take(12)
      .map(
        (card) => _HomeRailCardData(
          title: card.title,
          subtitle: card.subtitle,
          imageUrl: card.imageUrl,
          posterImageUrl: card.posterImageUrl,
          backdropImageUrl: card.backdropImageUrl,
          icon: card.icon,
          onPressed: card.onPressed,
          badge: 'ANIME',
          aspectRatio: card.aspectRatio,
          imagePadding: card.imagePadding,
          fit: card.fit,
          liveStreamId: card.liveStreamId,
          supportsLiveEpg: card.supportsLiveEpg,
          noEpgFallbackLabel: card.noEpgFallbackLabel,
          hasReplay: card.hasReplay,
          libraryKind: OnDemandLibraryKind.anime,
          contentId: card.contentId,
          seriesId: card.seriesId,
        ),
      )
      .toList();
}

bool _looksLikeAnime(String title, String subtitle) {
  final haystack = '${title.toLowerCase()} ${subtitle.toLowerCase()}';
  const animeKeywords = <String>[
    'anime',
    'animé',
    'manga',
    'otaku',
    'naruto',
    'one piece',
    'dragon ball',
    'demon slayer',
    'jujutsu',
    'bleach',
    'pokemon',
    'attack on titan',
  ];

  return animeKeywords.any(haystack.contains);
}

AsyncValue<void> _combineRailStates(List<AsyncValue<dynamic>> states) {
  final hasData = states.any(
    (state) => state.when(
      data: (_) => true,
      loading: () => false,
      error: (error, stackTrace) => false,
    ),
  );

  if (states.any((state) => state.isLoading) && !hasData) {
    return const AsyncValue.loading();
  }

  for (final state in states) {
    if (state is AsyncError<dynamic> && !hasData) {
      return AsyncValue.error(state.error, state.stackTrace);
    }
  }

  return const AsyncValue.data(null);
}

_ContinueWatchingData? _resolveTvContinueItem({
  required _ContinueWatchingSectionData? continueSection,
  required _ContinueWatchingData? fallback,
}) {
  final items = continueSection?.items;
  if (items != null && items.isNotEmpty) {
    return items.first;
  }
  return fallback;
}

List<_HomeRailCardData> _filterNonLiveHomeCards(List<_HomeRailCardData> cards) {
  return cards
      .where((card) => card.liveStreamId == null)
      .toList(growable: false);
}

_HomeHeroChoice _buildOnDemandHeroChoiceFromCard({
  required BuildContext context,
  required _HomeRailCardData card,
}) {
  final libraryKind = card.libraryKind;
  final posterArtwork = card.posterImageUrl ?? card.imageUrl;
  final backdropArtwork = card.backdropImageUrl;
  final isAnime =
      libraryKind == OnDemandLibraryKind.anime ||
      (libraryKind == null && _looksLikeAnime(card.title, card.subtitle));
  final isSeries = !isAnime && libraryKind == OnDemandLibraryKind.series;
  final isKids = libraryKind == OnDemandLibraryKind.kids;

  return _HomeHeroChoice(
    title: card.title,
    kicker: 'Novidade',
    description: isKids
        ? 'Uma seleção para abrir a sessão infantil.'
        : isAnime
        ? 'Uma escolha para começar sua sessão de anime.'
        : isSeries
        ? 'Uma série para começar ou retomar agora.'
        : 'Comece por um destaque escolhido para abrir sua sessão.',
    imageUrl: posterArtwork,
    backdropImageUrl: backdropArtwork,
    primaryLabel: isSeries || isAnime || isKids
        ? 'Abrir agora'
        : 'Assistir agora',
    secondaryLabel: isKids
        ? 'Ver kids'
        : isAnime
        ? 'Ver animes'
        : isSeries
        ? 'Ver séries'
        : 'Ver filmes',
    onPrimary: card.onPressed,
    onSecondary: () {
      if (isKids) {
        _openOnDemandLibraryDestination(context, KidsLibraryScreen.routePath);
        return;
      }
      if (isAnime || isSeries) {
        _openPrimaryDestination(context, SeriesCategoriesScreen.routePath);
        return;
      }
      _openPrimaryDestination(context, VodCategoriesScreen.routePath);
    },
    metadata: [
      if (isKids)
        'Kids'
      else if (isAnime)
        'Anime'
      else if (isSeries)
        'Série'
      else
        'Filme',
      'Novidade',
    ],
    hasBackdropArtwork:
        backdropArtwork?.trim().isNotEmpty == true &&
        posterArtwork?.trim().isNotEmpty == true &&
        backdropArtwork!.trim() != posterArtwork!.trim(),
    contentId: card.contentId,
    seriesId: card.seriesId,
  );
}

_HomeHeroChoice _resolveTvHeroChoice({
  required BuildContext context,
  required List<_HomeHeroChoice> heroSliderChoices,
  required List<_HomeRailCardData> highlightsCards,
  required List<_HomeRailCardData> vodCards,
  required List<_HomeRailCardData> seriesCards,
  required List<_HomeRailCardData> animeCards,
  required List<_DiscoveryAdditionalRail> additionalRails,
  required _HomeHeroChoice fallbackHero,
}) {
  final discoveryHeroSlides = heroSliderChoices
      .where((choice) => !choice.isLive)
      .toList(growable: false);
  if (discoveryHeroSlides.isNotEmpty) {
    return discoveryHeroSlides.first;
  }

  final additionalCandidates = additionalRails.expand((rail) => rail.cards);
  final onDemandCandidates = <_HomeRailCardData>[
    ..._filterNonLiveHomeCards(highlightsCards),
    ...vodCards,
    ...seriesCards,
    ...animeCards,
    ..._filterNonLiveHomeCards(additionalCandidates.toList(growable: false)),
  ];

  if (onDemandCandidates.isNotEmpty) {
    return _buildOnDemandHeroChoiceFromCard(
      context: context,
      card: onDemandCandidates.first,
    );
  }

  if (!fallbackHero.isLive) {
    return fallbackHero;
  }

  return _resolveMobileHeroChoice(
    context: context,
    liveCards: const <_HomeRailCardData>[],
    vodCards: vodCards,
    seriesCards: seriesCards,
    animeCards: animeCards,
  );
}

List<_HomeHeroChoice> _resolveTvHeroSliderChoices({
  required BuildContext context,
  required List<_HomeHeroChoice> heroSliderChoices,
  required List<_HomeRailCardData> highlightsCards,
  required List<_HomeRailCardData> vodCards,
  required List<_HomeRailCardData> seriesCards,
  required List<_HomeRailCardData> animeCards,
  required List<_DiscoveryAdditionalRail> additionalRails,
  required _HomeHeroChoice fallbackHero,
}) {
  final discoveryHeroSlides = heroSliderChoices
      .where((choice) => !choice.isLive)
      .toList(growable: false);
  if (discoveryHeroSlides.isNotEmpty) {
    return discoveryHeroSlides;
  }

  final slides = <_HomeHeroChoice>[];
  final seenKeys = <String>{};

  void addChoice(_HomeHeroChoice choice) {
    final key = choice.seriesId?.trim().isNotEmpty == true
        ? 'series:${choice.seriesId!.trim()}'
        : choice.contentId?.trim().isNotEmpty == true
        ? 'content:${choice.contentId!.trim()}'
        : choice.title.trim().toLowerCase();
    if (key.isEmpty || seenKeys.contains(key)) {
      return;
    }
    seenKeys.add(key);
    slides.add(choice);
  }

  if (!fallbackHero.isLive) {
    addChoice(fallbackHero);
  }

  for (final choice in heroSliderChoices) {
    if (!choice.isLive) {
      addChoice(choice);
    }
  }

  final additionalCandidates = additionalRails.expand((rail) => rail.cards);
  final onDemandCandidates = <_HomeRailCardData>[
    ..._filterNonLiveHomeCards(highlightsCards),
    ...vodCards,
    ...seriesCards,
    ...animeCards,
    ..._filterNonLiveHomeCards(additionalCandidates.toList(growable: false)),
  ];

  for (final card in onDemandCandidates) {
    addChoice(_buildOnDemandHeroChoiceFromCard(context: context, card: card));
    if (slides.length >= 6) {
      break;
    }
  }

  if (slides.isEmpty) {
    slides.add(fallbackHero);
  }

  return slides;
}

List<_TvNavigationItem> _buildTvPrimaryNavigationItems(
  List<_HomeQuickAction> actions,
) {
  return actions
      .map(
        (action) => _TvNavigationItem(
          label: action.title,
          subtitle: action.description,
          badge: action.badge,
          icon: action.icon,
          onTap: action.onTap,
          interactiveKey: action.interactiveKey,
          testId: action.testId,
        ),
      )
      .toList(growable: false);
}

bool _shouldShowMobileRail({
  required List<_HomeRailCardData> cards,
  required AsyncValue<dynamic> state,
}) {
  return cards.isNotEmpty || state.hasError;
}

_HomeHeroChoice _resolveMobileHeroChoice({
  required BuildContext context,
  required List<_HomeRailCardData> liveCards,
  required List<_HomeRailCardData> vodCards,
  required List<_HomeRailCardData> seriesCards,
  required List<_HomeRailCardData> animeCards,
}) {
  if (liveCards.isNotEmpty) {
    final liveChoice = liveCards.firstWhere(
      (card) => card.supportsLiveEpg,
      orElse: () => liveCards.first,
    );
    return _HomeHeroChoice(
      title: liveChoice.title,
      kicker: 'Ao vivo agora',
      description:
          'Abra o canal com contexto ao vivo e entre no que está acontecendo.',
      imageUrl: liveChoice.imageUrl,
      primaryLabel: 'Assistir ao vivo',
      secondaryLabel: 'Abrir guia',
      onPrimary: liveChoice.onPressed,
      onSecondary: () =>
          _openPrimaryDestination(context, LiveCategoriesScreen.routePath),
      metadata: const ['LIVE', 'Agora'],
      isLive: true,
    );
  }

  if (vodCards.isNotEmpty) {
    final vodChoice = vodCards.first;
    return _HomeHeroChoice(
      title: vodChoice.title,
      kicker: 'Chegou agora',
      description: 'Comece por um filme escolhido para abrir sua sessão.',
      imageUrl: vodChoice.imageUrl,
      primaryLabel: 'Assistir agora',
      secondaryLabel: 'Ver filmes',
      onPrimary: vodChoice.onPressed,
      onSecondary: () =>
          _openPrimaryDestination(context, VodCategoriesScreen.routePath),
      metadata: const ['Filme', 'Sob demanda'],
    );
  }

  if (animeCards.isNotEmpty) {
    final animeChoice = animeCards.first;
    return _HomeHeroChoice(
      title: animeChoice.title,
      kicker: 'Chegou agora',
      description: 'Uma escolha para começar sua sessão de anime.',
      imageUrl: animeChoice.imageUrl,
      primaryLabel: 'Abrir agora',
      secondaryLabel: 'Ver animes',
      onPrimary: animeChoice.onPressed,
      onSecondary: () =>
          _openPrimaryDestination(context, SeriesCategoriesScreen.routePath),
      metadata: const ['Anime', 'Novidade'],
    );
  }

  if (seriesCards.isNotEmpty) {
    final seriesChoice = seriesCards.first;
    return _HomeHeroChoice(
      title: seriesChoice.title,
      kicker: 'Chegou agora',
      description: 'Uma série para começar ou retomar agora.',
      imageUrl: seriesChoice.imageUrl,
      primaryLabel: 'Abrir agora',
      secondaryLabel: 'Ver séries',
      onPrimary: seriesChoice.onPressed,
      onSecondary: () =>
          _openPrimaryDestination(context, SeriesCategoriesScreen.routePath),
      metadata: const ['Série', 'Novidade'],
    );
  }

  return _HomeHeroChoice(
    title: 'Descubra algo para assistir',
    kicker: 'Sua sessão começa aqui',
    description:
        'Entre no catálogo para encontrar filmes, séries e canais ao vivo.',
    imageUrl: null,
    primaryLabel: 'Abrir filmes',
    secondaryLabel: 'Abrir guia',
    onPrimary: () =>
        _openPrimaryDestination(context, VodCategoriesScreen.routePath),
    onSecondary: () =>
        _openPrimaryDestination(context, LiveCategoriesScreen.routePath),
    metadata: const ['Ao vivo', 'Filmes', 'Séries'],
  );
}

_HomeHeroChoice _buildPendingDiscoveryHeroChoice() {
  return _HomeHeroChoice(
    title: 'Preparando sua seleção',
    kicker: 'Carregando novidades',
    description:
        'Organizando os destaques da sua home para entrar direto no que vale assistir.',
    imageUrl: null,
    primaryLabel: 'Aguarde',
    secondaryLabel: 'Aguarde',
    onPrimary: () {},
    onSecondary: () {},
    metadata: const ['Home', 'Catálogo'],
  );
}

bool shouldHoldMobileHeroForDiscovery(
  AsyncValue<HomeDiscoveryDto?> discoveryState, {
  required HomeDiscoveryDto? discoveryHome,
}) {
  return discoveryHome == null && discoveryState.isLoading;
}

String _resolveMobileRailTitle({
  required String? slug,
  required String? rawTitle,
  required String fallback,
}) {
  final normalizedSlug = slug?.trim().toLowerCase() ?? '';
  switch (normalizedSlug) {
    case 'hero-slider':
      return 'Novidades';
    case 'highlights':
      return 'Destaques';
    case 'live-library':
      return 'TV ao vivo';
    case 'movies-library':
      return 'Filmes';
    case 'series-library':
      return 'Séries';
    case 'anime-library':
      return 'Anime';
    case 'live-now':
      return 'Canais ao vivo';
    case 'trending-now':
      return 'Em destaque';
    case 'movies-for-today':
      return 'Filmes para ver agora';
    case 'series-to-binge':
      return 'Séries para maratonar';
    case 'anime-spotlight':
      return 'Anime';
  }

  final normalizedTitle = _cleanDiscoveryText(rawTitle);
  if (normalizedTitle == null) {
    return fallback;
  }
  if (normalizedTitle.toUpperCase() == normalizedTitle &&
      normalizedTitle.contains('_')) {
    return fallback;
  }
  return normalizedTitle;
}

String _resolveMobileRailSubtitle({
  required String? slug,
  required String? rawDescription,
  required String fallback,
}) {
  final normalizedSlug = slug?.trim().toLowerCase() ?? '';
  switch (normalizedSlug) {
    case 'hero-slider':
      return 'Escolhas para começar a sessão sem perder tempo.';
    case 'highlights':
      return 'Uma seleção editorial para abrir a sessão.';
    case 'live-library':
      return 'Canais ao vivo para assistir agora.';
    case 'movies-library':
      return 'Filmes adicionados ao catálogo para escolher agora.';
    case 'series-library':
      return 'Séries para começar ou retomar no seu ritmo.';
    case 'anime-library':
      return 'Anime para mergulhar em maratonas e novos episódios.';
    case 'live-now':
      return 'Entre ao vivo e escolha o que assistir agora.';
    case 'trending-now':
      return 'Títulos que estão chamando atenção agora.';
    case 'movies-for-today':
      return 'Filmes para escolher e assistir agora.';
    case 'series-to-binge':
      return 'Séries para seguir episódio após episódio.';
    case 'anime-spotlight':
      return 'Uma seleção para entrar no universo anime.';
  }

  final normalizedDescription = _cleanDiscoveryText(rawDescription);
  if (normalizedDescription == null ||
      _containsTechnicalDiscoveryLanguage(normalizedDescription)) {
    return fallback;
  }
  return normalizedDescription;
}

String? _cleanDiscoveryText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  return trimmed
      .replaceAll('TMDB', '')
      .replaceAll('tmdb', '')
      .replaceAll('EPG', '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .replaceAll(RegExp(r'\s+([.,;:])'), r'$1')
      .trim();
}

bool _containsTechnicalDiscoveryLanguage(String value) {
  final normalized = value.toLowerCase();
  return normalized.contains('tmdb') ||
      normalized.contains('epg') ||
      normalized.contains('fallback') ||
      normalized.contains('prioriza') ||
      normalized.contains('ranking real') ||
      normalized.contains('heur') ||
      normalized.contains('source') ||
      normalized.contains('rationale') ||
      normalized.contains('tempo real');
}

String _resolveDiscoveryBadgeLabel({
  required bool isLive,
  required bool isSeries,
  required bool isAnime,
  required List<String> badges,
  String fallback = 'FILME',
}) {
  if (isLive) {
    return 'AO VIVO';
  }
  if (isAnime) {
    return 'ANIME';
  }
  if (isSeries) {
    return 'SÉRIE';
  }

  return fallback;
}

String _resolveDiscoveryItemSubtitle({
  required HomeDiscoveryItemDto item,
  required bool isLive,
  required bool isSeries,
  required bool isAnime,
  required String fallback,
}) {
  final rawSubtitle = _cleanDiscoveryText(item.subtitle);
  if (rawSubtitle != null &&
      !_containsTechnicalDiscoveryLanguage(rawSubtitle)) {
    switch (rawSubtitle.toLowerCase()) {
      case 'tv series':
      case 'series':
      case 'serie':
        return 'Série';
      case 'vod':
        return 'Filme';
      case 'tv':
        return 'Ao vivo';
      case 'anime':
        return 'Anime';
      default:
        return rawSubtitle;
    }
  }

  if (isLive) {
    return 'Canal ao vivo';
  }
  if (isAnime) {
    return 'Anime';
  }
  if (isSeries) {
    return 'Série';
  }
  return fallback;
}

List<String> _resolveDiscoveryHeroMetadata({
  required HomeDiscoveryItemDto item,
  required bool isLive,
  required bool isSeries,
  required bool isAnime,
}) {
  final values = <String>[
    if (isLive)
      'Ao vivo'
    else if (isAnime)
      'Anime'
    else if (isSeries)
      'Série'
    else
      'Filme',
    if (item.year != null) '${item.year}',
  ];

  return values;
}

HomeDiscoveryRailDto? _resolveDiscoveryRail({
  required HomeDiscoveryDto? home,
  required HomeDiscoveryRailDto? primary,
  required String slug,
}) {
  if (primary != null) {
    return primary;
  }
  if (home == null) {
    return null;
  }

  final normalizedSlug = slug.trim().toLowerCase();
  for (final rail in home.rails) {
    if (rail.slug?.trim().toLowerCase() == normalizedSlug) {
      return rail;
    }
  }
  return null;
}

HomeDiscoveryRailDto? _resolveDiscoveryLibraryRail({
  required HomeDiscoveryDto? home,
  required HomeDiscoveryRailDto? primary,
  required String slug,
  OnDemandLibraryKind? libraryKind,
}) {
  if (primary != null) {
    return primary;
  }

  if (libraryKind != null) {
    for (final rail in home?.libraries ?? const <HomeDiscoveryRailDto>[]) {
      if (_matchesDiscoveryRailLibraryKind(rail, libraryKind)) {
        return rail;
      }
    }
    for (final rail in home?.rails ?? const <HomeDiscoveryRailDto>[]) {
      if (_matchesDiscoveryRailLibraryKind(rail, libraryKind)) {
        return rail;
      }
    }

    if (libraryKind == OnDemandLibraryKind.kids) {
      return null;
    }
  }

  final normalizedSlug = slug.trim().toLowerCase();
  for (final rail in home?.libraries ?? const <HomeDiscoveryRailDto>[]) {
    if (rail.slug?.trim().toLowerCase() == normalizedSlug) {
      return rail;
    }
  }

  return _resolveDiscoveryRail(home: home, primary: null, slug: normalizedSlug);
}

List<_HomeRailCardData> _buildDiscoveryRailCards({
  required HomeDiscoveryRailDto? rail,
  required BuildContext context,
  required List<LiveStream> liveStreams,
}) {
  if (rail == null || rail.items.isEmpty) {
    return const <_HomeRailCardData>[];
  }

  return rail.items
      .map(
        (item) => _buildDiscoveryRailCard(
          item: item,
          railLibraryKind: rail.libraryKind,
          railLayout: rail.layout,
          context: context,
          liveStreams: liveStreams,
        ),
      )
      .whereType<_HomeRailCardData>()
      .toList();
}

_HomeRailCardData? _buildDiscoveryRailCard({
  required HomeDiscoveryItemDto item,
  required String? railLibraryKind,
  required String? railLayout,
  required BuildContext context,
  required List<LiveStream> liveStreams,
}) {
  final title = item.title?.trim();
  if (title == null || title.isEmpty) {
    return null;
  }

  final mediaType = item.mediaType?.trim().toLowerCase() ?? '';
  final badgesUpper = item.badges.map((entry) => entry.trim().toUpperCase());
  final hasLiveBadge = badgesUpper.contains('LIVE');
  final libraryKind = _resolveDiscoveryItemLibraryKind(
    item,
    railLibraryKind: railLibraryKind,
  );
  final isLive =
      hasLiveBadge ||
      mediaType == 'tv' ||
      mediaType == 'live' ||
      mediaType.contains('channel');
  final isAnime =
      !isLive &&
      (libraryKind == OnDemandLibraryKind.anime ||
          badgesUpper.contains('ANIME') ||
          mediaType.contains('anime') ||
          _looksLikeAnime(title, item.subtitle ?? item.description ?? ''));
  final isSeries =
      !isLive &&
      (libraryKind == OnDemandLibraryKind.series ||
          libraryKind == OnDemandLibraryKind.anime ||
          mediaType.contains('series') ||
          mediaType == 'tvseries' ||
          mediaType == 'tv_show' ||
          mediaType == 'tv show' ||
          isAnime);
  final prefersLandscape =
      (railLayout?.toLowerCase() ?? '').contains('carousel') || isLive;
  final primaryArtwork = item.preferredArtwork;
  final posterArtwork = BrandedArtwork.normalizeArtworkUrl(item.image);
  final backdropArtwork = BrandedArtwork.normalizeArtworkUrl(item.backdrop);
  final contentId = item.contentId?.trim();
  final seriesNavigationId = resolveDiscoverySeriesNavigationId(item);
  final liveMatch = isLive
      ? _resolveDiscoveryLiveMatch(item: item, liveStreams: liveStreams)
      : null;

  if (isLive) {
    final liveStream = liveMatch?.stream;
    final epgLookupId = liveStream?.id ?? liveMatch?.playbackItemId?.trim();
    final canAttemptEpg =
        liveStream?.epgChannelId?.trim().isNotEmpty == true ||
        epgLookupId?.isNotEmpty == true;
    final noEpgLabel = liveStream?.hasArchive == true
        ? 'Ao vivo com replay'
        : 'Ao vivo agora';

    return _HomeRailCardData(
      title: title,
      subtitle: _resolveDiscoveryItemSubtitle(
        item: item,
        isLive: true,
        isSeries: false,
        isAnime: false,
        fallback: noEpgLabel,
      ),
      imageUrl: primaryArtwork,
      posterImageUrl: posterArtwork ?? primaryArtwork,
      backdropImageUrl: backdropArtwork ?? primaryArtwork,
      icon: Icons.live_tv_rounded,
      onPressed: () {
        final playerArguments = _buildDiscoveryLivePlayerArguments(
          item: item,
          liveMatch: liveMatch,
          liveStreams: liveStreams,
        );
        if (playerArguments != null) {
          context.push(PlayerScreen.routePath, extra: playerArguments);
          return;
        }
        _openPrimaryDestination(context, LiveCategoriesScreen.routePath);
      },
      badge: _resolveDiscoveryBadgeLabel(
        isLive: true,
        isSeries: false,
        isAnime: false,
        badges: item.badges,
      ),
      aspectRatio: 16 / 9,
      imagePadding: const EdgeInsets.all(18),
      fit: BoxFit.contain,
      liveStreamId: epgLookupId,
      supportsLiveEpg: canAttemptEpg,
      noEpgFallbackLabel: noEpgLabel,
      hasReplay: liveStream?.hasArchive == true,
      libraryKind: null,
      contentId: contentId,
    );
  }

  if (isSeries) {
    return _HomeRailCardData(
      title: title,
      subtitle: _resolveDiscoveryItemSubtitle(
        item: item,
        isLive: false,
        isSeries: true,
        isAnime: isAnime,
        fallback: isAnime ? 'Anime' : 'Série para maratonar',
      ),
      imageUrl: primaryArtwork,
      posterImageUrl: posterArtwork ?? primaryArtwork,
      backdropImageUrl: backdropArtwork,
      icon: Icons.tv_rounded,
      onPressed: () {
        if (seriesNavigationId != null && seriesNavigationId.isNotEmpty) {
          context.push(SeriesDetailsScreen.buildLocation(seriesNavigationId));
          return;
        }
        _openPrimaryDestination(context, SeriesCategoriesScreen.routePath);
      },
      badge: _resolveDiscoveryBadgeLabel(
        isLive: false,
        isSeries: true,
        isAnime: isAnime,
        badges: item.badges,
        fallback: 'SÉRIE',
      ),
      aspectRatio: prefersLandscape ? 16 / 9 : 2 / 3,
      libraryKind: isAnime
          ? OnDemandLibraryKind.anime
          : OnDemandLibraryKind.series,
      contentId: contentId,
      seriesId: seriesNavigationId,
    );
  }

  final fallbackSubtitle = _resolveDiscoveryItemSubtitle(
    item: item,
    isLive: false,
    isSeries: false,
    isAnime: false,
    fallback: item.rating != null
        ? 'Nota ${item.rating!.toStringAsFixed(1)}'
        : (item.year != null ? '${item.year}' : 'Filme'),
  );
  final normalizedBadge = _resolveDiscoveryBadgeLabel(
    isLive: false,
    isSeries: false,
    isAnime: false,
    badges: item.badges,
    fallback: 'FILME',
  );

  return _HomeRailCardData(
    title: title,
    subtitle: fallbackSubtitle,
    imageUrl: primaryArtwork,
    posterImageUrl: posterArtwork ?? primaryArtwork,
    backdropImageUrl: backdropArtwork,
    icon: Icons.movie_creation_outlined,
    onPressed: () {
      if (contentId != null && contentId.isNotEmpty) {
        context.push(VodDetailsScreen.buildLocation(contentId));
        return;
      }
      _openPrimaryDestination(context, VodCategoriesScreen.routePath);
    },
    badge: normalizedBadge,
    aspectRatio: prefersLandscape ? 16 / 9 : 2 / 3,
    libraryKind: libraryKind ?? OnDemandLibraryKind.movies,
    contentId: contentId,
  );
}

List<_HomeHeroChoice> _buildDiscoveryHeroSliderChoices({
  required HomeDiscoveryRailDto? rail,
  required BuildContext context,
  required List<LiveStream> liveStreams,
}) {
  if (rail == null || rail.items.isEmpty) {
    return const <_HomeHeroChoice>[];
  }

  return rail.items
      .map(
        (item) => _buildHeroChoiceFromDiscoveryItem(
          item: item,
          context: context,
          liveStreams: liveStreams,
          semanticKicker: _resolveHeroSliderSemanticKicker(rail),
          railLibraryKind: rail.libraryKind,
        ),
      )
      .whereType<_HomeHeroChoice>()
      .toList(growable: false);
}

String _resolveHeroSliderSemanticKicker(HomeDiscoveryRailDto rail) {
  final slug = rail.slug?.trim().toLowerCase() ?? '';
  if (slug == 'hero-slider') {
    return 'Novidade';
  }

  final title = _cleanDiscoveryText(rail.title)?.toLowerCase() ?? '';
  if (title.contains('novidade') || title.contains('recente')) {
    return 'Novidade';
  }
  return 'Chegou agora';
}

_HomeHeroChoice? _buildHeroChoiceFromDiscoveryItem({
  required HomeDiscoveryItemDto? item,
  required BuildContext context,
  required List<LiveStream> liveStreams,
  String? semanticKicker,
  String? railLibraryKind,
}) {
  if (item == null || item.title?.trim().isEmpty != false) {
    return null;
  }

  final mediaType = item.mediaType?.trim().toLowerCase() ?? '';
  final libraryKind = _resolveDiscoveryItemLibraryKind(
    item,
    railLibraryKind: railLibraryKind,
  );
  final isLive =
      mediaType == 'tv' ||
      mediaType == 'live' ||
      mediaType.contains('channel') ||
      item.badges.any((badge) => badge.toUpperCase() == 'LIVE');
  final isAnime =
      !isLive &&
      (libraryKind == OnDemandLibraryKind.anime ||
          mediaType.contains('anime') ||
          _looksLikeAnime(
            item.title ?? '',
            item.subtitle ?? item.description ?? '',
          ));
  final isSeries =
      !isLive &&
      (libraryKind == OnDemandLibraryKind.series ||
          libraryKind == OnDemandLibraryKind.anime ||
          mediaType.contains('series') ||
          mediaType == 'tvseries' ||
          mediaType == 'tv_show' ||
          mediaType == 'tv show' ||
          isAnime);
  final contentId = item.contentId?.trim();
  final seriesNavigationId = resolveDiscoverySeriesNavigationId(item);
  final liveMatch = isLive
      ? _resolveDiscoveryLiveMatch(item: item, liveStreams: liveStreams)
      : null;

  void onPrimary() {
    if (isLive) {
      final playerArguments = _buildDiscoveryLivePlayerArguments(
        item: item,
        liveMatch: liveMatch,
        liveStreams: liveStreams,
      );
      if (playerArguments != null) {
        context.push(PlayerScreen.routePath, extra: playerArguments);
        return;
      }
      _openPrimaryDestination(context, LiveCategoriesScreen.routePath);
      return;
    }
    if (isSeries) {
      if (seriesNavigationId != null && seriesNavigationId.isNotEmpty) {
        context.push(SeriesDetailsScreen.buildLocation(seriesNavigationId));
        return;
      }
      _openPrimaryDestination(context, SeriesCategoriesScreen.routePath);
      return;
    }
    if (contentId != null && contentId.isNotEmpty) {
      context.push(VodDetailsScreen.buildLocation(contentId));
      return;
    }
    _openPrimaryDestination(context, VodCategoriesScreen.routePath);
  }

  void onSecondary() {
    if (isLive) {
      _openPrimaryDestination(context, LiveCategoriesScreen.routePath);
      return;
    }
    if (isSeries) {
      _openPrimaryDestination(context, SeriesCategoriesScreen.routePath);
      return;
    }
    _openPrimaryDestination(context, VodCategoriesScreen.routePath);
  }

  final cleanedDescription = _cleanDiscoveryText(item.description);
  final heroPosterImage = item.image?.trim().isNotEmpty == true
      ? item.image
      : item.backdrop;
  final heroBackdropImage = item.backdrop?.trim().isNotEmpty == true
      ? item.backdrop
      : item.image;
  final hasDistinctBackdrop =
      item.backdrop?.trim().isNotEmpty == true &&
      item.image?.trim().isNotEmpty == true &&
      item.backdrop!.trim() != item.image!.trim();

  return _HomeHeroChoice(
    title: item.title!.trim(),
    kicker:
        semanticKicker ??
        (isLive
            ? 'Ao vivo agora'
            : isAnime || isSeries
            ? 'Chegou agora'
            : 'Chegou agora'),
    description: cleanedDescription?.isNotEmpty == true
        ? cleanedDescription!
        : isLive
        ? 'Entre direto em um canal ao vivo.'
        : isAnime
        ? 'Uma escolha para começar sua sessão de anime.'
        : isSeries
        ? 'Uma série para puxar a próxima maratona.'
        : 'Uma escolha para começar sua sessão.',
    imageUrl: heroPosterImage,
    backdropImageUrl: heroBackdropImage,
    primaryLabel: isLive
        ? 'Assistir ao vivo'
        : isSeries
        ? 'Abrir agora'
        : 'Assistir agora',
    secondaryLabel: isLive
        ? 'Ver canais'
        : isSeries
        ? 'Ver séries'
        : 'Ver filmes',
    onPrimary: onPrimary,
    onSecondary: onSecondary,
    metadata: _resolveDiscoveryHeroMetadata(
      item: item,
      isLive: isLive,
      isSeries: isSeries,
      isAnime: isAnime,
    ),
    isLive: isLive,
    hasBackdropArtwork: hasDistinctBackdrop,
    contentId: item.contentId?.trim(),
    seriesId: item.seriesId?.trim(),
  );
}

_HomeHeroChoice? _resolveMobileHeroChoiceFromDiscovery({
  required HomeDiscoveryHeroDto? hero,
  required BuildContext context,
  required List<LiveStream> liveStreams,
}) {
  return _buildHeroChoiceFromDiscoveryItem(
    item: hero?.item,
    context: context,
    liveStreams: liveStreams,
  );
}

String? resolveDiscoveryLivePlaybackItemId(
  HomeDiscoveryItemDto item,
  List<LiveStream> liveStreams,
) {
  return _resolveDiscoveryLiveMatch(
    item: item,
    liveStreams: liveStreams,
  )?.playbackItemId;
}

_DiscoveryLiveMatch? _resolveDiscoveryLiveMatch({
  required HomeDiscoveryItemDto item,
  required List<LiveStream> liveStreams,
}) {
  final candidateIds = <String>[];
  void addCandidate(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || candidateIds.contains(trimmed)) {
      return;
    }
    candidateIds.add(trimmed);
  }

  addCandidate(item.streamId);
  if (item.id?.trim().startsWith('live-') == true) {
    addCandidate(item.id!.trim().replaceFirst('live-', ''));
  }
  addCandidate(item.contentId);
  addCandidate(item.id);

  for (final candidateId in candidateIds) {
    final streamIndex = liveStreams.indexWhere(
      (stream) => stream.id == candidateId,
    );
    if (streamIndex >= 0) {
      return _DiscoveryLiveMatch(
        streamIndex: streamIndex,
        stream: liveStreams[streamIndex],
        playbackItemId: liveStreams[streamIndex].id,
      );
    }
  }

  final normalizedTitle = _normalizeDiscoveryLiveKey(item.title);
  if (normalizedTitle.isNotEmpty) {
    final streamIndex = liveStreams.indexWhere(
      (stream) => _normalizeDiscoveryLiveKey(stream.name) == normalizedTitle,
    );
    if (streamIndex >= 0) {
      return _DiscoveryLiveMatch(
        streamIndex: streamIndex,
        stream: liveStreams[streamIndex],
        playbackItemId: liveStreams[streamIndex].id,
      );
    }
  }

  final fallbackPlaybackId = candidateIds.firstWhere(
    (value) => !value.startsWith('live-'),
    orElse: () => '',
  );
  if (fallbackPlaybackId.isNotEmpty) {
    return _DiscoveryLiveMatch(
      streamIndex: -1,
      stream: null,
      playbackItemId: fallbackPlaybackId,
    );
  }

  return null;
}

PlayerScreenArguments? _buildDiscoveryLivePlayerArguments({
  required HomeDiscoveryItemDto item,
  required _DiscoveryLiveMatch? liveMatch,
  required List<LiveStream> liveStreams,
}) {
  if (liveMatch?.streamIndex != null && liveMatch!.streamIndex >= 0) {
    return buildLivePlaybackContext(liveStreams, liveMatch.streamIndex);
  }

  final playbackItemId = liveMatch?.playbackItemId?.trim();
  if (playbackItemId == null || playbackItemId.isEmpty) {
    return null;
  }

  final matchedStream = liveMatch?.stream;
  return PlayerScreenArguments.standalone(
    PlaybackContext(
      contentType: PlaybackContentType.live,
      itemId: playbackItemId,
      title: item.title?.trim().isNotEmpty == true
          ? item.title!.trim()
          : 'Canal ao vivo',
      containerExtension: matchedStream?.containerExtension,
      artworkUrl: matchedStream?.iconUrl ?? item.preferredArtwork,
      capabilities: matchedStream?.hasArchive == true
          ? const PlaybackSessionCapabilities.liveReplayAvailable()
          : const PlaybackSessionCapabilities.liveLinear(),
    ),
  );
}

String _normalizeDiscoveryLiveKey(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) {
    return '';
  }

  return normalized
      .replaceAll('&', ' e ')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<_ContinueWatchingData> _resolveContinueItemsFromDiscovery({
  required HomeDiscoveryRailDto? rail,
  required List<PlaybackHistoryEntry> playbackHistory,
  required BuildContext context,
  required List<LiveStream> liveStreams,
  int limit = _kMobileContinueWatchingMaxItems,
}) {
  if (rail == null || rail.items.isEmpty || limit <= 0) {
    return const [];
  }

  final items = <_ContinueWatchingData>[];
  for (final item in rail.items) {
    final continueItem = _resolveContinueItemFromDiscovery(
      item: item,
      playbackHistory: playbackHistory,
      context: context,
      liveStreams: liveStreams,
    );
    if (continueItem == null) {
      continue;
    }
    items.add(continueItem);
    if (items.length >= limit) {
      break;
    }
  }
  return items;
}

_ContinueWatchingData? _resolveContinueItemFromDiscovery({
  required HomeDiscoveryItemDto? item,
  required List<PlaybackHistoryEntry> playbackHistory,
  required BuildContext context,
  required List<LiveStream> liveStreams,
}) {
  if (item == null || item.title?.trim().isEmpty != false) {
    return null;
  }

  final mediaType = item.mediaType?.trim().toLowerCase() ?? '';
  final libraryKind = _resolveDiscoveryItemLibraryKind(item);
  final isLive =
      mediaType == 'tv' ||
      mediaType == 'live' ||
      mediaType.contains('channel') ||
      item.badges.any((badge) => badge.toUpperCase() == 'LIVE');
  final isSeries =
      !isLive &&
      (libraryKind == OnDemandLibraryKind.series ||
          libraryKind == OnDemandLibraryKind.anime ||
          mediaType.contains('series') ||
          mediaType == 'tvseries' ||
          mediaType == 'tv_show' ||
          mediaType == 'tv show' ||
          mediaType.contains('anime'));
  final contentId = item.contentId?.trim();
  final seriesNavigationId = resolveDiscoverySeriesNavigationId(item);
  final progress = (item.progress ?? 0).clamp(0.0, 1.0);
  final remainingPercent = ((1 - progress) * 100).clamp(0, 100).round();
  final liveMatch = isLive
      ? _resolveDiscoveryLiveMatch(item: item, liveStreams: liveStreams)
      : null;
  final matchedHistoryEntry = _matchHistoryEntryForDiscoveryContinueItem(
    item: item,
    playbackHistory: playbackHistory,
    isLive: isLive,
    isSeries: isSeries,
  );
  if (matchedHistoryEntry != null) {
    return _buildContinueItemFromHistoryEntry(
      matchedHistoryEntry,
      context,
      dedupeKeyOverride: _resolveContinueHistoryDedupeKey(matchedHistoryEntry),
      titleOverride: item.title?.trim(),
      subtitleOverride: _resolveDiscoveryItemSubtitle(
        item: item,
        isLive: isLive,
        isSeries: isSeries,
        isAnime: libraryKind == OnDemandLibraryKind.anime,
        fallback: isLive
            ? 'Ao vivo'
            : isSeries
            ? 'Série'
            : 'Filme',
      ),
      imageUrlOverride: _resolveDiscoveryContinueArtwork(item),
      posterImageUrlOverride:
          BrandedArtwork.normalizeArtworkUrl(matchedHistoryEntry.artworkUrl) ??
          _resolveDiscoveryContinuePosterArtwork(item),
    );
  }

  return _ContinueWatchingData(
    dedupeKey: _resolveDiscoveryContinueDedupeKey(
      item: item,
      isLive: isLive,
      isSeries: isSeries,
    ),
    title: item.title!.trim(),
    subtitle: _resolveDiscoveryItemSubtitle(
      item: item,
      isLive: isLive,
      isSeries: isSeries,
      isAnime: libraryKind == OnDemandLibraryKind.anime,
      fallback: isLive
          ? 'Ao vivo'
          : isSeries
          ? 'Série'
          : 'Filme',
    ),
    progress: progress,
    remainingLabel: progress > 0
        ? '$remainingPercent% restante'
        : 'Retomar agora',
    imageUrl: _resolveDiscoveryContinueArtwork(item),
    posterImageUrl: _resolveDiscoveryContinuePosterArtwork(item),
    seriesId: isSeries ? seriesNavigationId : null,
    icon: isLive
        ? Icons.live_tv_rounded
        : isSeries
        ? Icons.tv_rounded
        : Icons.movie_creation_outlined,
    onPressed: () {
      if (isLive) {
        final playerArguments = _buildDiscoveryLivePlayerArguments(
          item: item,
          liveMatch: liveMatch,
          liveStreams: liveStreams,
        );
        if (playerArguments != null) {
          context.push(PlayerScreen.routePath, extra: playerArguments);
          return;
        }
        _openPrimaryDestination(context, LiveCategoriesScreen.routePath);
        return;
      }
      if (isSeries) {
        if (seriesNavigationId != null && seriesNavigationId.isNotEmpty) {
          context.push(SeriesDetailsScreen.buildLocation(seriesNavigationId));
          return;
        }
        _openPrimaryDestination(context, SeriesCategoriesScreen.routePath);
        return;
      }
      if (contentId != null && contentId.isNotEmpty) {
        context.push(VodDetailsScreen.buildLocation(contentId));
        return;
      }
      _openPrimaryDestination(context, VodCategoriesScreen.routePath);
    },
  );
}

String? _resolveDiscoveryContinueArtwork(HomeDiscoveryItemDto item) {
  return BrandedArtwork.normalizeArtworkUrl(item.backdrop) ??
      _resolveDiscoveryContinuePosterArtwork(item);
}

String? _resolveDiscoveryContinuePosterArtwork(HomeDiscoveryItemDto item) {
  return BrandedArtwork.normalizeArtworkUrl(item.image) ??
      BrandedArtwork.normalizeArtworkUrl(item.preferredArtwork);
}

PlaybackHistoryEntry? _matchHistoryEntryForDiscoveryContinueItem({
  required HomeDiscoveryItemDto item,
  required List<PlaybackHistoryEntry> playbackHistory,
  required bool isLive,
  required bool isSeries,
}) {
  final candidateIds = <String>{
    if (item.seriesId?.trim().isNotEmpty == true) item.seriesId!.trim(),
    if (item.contentId?.trim().isNotEmpty == true) item.contentId!.trim(),
    if (item.streamId?.trim().isNotEmpty == true) item.streamId!.trim(),
    if (item.id?.trim().isNotEmpty == true) item.id!.trim(),
  };
  if (candidateIds.isEmpty) {
    return null;
  }

  final expectedType = isLive
      ? PlaybackContentType.live
      : isSeries
      ? PlaybackContentType.seriesEpisode
      : PlaybackContentType.vod;

  if (isSeries) {
    final normalizedDiscoveryTitle = _normalizeSeriesLegacyTitleBase(
      _extractSeriesTitleFromDiscovery(item.title ?? ''),
    );
    for (final entry in playbackHistory) {
      if (entry.contentType != PlaybackContentType.seriesEpisode) {
        continue;
      }

      final entrySeriesId = entry.seriesId?.trim();
      if (entrySeriesId != null && candidateIds.contains(entrySeriesId)) {
        return entry;
      }

      if (normalizedDiscoveryTitle.isNotEmpty &&
          _normalizeSeriesLegacyTitleBase(
                _extractSeriesTitleFromPlaybackHistory(entry.title),
              ) ==
              normalizedDiscoveryTitle) {
        return entry;
      }
    }
    return null;
  }

  for (final entry in playbackHistory) {
    if (entry.contentType == expectedType &&
        candidateIds.contains(entry.itemId.trim())) {
      return entry;
    }
  }
  return null;
}

String _resolveDiscoveryContinueDedupeKey({
  required HomeDiscoveryItemDto item,
  required bool isLive,
  required bool isSeries,
}) {
  final typeKey = isLive
      ? 'live'
      : isSeries
      ? 'series'
      : 'vod';
  final preferredId = isSeries && item.seriesId?.trim().isNotEmpty == true
      ? item.seriesId!.trim()
      : item.contentId?.trim().isNotEmpty == true
      ? item.contentId!.trim()
      : item.streamId?.trim().isNotEmpty == true
      ? item.streamId!.trim()
      : item.id?.trim().isNotEmpty == true
      ? item.id!.trim()
      : isSeries
      ? _normalizeSeriesLegacyTitleBase(
          _extractSeriesTitleFromDiscovery(item.title ?? ''),
        )
      : (item.title?.trim().toLowerCase() ?? 'continue-watching');
  return '$typeKey:$preferredId';
}

String? resolveDiscoverySeriesNavigationId(HomeDiscoveryItemDto item) {
  final seriesId = item.seriesId?.trim();
  if (seriesId != null && seriesId.isNotEmpty) {
    return seriesId;
  }

  final contentId = item.contentId?.trim();
  if (contentId != null && contentId.isNotEmpty) {
    return contentId;
  }

  return null;
}

List<_DiscoveryAdditionalRail> _buildAdditionalDiscoveryRails({
  required HomeDiscoveryDto? home,
  required BuildContext context,
  required List<LiveStream> liveStreams,
  required AsyncValue<dynamic> discoveryState,
}) {
  if (home == null || home.rails.isEmpty) {
    return const <_DiscoveryAdditionalRail>[];
  }

  const reservedSlugs = <String>{
    'hero-slider',
    'highlights',
    'live-library',
    'movies-library',
    'series-library',
    'anime-library',
    'live-now',
    'trending-now',
    'movies-for-today',
    'series-to-binge',
    'anime-spotlight',
  };

  final result = <_DiscoveryAdditionalRail>[];
  for (final rail in home.rails) {
    final slug = rail.slug?.trim().toLowerCase() ?? '';
    if (reservedSlugs.contains(slug)) {
      continue;
    }

    final cards = _buildDiscoveryRailCards(
      rail: rail,
      context: context,
      liveStreams: liveStreams,
    );
    if (cards.isEmpty) {
      continue;
    }

    result.add(
      _DiscoveryAdditionalRail(
        title: _resolveMobileRailTitle(
          slug: rail.slug,
          rawTitle: rail.title,
          fallback: 'Coleção em destaque',
        ),
        subtitle: _resolveMobileRailSubtitle(
          slug: rail.slug,
          rawDescription: rail.description,
          fallback: 'Uma seleção para descobrir algo novo.',
        ),
        icon: _resolveDiscoveryRailIcon(slug),
        cards: cards,
        state: discoveryState,
        onViewAll: () {
          final railLibraryKind = _resolveDiscoveryRailLibraryKind(rail);
          if (railLibraryKind == OnDemandLibraryKind.kids) {
            _openOnDemandLibraryDestination(
              context,
              KidsLibraryScreen.routePath,
            );
            return;
          }
          if (railLibraryKind == OnDemandLibraryKind.anime) {
            _openOnDemandLibraryDestination(
              context,
              SeriesItemsScreen.buildLocation(
                'all',
                library: OnDemandLibraryKind.anime,
              ),
            );
            return;
          }
          if (railLibraryKind == OnDemandLibraryKind.series) {
            _openOnDemandLibraryDestination(
              context,
              SeriesItemsScreen.buildLocation(
                'all',
                library: OnDemandLibraryKind.series,
              ),
            );
            return;
          }
          if (railLibraryKind == OnDemandLibraryKind.movies) {
            _openOnDemandLibraryDestination(
              context,
              VodStreamsScreen.buildLocation(
                'all',
                library: OnDemandLibraryKind.movies,
              ),
            );
            return;
          }
          if (slug.contains('live')) {
            _openPrimaryDestination(context, LiveCategoriesScreen.routePath);
            return;
          }
          if (slug.contains('series') || slug.contains('anime')) {
            _openPrimaryDestination(context, SeriesCategoriesScreen.routePath);
            return;
          }
          _openPrimaryDestination(context, VodCategoriesScreen.routePath);
        },
      ),
    );
  }

  return result;
}

IconData _resolveDiscoveryRailIcon(String slug) {
  if (slug.contains('live')) {
    return Icons.live_tv_rounded;
  }
  if (slug.contains('series')) {
    return Icons.tv_rounded;
  }
  if (slug.contains('anime')) {
    return Icons.auto_awesome_rounded;
  }
  if (slug.contains('movie')) {
    return Icons.local_movies_rounded;
  }
  if (slug.contains('trend')) {
    return Icons.local_fire_department_rounded;
  }
  return Icons.explore_rounded;
}

class _DiscoveryAdditionalRail {
  const _DiscoveryAdditionalRail({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.cards,
    required this.state,
    required this.onViewAll,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<_HomeRailCardData> cards;
  final AsyncValue<dynamic> state;
  final VoidCallback onViewAll;
}

class _MobileHomeExperience extends StatelessWidget {
  const _MobileHomeExperience({
    required this.layout,
    required this.showHero,
    required this.fallbackHero,
    required this.heroSlider,
    required this.primaryActions,
    required this.continueSection,
    required this.liveHeading,
    required this.liveSubtitle,
    required this.liveCards,
    required this.highlightsHeading,
    required this.highlightsSubtitle,
    required this.highlightsCards,
    required this.vodHeading,
    required this.vodSubtitle,
    required this.vodCards,
    required this.seriesHeading,
    required this.seriesSubtitle,
    required this.seriesCards,
    required this.animeHeading,
    required this.animeSubtitle,
    required this.animeCards,
    required this.liveState,
    required this.highlightsState,
    required this.vodState,
    required this.seriesState,
    required this.animeState,
    required this.showHighlights,
    required this.additionalRails,
  });

  final DeviceLayout layout;
  final bool showHero;
  final _HomeHeroChoice fallbackHero;
  final List<_HomeHeroChoice> heroSlider;
  final List<_HomeQuickAction> primaryActions;
  final _ContinueWatchingSectionData? continueSection;
  final String liveHeading;
  final String liveSubtitle;
  final List<_HomeRailCardData> liveCards;
  final String highlightsHeading;
  final String highlightsSubtitle;
  final List<_HomeRailCardData> highlightsCards;
  final String vodHeading;
  final String vodSubtitle;
  final List<_HomeRailCardData> vodCards;
  final String seriesHeading;
  final String seriesSubtitle;
  final List<_HomeRailCardData> seriesCards;
  final String animeHeading;
  final String animeSubtitle;
  final List<_HomeRailCardData> animeCards;
  final AsyncValue<dynamic> liveState;
  final AsyncValue<dynamic> highlightsState;
  final AsyncValue<dynamic> vodState;
  final AsyncValue<dynamic> seriesState;
  final AsyncValue<dynamic> animeState;
  final bool showHighlights;
  final List<_DiscoveryAdditionalRail> additionalRails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MobileTopBar(),
        SizedBox(height: layout.sectionSpacing + 2),
        if (showHero) ...[
          _MobileHeroSlider(
            layout: layout,
            slides: heroSlider,
            fallbackHero: fallbackHero,
          ),
          SizedBox(height: layout.sectionSpacing + 4),
        ],
        if (primaryActions.isNotEmpty)
          _MobileTopActionStrip(layout: layout, actions: primaryActions),
        if (continueSection != null) ...[
          SizedBox(height: layout.sectionSpacing + 4),
          _ContinueWatchingRailSection(
            layout: layout,
            section: continueSection!,
          ),
        ],
        if (showHighlights) ...[
          SizedBox(height: layout.sectionSpacing + 10),
          _HomeRailSection(
            layout: layout,
            title: highlightsHeading,
            subtitle: highlightsSubtitle,
            icon: Icons.auto_awesome_rounded,
            onViewAll: () =>
                _openPrimaryDestination(context, VodCategoriesScreen.routePath),
            cards: highlightsCards,
            state: highlightsState,
          ),
        ],
        if (_shouldShowMobileRail(cards: liveCards, state: liveState)) ...[
          SizedBox(
            height: continueSection != null
                ? layout.sectionSpacing + 12
                : layout.sectionSpacing + 10,
          ),
          _HomeRailSection(
            layout: layout,
            title: liveHeading,
            subtitle: liveSubtitle,
            icon: Icons.live_tv_rounded,
            onViewAll: () => _openPrimaryDestination(
              context,
              LiveCategoriesScreen.routePath,
            ),
            cards: liveCards,
            state: liveState,
          ),
        ],
        if (_shouldShowMobileRail(cards: vodCards, state: vodState)) ...[
          SizedBox(height: layout.sectionSpacing + 10),
          _HomeRailSection(
            layout: layout,
            title: vodHeading,
            subtitle: vodSubtitle,
            icon: Icons.local_movies_rounded,
            onViewAll: () =>
                _openPrimaryDestination(context, VodCategoriesScreen.routePath),
            cards: vodCards,
            state: vodState,
          ),
        ],
        if (_shouldShowMobileRail(cards: seriesCards, state: seriesState)) ...[
          SizedBox(height: layout.sectionSpacing + 10),
          _HomeRailSection(
            layout: layout,
            title: seriesHeading,
            subtitle: seriesSubtitle,
            icon: Icons.tv_rounded,
            onViewAll: () => _openPrimaryDestination(
              context,
              SeriesCategoriesScreen.routePath,
            ),
            cards: seriesCards,
            state: seriesState,
          ),
        ],
        if (_shouldShowMobileRail(cards: animeCards, state: animeState)) ...[
          SizedBox(height: layout.sectionSpacing + 10),
          _HomeRailSection(
            layout: layout,
            title: animeHeading,
            subtitle: animeSubtitle,
            icon: Icons.auto_awesome_rounded,
            onViewAll: () => _openPrimaryDestination(
              context,
              SeriesCategoriesScreen.routePath,
            ),
            cards: animeCards,
            state: animeState,
          ),
        ],
        for (final rail in additionalRails) ...[
          SizedBox(height: layout.sectionSpacing + 10),
          _HomeRailSection(
            layout: layout,
            title: rail.title,
            subtitle: rail.subtitle,
            icon: rail.icon,
            onViewAll: rail.onViewAll,
            cards: rail.cards,
            state: rail.state,
          ),
        ],
      ],
    );
  }
}

class _TvNavigationItem {
  const _TvNavigationItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.selected = false,
    this.interactiveKey,
    this.testId,
  });

  final String label;
  final String? subtitle;
  final String? badge;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final Key? interactiveKey;
  final String? testId;
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [BrandWordmark(height: 24, compact: true, showTagline: false)],
    );
  }
}

class _MobileTopActionStrip extends StatelessWidget {
  const _MobileTopActionStrip({required this.layout, required this.actions});

  final DeviceLayout layout;
  final List<_HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final action in actions) _MobileTopActionChip(action: action),
        ],
      ),
    );
  }
}

class _MobileTopActionChip extends StatelessWidget {
  const _MobileTopActionChip({required this.action});

  final _HomeQuickAction action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLive = action.badge == 'LIVE';
    final isAnime = action.badge == 'ANIME';
    final isKids = action.badge == 'KIDS';
    final accent = isLive
        ? const Color(0xFFEF5457)
        : isAnime
        ? const Color(0xFFFFB347)
        : isKids
        ? const Color(0xFF52C7B8)
        : colorScheme.primary;

    return TvFocusable(
      interactiveKey: action.interactiveKey,
      testId: action.testId,
      onPressed: action.onTap,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: focused
                ? accent.withValues(alpha: 0.18)
                : colorScheme.surface.withValues(alpha: 0.56),
            border: Border.all(
              color: focused
                  ? accent.withValues(alpha: 0.92)
                  : colorScheme.outline.withValues(alpha: 0.28),
              width: focused ? 1.8 : 1,
            ),
          ),
          child: Text(
            action.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }
}

class _TvHeroCarousel extends StatefulWidget {
  const _TvHeroCarousel({
    required this.layout,
    required this.contentSafeLeftInset,
    required this.slides,
    required this.fallbackHero,
    required this.heroFocusNode,
    required this.primaryNavEntryFocusNode,
    required this.primaryNavItems,
  });

  final DeviceLayout layout;
  final double contentSafeLeftInset;
  final List<_HomeHeroChoice> slides;
  final _HomeHeroChoice fallbackHero;
  final FocusNode heroFocusNode;
  final FocusNode primaryNavEntryFocusNode;
  final List<_TvNavigationItem> primaryNavItems;

  @override
  State<_TvHeroCarousel> createState() => _TvHeroCarouselState();
}

class _TvHeroCarouselState extends State<_TvHeroCarousel> {
  static const _autoAdvanceInterval = Duration(seconds: 15);
  static const _manualCooldown = Duration(seconds: 15);

  Timer? _autoAdvanceTimer;
  int _currentIndex = 0;
  DateTime? _lastManualInteractionAt;
  bool _heroFocused = false;

  List<_HomeHeroChoice> get _effectiveSlides {
    final nonLiveSlides = widget.slides
        .where((choice) => !choice.isLive)
        .toList(growable: false);
    if (nonLiveSlides.isNotEmpty) {
      return nonLiveSlides;
    }
    return <_HomeHeroChoice>[widget.fallbackHero];
  }

  @override
  void initState() {
    super.initState();
    _scheduleAutoAdvance();
  }

  @override
  void didUpdateWidget(covariant _TvHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slides.length != widget.slides.length) {
      if (_currentIndex >= _effectiveSlides.length) {
        _currentIndex = 0;
      }
    }
    _scheduleAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (_effectiveSlides.length <= 1 || _heroFocused) {
      return;
    }

    var delay = _autoAdvanceInterval;
    final lastInteractionAt = _lastManualInteractionAt;
    if (lastInteractionAt != null) {
      final elapsed = DateTime.now().difference(lastInteractionAt);
      if (elapsed < _manualCooldown) {
        delay = _manualCooldown - elapsed;
      }
    }

    _autoAdvanceTimer = Timer(delay, _advanceToNextSlide);
  }

  void _registerManualInteraction() {
    _lastManualInteractionAt = DateTime.now();
  }

  void _handleHeroFocusChanged(bool focused) {
    if (_heroFocused == focused) {
      return;
    }

    setState(() {
      _heroFocused = focused;
    });
    _scheduleAutoAdvance();
  }

  void _setCurrentIndex(int index, {bool manual = false}) {
    if (!mounted || index == _currentIndex || _effectiveSlides.isEmpty) {
      return;
    }

    if (manual) {
      _registerManualInteraction();
    }

    setState(() {
      _currentIndex = index;
    });
    _scheduleAutoAdvance();
  }

  void _advanceToNextSlide() {
    if (!mounted || _effectiveSlides.length <= 1 || _heroFocused) {
      return;
    }

    final lastInteractionAt = _lastManualInteractionAt;
    if (lastInteractionAt != null &&
        DateTime.now().difference(lastInteractionAt) < _manualCooldown) {
      _scheduleAutoAdvance();
      return;
    }

    _setCurrentIndex((_currentIndex + 1) % _effectiveSlides.length);
  }

  @override
  Widget build(BuildContext context) {
    final slides = _effectiveSlides;
    final stageAspectRatio = widget.layout.isTvCompact ? 16 / 6.5 : 16 / 6.8;
    final activeSlide = slides[_currentIndex];

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: stageAspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _MobileHeroSlideCard(
                layout: widget.layout,
                hero: activeSlide,
                focusNode: widget.heroFocusNode,
                tvContentSafeLeftInset: widget.contentSafeLeftInset,
                onFocusChanged: _handleHeroFocusChanged,
                onKeyEvent: (node, event) {
                  if (event is! KeyDownEvent) {
                    return KeyEventResult.ignored;
                  }

                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    widget.primaryNavEntryFocusNode.requestFocus();
                    return KeyEventResult.handled;
                  }

                  return KeyEventResult.ignored;
                },
              ),
            ],
          ),
        ),
        IgnorePointer(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: widget.layout.isTvCompact ? 96 : 108,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x0004070E),
                    Color(0x5C04070E),
                    Color(0xD804070E),
                  ],
                  stops: [0.0, 0.56, 1.0],
                ),
              ),
            ),
          ),
        ),
        if (widget.primaryNavItems.isNotEmpty)
          Positioned(
            top: 14,
            left: widget.contentSafeLeftInset + 20,
            right: 20,
            child: _TvHomePrimaryActions(
              layout: widget.layout,
              items: widget.primaryNavItems,
              entryFocusNode: widget.primaryNavEntryFocusNode,
              downFocusNode: widget.heroFocusNode,
            ),
          ),
        if (slides.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Row(
              key: const ValueKey<String>('home.tv.hero.pagination'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < slides.length; index++) ...[
                  if (index > 0) const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == _currentIndex ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: index == _currentIndex
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _MobileHeroSlider extends StatefulWidget {
  const _MobileHeroSlider({
    required this.layout,
    required this.slides,
    required this.fallbackHero,
  });

  final DeviceLayout layout;
  final List<_HomeHeroChoice> slides;
  final _HomeHeroChoice fallbackHero;

  @override
  State<_MobileHeroSlider> createState() => _MobileHeroSliderState();
}

class _MobileHeroSliderState extends State<_MobileHeroSlider> {
  static const _autoAdvanceInterval = Duration(seconds: 15);
  static const _manualCooldown = Duration(seconds: 15);

  late final PageController _controller;
  Timer? _autoAdvanceTimer;
  int _currentIndex = 0;
  DateTime? _lastManualInteractionAt;
  bool _autoAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _restartAutoAdvance();
  }

  @override
  void didUpdateWidget(covariant _MobileHeroSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slides.length != widget.slides.length) {
      if (_currentIndex >= widget.slides.length) {
        _currentIndex = 0;
        if (_controller.hasClients) {
          _controller.jumpToPage(0);
        }
      }
      _restartAutoAdvance();
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (widget.slides.length <= 1) {
      return;
    }
    _autoAdvanceTimer = Timer.periodic(_autoAdvanceInterval, (_) {
      _advanceToNextSlide();
    });
  }

  void _registerManualInteraction() {
    _lastManualInteractionAt = DateTime.now();
  }

  Future<void> _advanceToNextSlide() async {
    if (!mounted || !_controller.hasClients || widget.slides.length <= 1) {
      return;
    }

    final lastInteractionAt = _lastManualInteractionAt;
    if (lastInteractionAt != null &&
        DateTime.now().difference(lastInteractionAt) < _manualCooldown) {
      return;
    }

    final nextIndex = (_currentIndex + 1) % widget.slides.length;
    _autoAnimating = true;
    try {
      await _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _autoAnimating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) {
      return _CinematicHeroCard(
        layout: widget.layout,
        hero: widget.fallbackHero,
        tvMode: false,
      );
    }

    final slides = widget.slides;
    final availableWidth =
        MediaQuery.sizeOf(context).width -
        (widget.layout.pageHorizontalPadding * 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: availableWidth / (16 / 7.6),
          child: NotificationListener<ScrollStartNotification>(
            onNotification: (notification) {
              if (notification.dragDetails != null) {
                _registerManualInteraction();
              }
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                if (_currentIndex != index) {
                  setState(() {
                    _currentIndex = index;
                  });
                }
                if (!_autoAnimating) {
                  _registerManualInteraction();
                }
              },
              itemCount: slides.length,
              itemBuilder: (context, index) {
                return _MobileHeroSlideCard(
                  layout: widget.layout,
                  hero: slides[index],
                );
              },
            ),
          ),
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < slides.length; index++) ...[
                if (index > 0) const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: index == _currentIndex ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: index == _currentIndex
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.24),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _MobileHeroSlideCard extends StatelessWidget {
  const _MobileHeroSlideCard({
    required this.layout,
    required this.hero,
    this.focusNode,
    this.autofocus = false,
    this.tvContentSafeLeftInset = 0,
    this.onFocusChanged,
    this.onKeyEvent,
  });

  final DeviceLayout layout;
  final _HomeHeroChoice hero;
  final FocusNode? focusNode;
  final bool autofocus;
  final double tvContentSafeLeftInset;
  final ValueChanged<bool>? onFocusChanged;
  final FocusOnKeyEventCallback? onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backdropImageUrl = BrandedArtwork.normalizeArtworkUrl(
      hero.backdropImageUrl,
    );
    final posterImageUrl = BrandedArtwork.normalizeArtworkUrl(hero.imageUrl);
    final metadata = hero.metadata.take(layout.isTv ? 3 : 2).join('  •  ');

    return TvFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      onFocusChanged: onFocusChanged,
      onKeyEvent: onKeyEvent,
      onPressed: hero.onPrimary,
      builder: (context, focused) {
        if (layout.isTv) {
          return _buildTvCard(
            context: context,
            focused: focused,
            colorScheme: colorScheme,
            backdropImageUrl: backdropImageUrl,
            posterImageUrl: posterImageUrl,
            metadata: metadata,
            tvContentSafeLeftInset: tvContentSafeLeftInset,
          );
        }

        return _buildMobileCard(
          context: context,
          colorScheme: colorScheme,
          imageUrl: backdropImageUrl ?? posterImageUrl,
          metadata: metadata,
        );
      },
    );
  }

  Widget _buildTvCard({
    required BuildContext context,
    required bool focused,
    required ColorScheme colorScheme,
    required String? backdropImageUrl,
    required String? posterImageUrl,
    required String metadata,
    required double tvContentSafeLeftInset,
  }) {
    final showcaseImageUrl = backdropImageUrl ?? posterImageUrl;
    final ambientImageUrl = showcaseImageUrl;
    final borderRadius = BorderRadius.circular(26);
    final titleSize = layout.isTvCompact ? 34.0 : 38.0;
    final metadataFontSize = layout.isTvCompact ? 13.0 : 13.5;
    final kickerFontSize = layout.isTvCompact ? 11.0 : 11.5;
    final contentWidth = layout.isTvCompact ? 420.0 : 500.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: focused ? 0.32 : 0.2),
            blurRadius: focused ? 30 : 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final safeLeftPadding = tvContentSafeLeftInset + 38;
          final safeTopPadding = layout.isTvCompact ? 92.0 : 104.0;
          final safeRightPadding =
              constraints.maxWidth * (layout.isTvCompact ? 0.46 : 0.48);
          final showcaseWidth =
              constraints.maxWidth * (layout.isTvCompact ? 0.42 : 0.44);
          final showcaseTopInset = layout.isTvCompact ? 72.0 : 82.0;
          final showcaseBottomInset = layout.isTvCompact ? 116.0 : 132.0;

          return Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: borderRadius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF03060B),
                            Color(0xFF07111D),
                            Color(0xFF03060B),
                          ],
                        ),
                      ),
                    ),
                    if (ambientImageUrl != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ImageFiltered(
                                imageFilter: ui.ImageFilter.blur(
                                  sigmaX: 34,
                                  sigmaY: 34,
                                ),
                                child: Opacity(
                                  opacity: 0.28,
                                  child: Transform.scale(
                                    scale: 1.1,
                                    child: Image.network(
                                      ambientImageUrl,
                                      fit: BoxFit.cover,
                                      alignment: const Alignment(0.34, -0.08),
                                      filterQuality: FilterQuality.low,
                                      headers: const {
                                        'Accept-Encoding': 'identity',
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (showcaseImageUrl != null)
                      Positioned(
                        right: layout.isTvCompact ? 26 : 30,
                        top: showcaseTopInset,
                        bottom: showcaseBottomInset,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: Colors.black.withValues(alpha: 0.26),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.26),
                                  blurRadius: 24,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: SizedBox(
                                width: showcaseWidth,
                                child: Image.network(
                                  showcaseImageUrl,
                                  key: const ValueKey<String>(
                                    'home.tv.hero.artwork',
                                  ),
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  filterQuality: FilterQuality.medium,
                                  headers: const {
                                    'Accept-Encoding': 'identity',
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFB04070E),
                            Color(0xF0060A12),
                            Color(0xA0070B13),
                            Color(0x12070B13),
                          ],
                          stops: [0.0, 0.38, 0.68, 1.0],
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0x66000000), Color(0x00000000)],
                          stops: [0.0, 0.38],
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x26000000), Color(0x00000000)],
                          stops: [0.0, 0.22],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        safeLeftPadding,
                        safeTopPadding,
                        safeRightPadding,
                        layout.isTvCompact ? 20 : 22,
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: const Color(0xEAF0701E),
                                ),
                                child: Text(
                                  hero.kicker.toUpperCase(),
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Colors.black,
                                        letterSpacing: 0.6,
                                        fontWeight: FontWeight.w800,
                                        fontSize: kickerFontSize,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                hero.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      fontSize: titleSize,
                                      height: 0.98,
                                      fontWeight: FontWeight.w700,
                                      shadows: const [
                                        Shadow(
                                          color: Color(0xCC000000),
                                          blurRadius: 18,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                              ),
                              if (metadata.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  metadata,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.86,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        fontSize: metadataFontSize,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              _TvHeroActionPill(
                                label: hero.primaryLabel,
                                focused: focused,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileCard({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String? imageUrl,
    required String metadata,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.42),
          width: 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFF030507)),
          ),
          if (imageUrl != null)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
              headers: const {'Accept-Encoding': 'identity'},
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F1A2E), Color(0xFF172842)],
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xF004080F),
                  Color(0xCC050A13),
                  Color(0x78050A13),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xCCFF6A1A),
                  ),
                  child: Text(
                    hero.kicker.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.black,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  hero.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    shadows: const [
                      Shadow(
                        color: Color(0xB8000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (metadata.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    metadata,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.84),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hero.primaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CinematicHeroCard extends StatelessWidget {
  const _CinematicHeroCard({
    required this.layout,
    required this.hero,
    required this.tvMode,
  });

  final DeviceLayout layout;
  final _HomeHeroChoice hero;
  final bool tvMode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = BrandedArtwork.normalizeArtworkUrl(hero.imageUrl);
    Widget buildCard(BuildContext context, {required bool focused}) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(layout.isTv ? 24 : 24),
          border: tvMode && focused
              ? Border.all(color: _kHomeTvFocusColor, width: 2.2)
              : null,
          boxShadow: tvMode && focused
              ? [
                  BoxShadow(
                    color: _kHomeTvFocusGlow.withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: AspectRatio(
          aspectRatio: tvMode ? 16 / 4.4 : 16 / 9.8,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactMobile = !tvMode && constraints.maxHeight < 260;
              final veryCompactMobile = !tvMode && constraints.maxHeight < 236;
              final metadata = hero.metadata
                  .take(
                    tvMode
                        ? 3
                        : (veryCompactMobile ? 0 : (compactMobile ? 1 : 2)),
                  )
                  .toList();
              final titleFontSize = tvMode
                  ? (layout.isTvCompact ? 30.0 : 34.0)
                  : (compactMobile ? 27.0 : 32.0);
              final metadataFontSize = tvMode
                  ? 12.5
                  : (compactMobile ? 13.0 : 14.0);
              final descriptionFontSize = tvMode
                  ? 12.0
                  : (compactMobile ? 11.8 : 12.6);
              final actionStyle = tvMode
                  ? ButtonStyle(
                      minimumSize: const WidgetStatePropertyAll(Size(0, 50)),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.focused)) {
                          return const Color(0xFFFFF3E7);
                        }
                        if (states.contains(WidgetState.pressed)) {
                          return colorScheme.primary.withValues(alpha: 0.86);
                        }
                        return colorScheme.primary;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.focused)) {
                          return const Color(0xFF161005);
                        }
                        return colorScheme.onPrimary;
                      }),
                      side: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.focused)) {
                          return BorderSide(
                            color: colorScheme.secondary,
                            width: 2.6,
                          );
                        }
                        return BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.9),
                        );
                      }),
                      elevation: WidgetStateProperty.resolveWith((states) {
                        return states.contains(WidgetState.focused) ? 9 : 1;
                      }),
                    )
                  : FilledButton.styleFrom(
                      minimumSize: Size(0, veryCompactMobile ? 42 : 46),
                      padding: EdgeInsets.symmetric(
                        horizontal: veryCompactMobile ? 14 : 16,
                        vertical: veryCompactMobile ? 10 : 11,
                      ),
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: veryCompactMobile ? 13.5 : 14.5,
                          ),
                    );
              final showDescription = tvMode || !compactMobile;

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      headers: const {'Accept-Encoding': 'identity'},
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    )
                  else
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0F1A2E), Color(0xFF172842)],
                        ),
                      ),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xEE04080F),
                          Color(0xC2050A13),
                          Color(0x6A050A13),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: tvMode
                        ? const EdgeInsets.fromLTRB(18, 54, 18, 18)
                        : EdgeInsets.all(compactMobile ? 14 : 16),
                    child: Column(
                      mainAxisAlignment: tvMode
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compactMobile ? 10 : 12,
                            vertical: compactMobile ? 5 : 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(0xCCFF6A1A),
                          ),
                          child: Text(
                            hero.kicker.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.black,
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w800,
                                  fontSize: tvMode ? 11.5 : null,
                                ),
                          ),
                        ),
                        SizedBox(height: tvMode ? 12 : (compactMobile ? 6 : 8)),
                        Text(
                          hero.title,
                          maxLines: tvMode ? 1 : (veryCompactMobile ? 2 : 3),
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontSize: titleFontSize,
                                height: veryCompactMobile ? 1.02 : 1.0,
                                fontWeight: FontWeight.w800,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xB8000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                        ),
                        if (showDescription) ...[
                          SizedBox(height: tvMode ? 4 : 6),
                          Text(
                            hero.description,
                            maxLines: tvMode ? 1 : (veryCompactMobile ? 1 : 2),
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontSize: descriptionFontSize,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.84,
                                  ),
                                ),
                          ),
                        ],
                        if (metadata.isNotEmpty && !tvMode) ...[
                          SizedBox(height: compactMobile ? 5 : 7),
                          Text(
                            metadata.join('  •  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.88,
                                  ),
                                  fontSize: metadataFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                        SizedBox(height: tvMode ? 8 : (compactMobile ? 8 : 10)),
                        Wrap(
                          spacing: compactMobile ? 10 : 12,
                          runSpacing: compactMobile ? 8 : 10,
                          children: [
                            if (tvMode)
                              TvFocusable(
                                onPressed: hero.onPrimary,
                                builder: (context, pillFocused) =>
                                    _TvHeroActionPill(
                                      label: hero.primaryLabel,
                                      focused: pillFocused,
                                    ),
                              )
                            else
                              FilledButton.icon(
                                style: actionStyle,
                                onPressed: hero.onPrimary,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(hero.primaryLabel),
                              ),
                            if (!tvMode)
                              OutlinedButton.icon(
                                onPressed: hero.onSecondary,
                                icon: const Icon(Icons.explore_rounded),
                                label: Text(hero.secondaryLabel),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return buildCard(context, focused: false);
  }
}

class _TvHeroActionPill extends StatelessWidget {
  const _TvHeroActionPill({required this.label, required this.focused});

  final String label;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: focused ? const Color(0xFFFFF3E7) : const Color(0xFFF28A38),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: _kHomeTvFocusGlow.withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow_rounded,
            size: 20,
            color: focused ? const Color(0xFF161005) : Colors.black,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: focused ? const Color(0xFF161005) : Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueWatchingData {
  const _ContinueWatchingData({
    required this.dedupeKey,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.remainingLabel,
    required this.icon,
    required this.onPressed,
    this.imageUrl,
    this.posterImageUrl,
    this.seriesId,
    this.removableContentType,
    this.removableItemId,
  });

  final String dedupeKey;
  final String title;
  final String subtitle;
  final double progress;
  final String remainingLabel;
  final String? imageUrl;
  final String? posterImageUrl;
  final String? seriesId;
  final IconData icon;
  final VoidCallback onPressed;
  final PlaybackContentType? removableContentType;
  final String? removableItemId;
}

class _ContinueWatchingSectionData {
  const _ContinueWatchingSectionData({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<_ContinueWatchingData> items;
}

class _ContinueWatchingCard extends StatelessWidget {
  const _ContinueWatchingCard({
    required this.layout,
    required this.item,
    this.compactTvCard = false,
    this.heading = 'Continuar assistindo',
  });

  final DeviceLayout layout;
  final _ContinueWatchingData? item;
  final bool compactTvCard;
  final String heading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final useCompactTvVariant = layout.isTv && compactTvCard;
    final cardPadding = useCompactTvVariant
        ? 16.0
        : (layout.isTv ? 14.0 : 12.0);
    final headerSize = useCompactTvVariant ? 24.0 : (layout.isTv ? 30.0 : 22.0);
    final artworkWidth = useCompactTvVariant
        ? 148.0
        : (layout.isTv ? 180.0 : 150.0);
    final titleSize = useCompactTvVariant ? 23.0 : (layout.isTv ? 28.0 : 19.0);
    final progressHeight = useCompactTvVariant
        ? 8.0
        : (layout.isTv ? 9.0 : 8.0);
    final chevronSize = useCompactTvVariant
        ? 34.0
        : (layout.isTv ? 40.0 : 36.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontSize: headerSize),
        ),
        SizedBox(height: useCompactTvVariant ? 12 : layout.sectionSpacing - 2),
        if (item == null)
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(layout.isTv ? 22 : 20),
              gradient: LinearGradient(
                colors: [
                  colorScheme.surface.withValues(alpha: 0.86),
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'Nenhum titulo em andamento neste momento.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          TvFocusable(
            onPressed: item!.onPressed,
            builder: (context, focused) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(layout.isTv ? 22 : 20),
                  gradient: LinearGradient(
                    colors: focused
                        ? [
                            colorScheme.primary.withValues(alpha: 0.24),
                            colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.9,
                            ),
                          ]
                        : [
                            colorScheme.surface.withValues(alpha: 0.86),
                            colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.72,
                            ),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: focused
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.4),
                    width: focused ? 2 : 1,
                  ),
                  boxShadow: focused
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : const [],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: artworkWidth,
                      child: BrandedArtwork(
                        imageUrl: item!.imageUrl,
                        aspectRatio: 16 / 9,
                        placeholderLabel: 'Sem capa',
                        icon: item!.icon,
                        borderRadius: 14,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontSize: titleSize),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item!.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.82,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: item!.progress,
                              minHeight: progressHeight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Restando: ${item!.remainingLabel}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: chevronSize,
                      color: focused
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.56),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ContinueWatchingRailSection extends StatelessWidget {
  const _ContinueWatchingRailSection({
    required this.layout,
    required this.section,
  });

  final DeviceLayout layout;
  final _ContinueWatchingSectionData section;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sectionGap = switch (layout.deviceClass) {
      DeviceClass.mobilePortrait => 8.0,
      DeviceClass.mobileLandscape => 10.0,
      DeviceClass.tablet => 12.0,
      _ => layout.sectionSpacing,
    };
    final railHeight = switch (layout.deviceClass) {
      DeviceClass.mobilePortrait => 224.0,
      DeviceClass.mobileLandscape => 232.0,
      DeviceClass.tablet => 246.0,
      _ => 224.0,
    };
    final railSpacing = switch (layout.deviceClass) {
      DeviceClass.mobilePortrait => 12.0,
      DeviceClass.mobileLandscape => 14.0,
      DeviceClass.tablet => 14.0,
      _ => layout.cardSpacing,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.primary.withValues(alpha: 0.16),
              ),
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    section.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.76),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: sectionGap),
        SizedBox(
          height: railHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewportWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: section.items.length,
                separatorBuilder: (context, index) =>
                    SizedBox(width: railSpacing),
                itemBuilder: (context, index) {
                  return _ContinueWatchingRailCard(
                    layout: layout,
                    item: section.items[index],
                    viewportWidth: viewportWidth,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContinueWatchingRailCard extends ConsumerWidget {
  const _ContinueWatchingRailCard({
    required this.layout,
    required this.item,
    required this.viewportWidth,
  });

  final DeviceLayout layout;
  final _ContinueWatchingData item;
  final double viewportWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final playbackHistoryController = ref.read(
      playbackHistoryControllerProvider.notifier,
    );
    final cardWidth = switch (layout.deviceClass) {
      DeviceClass.mobilePortrait => (viewportWidth - 54).clamp(248.0, 320.0),
      DeviceClass.mobileLandscape => (viewportWidth * 0.42).clamp(260.0, 340.0),
      DeviceClass.tablet => (viewportWidth * 0.38).clamp(300.0, 380.0),
      _ => (viewportWidth - 54).clamp(248.0, 320.0),
    };
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: layout.deviceClass == DeviceClass.tablet ? 15.5 : 14.5,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
    final remainingStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.76),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    );
    final remainingText = _formatContinueRemainingText(item.remainingLabel);
    final normalizedCurrentImage = BrandedArtwork.normalizeArtworkUrl(
      item.imageUrl,
    );
    final normalizedPosterImage = BrandedArtwork.normalizeArtworkUrl(
      item.posterImageUrl,
    );
    final needsBackdropLookup =
        normalizedCurrentImage == null ||
        normalizedCurrentImage == normalizedPosterImage;
    var resolvedThumbnailImageUrl = item.imageUrl;
    if (needsBackdropLookup &&
        item.removableContentType == PlaybackContentType.vod) {
      final vodId = item.removableItemId?.trim();
      if (vodId != null && vodId.isNotEmpty) {
        final vodInfoAsync = ref.watch(vodInfoProvider(vodId));
        resolvedThumbnailImageUrl = vodInfoAsync.maybeWhen(
          data: (info) => info.backdropUrl ?? item.imageUrl,
          orElse: () => item.imageUrl,
        );
      }
    } else if (needsBackdropLookup &&
        item.removableContentType == PlaybackContentType.seriesEpisode) {
      final seriesId = item.seriesId?.trim();
      if (seriesId != null && seriesId.isNotEmpty) {
        final seriesInfoAsync = ref.watch(seriesInfoProvider(seriesId));
        resolvedThumbnailImageUrl = seriesInfoAsync.maybeWhen(
          data: (info) => info.backdropUrl ?? item.imageUrl,
          orElse: () => item.imageUrl,
        );
      }
    }
    final menuButton = SizedBox(
      width: 30,
      height: 30,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.54),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: PopupMenuButton<_ContinueWatchingMenuAction>(
          padding: EdgeInsets.zero,
          tooltip: 'Mais opções',
          position: PopupMenuPosition.under,
          color: colorScheme.surfaceContainerHighest,
          iconSize: 17,
          splashRadius: 18,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          icon: Icon(
            Icons.more_vert_rounded,
            color: Colors.white.withValues(alpha: 0.92),
          ),
          onSelected: (action) async {
            switch (action) {
              case _ContinueWatchingMenuAction.open:
                item.onPressed();
                return;
              case _ContinueWatchingMenuAction.remove:
                final contentType = item.removableContentType;
                final itemId = item.removableItemId?.trim();
                if (contentType == null || itemId == null || itemId.isEmpty) {
                  return;
                }
                await playbackHistoryController.remove(contentType, itemId);
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '"${item.title}" removido de Continuar assistindo.',
                    ),
                  ),
                );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _ContinueWatchingMenuAction.open,
              child: Text('Abrir'),
            ),
            if (item.removableContentType != null &&
                item.removableItemId?.trim().isNotEmpty == true)
              const PopupMenuItem(
                value: _ContinueWatchingMenuAction.remove,
                child: Text('Remover da lista'),
              ),
          ],
        ),
      ),
    );

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: item.onPressed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _ContinueWatchingThumbnail(
                    imageUrl: resolvedThumbnailImageUrl,
                    posterImageUrl: item.posterImageUrl,
                    icon: item.icon,
                    borderRadius: 16,
                    aspectRatio: 16 / 9,
                  ),
                  Positioned(top: 8, right: 8, child: menuButton),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              if (remainingText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  remainingText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: remainingStyle,
                ),
              ],
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: item.progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ContinueWatchingMenuAction { open, remove }

class _ContinueWatchingThumbnail extends StatefulWidget {
  const _ContinueWatchingThumbnail({
    required this.imageUrl,
    this.posterImageUrl,
    required this.icon,
    required this.borderRadius,
    this.aspectRatio = 16 / 9,
  });

  final String? imageUrl;
  final String? posterImageUrl;
  final IconData icon;
  final double borderRadius;
  final double aspectRatio;

  @override
  State<_ContinueWatchingThumbnail> createState() =>
      _ContinueWatchingThumbnailState();
}

class _ContinueWatchingThumbnailState
    extends State<_ContinueWatchingThumbnail> {
  static const _imageHeaders = {'Accept-Encoding': 'identity'};

  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  String? _observedUrl;
  bool _isPortrait = false;

  @override
  void initState() {
    super.initState();
    _resolveImageOrientation();
  }

  @override
  void didUpdateWidget(covariant _ContinueWatchingThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.posterImageUrl != widget.posterImageUrl) {
      _resolveImageOrientation();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  void _removeImageListener() {
    final stream = _imageStream;
    final listener = _imageStreamListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  void _resolveImageOrientation() {
    _removeImageListener();

    // Prefer the main thumbnail image when resolving orientation so a fetched
    // backdrop can switch the card out of the poster fallback composition.
    final normalizedUrl =
        BrandedArtwork.normalizeArtworkUrl(widget.imageUrl) ??
        BrandedArtwork.normalizeArtworkUrl(widget.posterImageUrl);
    _observedUrl = normalizedUrl;
    if (normalizedUrl == null) {
      if (_isPortrait) {
        setState(() {
          _isPortrait = false;
        });
      }
      return;
    }

    // Default to landscape crop until the real ratio is known.
    if (_isPortrait) {
      setState(() {
        _isPortrait = false;
      });
    }

    final provider = NetworkImage(normalizedUrl, headers: _imageHeaders);
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (imageInfo, synchronousCall) {
        if (!mounted || _observedUrl != normalizedUrl) {
          return;
        }
        final isPortrait = imageInfo.image.height > imageInfo.image.width;
        if (_isPortrait != isPortrait) {
          setState(() {
            _isPortrait = isPortrait;
          });
        }
      },
      onError: (exception, stackTrace) {
        if (!mounted || _observedUrl != normalizedUrl) {
          return;
        }
        if (_isPortrait) {
          setState(() {
            _isPortrait = false;
          });
        }
      },
    );
    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedLandscapeUrl = BrandedArtwork.normalizeArtworkUrl(
      widget.imageUrl,
    );
    final normalizedPosterUrl =
        BrandedArtwork.normalizeArtworkUrl(widget.posterImageUrl) ??
        normalizedLandscapeUrl;
    final radius = BorderRadius.circular(widget.borderRadius);
    final usePosterComposition =
        normalizedPosterUrl != null &&
        (normalizedLandscapeUrl == null || _isPortrait);
    final resolvedDisplayUrl = normalizedLandscapeUrl ?? normalizedPosterUrl;

    Widget buildFullBleed(String imageUrl) {
      final applyTint = !_isPortrait;
      final imageTint = applyTint ? Colors.black.withValues(alpha: 0.14) : null;
      final imageBlendMode = applyTint ? BlendMode.darken : null;
      final alignment = _isPortrait ? Alignment.topCenter : Alignment.center;

      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            alignment: alignment,
            headers: _imageHeaders,
            filterQuality: FilterQuality.medium,
            color: imageTint,
            colorBlendMode: imageBlendMode,
            errorBuilder: (context, error, stackTrace) =>
                _ContinueWatchingThumbnailFallback(icon: widget.icon),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0x52040A14),
                  Color(0x16040A14),
                  Color(0x00040A14),
                ],
              ),
            ),
          ),
        ],
      );
    }

    Widget buildPosterComposition(String imageUrl) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Transform.scale(
              scale: 1.22,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                headers: _imageHeaders,
                filterQuality: FilterQuality.medium,
                color: Colors.black.withValues(alpha: 0.22),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (context, error, stackTrace) =>
                    _ContinueWatchingThumbnailFallback(icon: widget.icon),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xA8040A14),
                  Color(0x5A040A14),
                  Color(0x22040A14),
                ],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0x50040A14),
                  Color(0x14040A14),
                  Color(0x00040A14),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: 0.32,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.34),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        headers: _imageHeaders,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, stackTrace) =>
                            _ContinueWatchingThumbnailFallback(
                              icon: widget.icon,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.54),
          ),
          child: normalizedLandscapeUrl == null && normalizedPosterUrl == null
              ? _ContinueWatchingThumbnailFallback(icon: widget.icon)
              : usePosterComposition
              ? buildPosterComposition(normalizedPosterUrl)
              : buildFullBleed(resolvedDisplayUrl!),
        ),
      ),
    );
  }
}

class _ContinueWatchingThumbnailFallback extends StatelessWidget {
  const _ContinueWatchingThumbnailFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.16),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
            colorScheme.surface.withValues(alpha: 0.96),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 28,
          color: colorScheme.primary.withValues(alpha: 0.78),
        ),
      ),
    );
  }
}

class _CategoryChipRail extends StatefulWidget {
  const _CategoryChipRail({required this.layout, required this.categories});

  final DeviceLayout layout;
  final List<String> categories;

  @override
  State<_CategoryChipRail> createState() => _CategoryChipRailState();
}

class _CategoryChipRailState extends State<_CategoryChipRail> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorias de filmes',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: widget.layout.isTv ? 27 : 30,
          ),
        ),
        SizedBox(height: widget.layout.sectionSpacing - 2),
        SizedBox(
          height: widget.layout.isTv ? 58 : 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.categories.length,
            separatorBuilder: (context, index) =>
                SizedBox(width: widget.layout.cardSpacing - 4),
            itemBuilder: (context, index) {
              final selected = index == _selectedIndex;
              return TvFocusable(
                onPressed: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                builder: (context, focused) {
                  final active = selected || focused;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: active
                          ? LinearGradient(
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.45),
                                colorScheme.secondary.withValues(alpha: 0.2),
                              ],
                            )
                          : null,
                      color: active
                          ? null
                          : colorScheme.surface.withValues(alpha: 0.55),
                      border: Border.all(
                        color: active
                            ? colorScheme.primary.withValues(alpha: 0.78)
                            : colorScheme.outline.withValues(alpha: 0.35),
                        width: active ? 1.8 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.categories[index],
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: widget.layout.isTv ? 14.5 : null,
                              color: active
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.88,
                                    ),
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HomeQuickAction {
  const _HomeQuickAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.badge,
    this.interactiveKey,
    this.testId,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final Key? interactiveKey;
  final String? testId;
}

class _HomeRailCardData {
  const _HomeRailCardData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.posterImageUrl,
    this.backdropImageUrl,
    required this.icon,
    required this.onPressed,
    this.badge,
    this.aspectRatio = 2 / 3,
    this.imagePadding = EdgeInsets.zero,
    this.fit = BoxFit.cover,
    this.liveStreamId,
    this.supportsLiveEpg = false,
    this.noEpgFallbackLabel = 'Ao vivo agora',
    this.hasReplay = false,
    this.libraryKind,
    this.contentId,
    this.seriesId,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? posterImageUrl;
  final String? backdropImageUrl;
  final IconData icon;
  final VoidCallback onPressed;
  final String? badge;
  final double aspectRatio;
  final EdgeInsets imagePadding;
  final BoxFit fit;
  final String? liveStreamId;
  final bool supportsLiveEpg;
  final String noEpgFallbackLabel;
  final bool hasReplay;
  final OnDemandLibraryKind? libraryKind;
  final String? contentId;
  final String? seriesId;
}

List<_HomeRailCardData> _buildVodCards(
  List<VodStream>? items,
  BuildContext context,
) {
  if (items == null || items.isEmpty) {
    return const [];
  }

  return items.take(14).map((item) {
    final libraryKind =
        OnDemandLibraryKind.tryParse(item.libraryKind) ??
        OnDemandLibraryKind.movies;
    final subtitle = item.rating?.trim().isNotEmpty == true
        ? 'Nota ${item.rating}'
        : 'Sob demanda';
    return _HomeRailCardData(
      title: item.name,
      subtitle: subtitle,
      imageUrl: item.coverUrl,
      posterImageUrl: item.coverUrl,
      icon: Icons.movie_creation_outlined,
      badge: libraryKind == OnDemandLibraryKind.kids ? 'KIDS' : 'FILME',
      onPressed: () => context.push(VodDetailsScreen.buildLocation(item.id)),
      libraryKind: libraryKind,
      contentId: item.id,
    );
  }).toList();
}

List<_HomeRailCardData> _buildSeriesCards(
  List<SeriesItem>? items,
  BuildContext context,
) {
  if (items == null || items.isEmpty) {
    return const [];
  }

  return items.take(14).map((item) {
    final libraryKind =
        OnDemandLibraryKind.tryParse(item.libraryKind) ??
        (_looksLikeAnime(item.name, item.plot ?? '')
            ? OnDemandLibraryKind.anime
            : OnDemandLibraryKind.series);
    final isAnime = libraryKind == OnDemandLibraryKind.anime;
    return _HomeRailCardData(
      title: item.name,
      subtitle: item.plot?.trim().isNotEmpty == true
          ? item.plot!
          : 'Série para maratonar',
      imageUrl: item.coverUrl,
      posterImageUrl: item.coverUrl,
      icon: Icons.tv_rounded,
      badge: isAnime ? 'ANIME' : 'SÉRIE',
      onPressed: () => context.push(SeriesDetailsScreen.buildLocation(item.id)),
      libraryKind: libraryKind,
      contentId: item.id,
      seriesId: item.id,
    );
  }).toList();
}

List<_HomeRailCardData> _buildLiveCards(
  List<LiveStream>? items,
  BuildContext context,
) {
  if (items == null || items.isEmpty) {
    return const [];
  }

  final visibleItems = items.take(16).toList(growable: false);
  final prioritizedItems = [
    ...visibleItems.where(
      (item) => item.epgChannelId?.trim().isNotEmpty == true,
    ),
    ...visibleItems.where(
      (item) => item.epgChannelId?.trim().isNotEmpty != true,
    ),
  ];

  return prioritizedItems.asMap().entries.map((entry) {
    final index = entry.key;
    final item = entry.value;
    final hasEpgSignal = item.epgChannelId?.trim().isNotEmpty == true;
    final noEpgLabel = item.hasArchive ? 'Ao vivo com replay' : 'Ao vivo agora';
    return _HomeRailCardData(
      title: item.name,
      subtitle: hasEpgSignal ? 'Programacao ao vivo' : noEpgLabel,
      imageUrl: item.iconUrl,
      posterImageUrl: item.iconUrl,
      icon: Icons.live_tv_rounded,
      badge: 'LIVE',
      aspectRatio: 16 / 9,
      imagePadding: const EdgeInsets.all(18),
      fit: BoxFit.contain,
      liveStreamId: item.id,
      supportsLiveEpg: hasEpgSignal,
      noEpgFallbackLabel: noEpgLabel,
      hasReplay: item.hasArchive,
      libraryKind: null,
      contentId: item.id,
      onPressed: () => context.push(
        PlayerScreen.routePath,
        extra: buildLivePlaybackContext(prioritizedItems, index),
      ),
    );
  }).toList();
}

List<_HomeRailCardData> _filterHomeCardsByLibrary(
  List<_HomeRailCardData> cards,
  OnDemandLibraryKind library,
) {
  return cards
      .where((card) => card.libraryKind == library)
      .toList(growable: false);
}

OnDemandLibraryKind? _resolveDiscoveryItemLibraryKind(
  HomeDiscoveryItemDto item, {
  String? railLibraryKind,
}) {
  final explicitKind =
      OnDemandLibraryKind.tryParse(item.libraryKind) ??
      OnDemandLibraryKind.tryParse(railLibraryKind);
  if (explicitKind != null) {
    return explicitKind;
  }

  final mediaType = item.mediaType?.trim().toLowerCase() ?? '';
  if (mediaType.contains('anime')) {
    return OnDemandLibraryKind.anime;
  }
  if (mediaType.contains('series') ||
      mediaType == 'tvseries' ||
      mediaType == 'tv_show' ||
      mediaType == 'tv show') {
    return OnDemandLibraryKind.series;
  }
  if (mediaType == 'vod' || mediaType == 'movie') {
    return OnDemandLibraryKind.movies;
  }
  return null;
}

OnDemandLibraryKind? _resolveDiscoveryRailLibraryKind(
  HomeDiscoveryRailDto rail,
) {
  final explicitKind = OnDemandLibraryKind.tryParse(rail.libraryKind);
  if (explicitKind != null) {
    return explicitKind;
  }

  for (final item in rail.items) {
    final itemKind = _resolveDiscoveryItemLibraryKind(
      item,
      railLibraryKind: rail.libraryKind,
    );
    if (itemKind != null) {
      return itemKind;
    }
  }

  final normalizedSlug = rail.slug?.trim().toLowerCase() ?? '';
  if (normalizedSlug.contains('anime')) {
    return OnDemandLibraryKind.anime;
  }
  if (normalizedSlug.contains('series')) {
    return OnDemandLibraryKind.series;
  }
  if (normalizedSlug.contains('movie') || normalizedSlug.contains('vod')) {
    return OnDemandLibraryKind.movies;
  }
  return null;
}

bool _matchesDiscoveryRailLibraryKind(
  HomeDiscoveryRailDto rail,
  OnDemandLibraryKind libraryKind,
) {
  return _resolveDiscoveryRailLibraryKind(rail) == libraryKind;
}

bool _shouldShowKidsLibraryEntry({
  required HomeDiscoveryRailDto? discoveryKidsRail,
  required List<VodStream>? vodItems,
  required List<SeriesItem>? seriesItems,
}) {
  if (discoveryKidsRail != null &&
      _matchesDiscoveryRailLibraryKind(
        discoveryKidsRail,
        OnDemandLibraryKind.kids,
      ) &&
      discoveryKidsRail.items.isNotEmpty) {
    return true;
  }

  final hasVodKids =
      vodItems?.any(
        (item) =>
            OnDemandLibraryKind.tryParse(item.libraryKind) ==
            OnDemandLibraryKind.kids,
      ) ??
      false;
  if (hasVodKids) {
    return true;
  }

  return seriesItems?.any(
        (item) =>
            OnDemandLibraryKind.tryParse(item.libraryKind) ==
            OnDemandLibraryKind.kids,
      ) ??
      false;
}

class _HomeRailSection extends StatelessWidget {
  const _HomeRailSection({
    required this.layout,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onViewAll,
    required this.cards,
    required this.state,
    this.collapseWhenEmptyOnTv = false,
    this.compactTvHeader = false,
    this.tvCardScale = 1.0,
  });

  final DeviceLayout layout;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onViewAll;
  final List<_HomeRailCardData> cards;
  final AsyncValue<dynamic> state;
  final bool collapseWhenEmptyOnTv;
  final bool compactTvHeader;
  final double tvCardScale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = state.isLoading && cards.isEmpty;
    final hasError = state.hasError && cards.isEmpty;
    final usePosterDominantMobileStyle =
        !layout.isTv && layout.deviceClass != DeviceClass.tablet;
    final sectionIconSize = layout.isTv
        ? 40.0
        : usePosterDominantMobileStyle
        ? 32.0
        : 36.0;
    final sectionGap = layout.isTv && compactTvHeader
        ? 10.0
        : layout.isTv
        ? (layout.sectionSpacing - 2).clamp(0, 999).toDouble()
        : usePosterDominantMobileStyle
        ? (layout.sectionSpacing - 3).clamp(8, 999).toDouble()
        : layout.sectionSpacing;
    final railItemSpacing = usePosterDominantMobileStyle
        ? (layout.cardSpacing - 3).clamp(8, 999).toDouble()
        : layout.cardSpacing;
    if (layout.isTv && collapseWhenEmptyOnTv && cards.isEmpty) {
      return const SizedBox.shrink();
    }
    final prefersLandscape = cards.isNotEmpty && cards.first.aspectRatio >= 1.3;
    final compactTvSection = layout.isTv && compactTvHeader;
    final showSubtitle = subtitle.trim().isNotEmpty && !compactTvSection;
    final effectiveSectionIconSize = compactTvSection ? 30.0 : sectionIconSize;
    final railHeight = _resolveRailHeight(
      layout,
      prefersLandscape: prefersLandscape,
      tvCardScale: tvCardScale,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: effectiveSectionIconSize,
              height: effectiveSectionIconSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  compactTvSection
                      ? 9
                      : (usePosterDominantMobileStyle ? 10 : 12),
                ),
                color: colorScheme.primary.withValues(
                  alpha: usePosterDominantMobileStyle ? 0.12 : 0.16,
                ),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: layout.isTv
                    ? (compactTvSection ? 17 : 23)
                    : usePosterDominantMobileStyle
                    ? 18
                    : 20,
              ),
            ),
            SizedBox(width: compactTvSection ? 8 : (layout.isTv ? 12 : 10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: compactTvSection
                          ? 18
                          : layout.isTv
                          ? 23
                          : usePosterDominantMobileStyle
                          ? 21
                          : 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (showSubtitle)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.76),
                        fontSize: layout.isTv ? 12 : 12,
                      ),
                    ),
                ],
              ),
            ),
            if (layout.isTv)
              _TvViewAllButton(
                key: ValueKey<String>('home.tv.rail.viewAll.$title'),
                onPressed: onViewAll,
              )
            else
              TextButton.icon(
                onPressed: onViewAll,
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Ver tudo'),
              ),
          ],
        ),
        SizedBox(height: sectionGap),
        if (isLoading)
          _RailPlaceholder(
            layout: layout,
            height: railHeight,
            prefersLandscape: prefersLandscape,
          )
        else if (hasError)
          _RailErrorCard(layout: layout, onPressed: onViewAll)
        else if (cards.isEmpty)
          _RailEmptyCard(layout: layout, onPressed: onViewAll)
        else
          SizedBox(
            height: railHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (context, index) =>
                  SizedBox(width: railItemSpacing),
              itemBuilder: (context, index) {
                return _HomeRailCard(
                  layout: layout,
                  data: cards[index],
                  autofocus: false,
                  tvCardScale: tvCardScale,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TvViewAllButton extends StatelessWidget {
  const _TvViewAllButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 140,
      child: TvFocusable(
        autofocus: false,
        onPressed: onPressed,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: focused
                  ? const Color(0xFFFFE5CA)
                  : colorScheme.surface.withValues(alpha: 0.68),
              border: Border.all(
                color: focused
                    ? colorScheme.secondary
                    : colorScheme.outline.withValues(alpha: 0.4),
                width: focused ? 2.4 : 1,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver tudo',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: focused ? const Color(0xFF140B02) : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: focused ? const Color(0xFF140B02) : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

double _resolveRailHeight(
  DeviceLayout layout, {
  required bool prefersLandscape,
  double tvCardScale = 1.0,
}) {
  if (!layout.isTv && layout.deviceClass != DeviceClass.tablet) {
    return prefersLandscape ? 218 : 294;
  }
  if (prefersLandscape) {
    return layout.isTv ? 238 * tvCardScale : 226;
  }
  return layout.isTv ? 368 * tvCardScale : 304;
}

class _HomeRailCard extends StatelessWidget {
  const _HomeRailCard({
    required this.layout,
    required this.data,
    required this.autofocus,
    this.tvCardScale = 1.0,
  });

  final DeviceLayout layout;
  final _HomeRailCardData data;
  final bool autofocus;
  final double tvCardScale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscapeCard = data.aspectRatio >= 1.3;
    final usePosterDominantMobileStyle =
        !layout.isTv && layout.deviceClass != DeviceClass.tablet;
    final cardWidth = switch ((layout.isTv, isLandscapeCard)) {
      (true, true) => 320.0 * tvCardScale,
      (true, false) => 204.0 * tvCardScale,
      (false, true) => 236.0,
      (false, false) => 156.0,
    };
    final artworkAspectRatio = isLandscapeCard
        ? data.aspectRatio
        : layout.isTv
        ? 0.82
        : data.aspectRatio;
    final artworkRadius = layout.isTv ? 16.0 : 14.0;
    final focusedArtworkRadius = artworkRadius + 4;
    final compactTvLiveMeta =
        layout.isTv && data.liveStreamId != null && isLandscapeCard;

    return SizedBox(
      width: cardWidth,
      child: TvFocusable(
        autofocus: autofocus,
        onPressed: data.onPressed,
        builder: (context, focused) {
          if (usePosterDominantMobileStyle) {
            final posterRadius = isLandscapeCard ? 16.0 : 18.0;
            final mobileMetaStyle = Theme.of(context).textTheme.bodySmall
                ?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.74),
                  fontSize: 11,
                  height: 1.25,
                );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(posterRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      BrandedArtwork(
                        imageUrl: data.imageUrl,
                        aspectRatio: artworkAspectRatio,
                        placeholderLabel: 'Imagem indisponivel',
                        icon: data.icon,
                        imagePadding: data.imagePadding,
                        fit: data.fit,
                        borderRadius: posterRadius,
                        chrome: BrandedArtworkChrome.subtle,
                      ),
                      if (isLandscapeCard)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(posterRadius),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x00000000), Color(0xD9000000)],
                              ),
                            ),
                          ),
                        ),
                      if (data.badge != null)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  data.badge == 'LIVE' ||
                                      data.badge == 'AO VIVO'
                                  ? const Color(0xCCFF4A57)
                                  : Colors.black.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              data.badge == 'LIVE' ? 'AO VIVO' : data.badge!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    letterSpacing: 0.6,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ),
                      if (isLandscapeCard)
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 8,
                          child: Text(
                            data.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (!isLandscapeCard)
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                if (!isLandscapeCard) const SizedBox(height: 3),
                if (data.liveStreamId != null)
                  _MobileLiveHomeCardMeta(
                    streamId: data.liveStreamId!,
                    supportsEpg: data.supportsLiveEpg,
                    fallbackSubtitle: data.noEpgFallbackLabel,
                    defaultSubtitle: data.subtitle,
                    hasReplay: data.hasReplay,
                  )
                else
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: mobileMetaStyle,
                  ),
              ],
            );
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: EdgeInsets.all(layout.isTv ? 0 : 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(layout.isTv ? 16 : 18),
              color: layout.isTv ? Colors.transparent : null,
              gradient: layout.isTv
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: focused
                          ? [
                              colorScheme.primary.withValues(alpha: 0.26),
                              colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.96,
                              ),
                            ]
                          : [
                              colorScheme.surface.withValues(alpha: 0.86),
                              colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.72,
                              ),
                            ],
                    ),
              border: layout.isTv
                  ? null
                  : Border.all(
                      color: focused
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.5),
                      width: focused ? 2.6 : 1,
                    ),
              boxShadow: !layout.isTv && focused
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(
                          alpha: layout.isTv ? 0.16 : 0.24,
                        ),
                        blurRadius: layout.isTv ? 12 : 18,
                        offset: Offset(0, layout.isTv ? 6 : 9),
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: layout.isTv
                      ? const EdgeInsets.all(3)
                      : EdgeInsets.zero,
                  decoration: layout.isTv
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            focusedArtworkRadius,
                          ),
                          border: Border.all(
                            color: focused
                                ? _kHomeTvFocusColor
                                : Colors.transparent,
                            width: 2.4,
                          ),
                          boxShadow: focused
                              ? [
                                  BoxShadow(
                                    color: _kHomeTvFocusGlow,
                                    blurRadius: 18,
                                    spreadRadius: 1.5,
                                  ),
                                ]
                              : const [],
                        )
                      : null,
                  child: Stack(
                    children: [
                      BrandedArtwork(
                        imageUrl: data.imageUrl,
                        aspectRatio: artworkAspectRatio,
                        placeholderLabel: 'Imagem indisponivel',
                        icon: data.icon,
                        imagePadding: data.imagePadding,
                        fit: data.fit,
                        borderRadius: artworkRadius,
                      ),
                      if (isLandscapeCard)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                artworkRadius,
                              ),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x00000000), Color(0xC0000000)],
                              ),
                            ),
                          ),
                        ),
                      if (data.badge != null)
                        // Mobile shows humanized badges; TV keeps the compact wording.
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  data.badge == 'LIVE' ||
                                      data.badge == 'AO VIVO'
                                  ? const Color(0xCCFF4A57)
                                  : Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              !layout.isTv && data.badge == 'LIVE'
                                  ? 'AO VIVO'
                                  : data.badge!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    letterSpacing: 0.45,
                                    fontWeight: FontWeight.w700,
                                    fontSize: layout.isTv ? 9.5 : null,
                                  ),
                            ),
                          ),
                        ),
                      if (isLandscapeCard)
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 8,
                          child: Text(
                            data.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: compactTvLiveMeta ? 4 : (layout.isTv ? 10 : 8),
                ),
                if (!isLandscapeCard)
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: layout.isTv ? 18 : 15,
                      fontWeight: FontWeight.w700,
                      height: 1.12,
                    ),
                  ),
                SizedBox(height: compactTvLiveMeta ? 2 : (layout.isTv ? 5 : 4)),
                if (layout.isTv && data.liveStreamId != null)
                  _LiveHomeEpgSubtitle(
                    streamId: data.liveStreamId!,
                    supportsEpg: data.supportsLiveEpg,
                    fallbackSubtitle: data.noEpgFallbackLabel,
                    defaultSubtitle: data.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.74),
                      fontSize: compactTvLiveMeta ? 11.5 : 12.5,
                      height: compactTvLiveMeta ? 1.15 : 1.3,
                    ),
                  )
                else if (!layout.isTv && data.liveStreamId != null)
                  _MobileLiveHomeCardMeta(
                    streamId: data.liveStreamId!,
                    supportsEpg: data.supportsLiveEpg,
                    fallbackSubtitle: data.noEpgFallbackLabel,
                    defaultSubtitle: data.subtitle,
                    hasReplay: data.hasReplay,
                  )
                else
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.74),
                      fontSize: layout.isTv ? 12.5 : 11.5,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MobileLiveHomeCardMeta extends ConsumerWidget {
  const _MobileLiveHomeCardMeta({
    required this.streamId,
    required this.supportsEpg,
    required this.fallbackSubtitle,
    required this.defaultSubtitle,
    required this.hasReplay,
  });

  final String streamId;
  final bool supportsEpg;
  final String fallbackSubtitle;
  final String defaultSubtitle;
  final bool hasReplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final fallbackStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.74),
      fontSize: 11.5,
      height: 1.3,
    );

    if (!supportsEpg) {
      return Text(
        fallbackSubtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: fallbackStyle,
      );
    }

    final epgAsync = ref.watch(liveShortEpgProvider(streamId));
    final presentation = epgAsync.when(
      data: (entries) => _resolveMobileHomeLiveEpgPresentation(
        epgState: _resolveHomeLiveEpgState(entries),
        fallbackSubtitle: fallbackSubtitle,
        defaultSubtitle: defaultSubtitle,
        hasReplay: hasReplay,
      ),
      loading: () => _MobileHomeLiveEpgPresentation(
        headline: defaultSubtitle,
        supportingLine: hasReplay ? 'Canal com replay disponivel' : null,
      ),
      error: (_, _) =>
          _MobileHomeLiveEpgPresentation(headline: fallbackSubtitle),
    );

    if (!presentation.hasStructuredEpg) {
      return Text(
        presentation.headline,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: fallbackStyle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          presentation.headline,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.92),
            fontWeight: FontWeight.w700,
            fontSize: 12,
            height: 1.2,
          ),
        ),
        if (presentation.scheduleLine != null) ...[
          const SizedBox(height: 4),
          Text(
            presentation.scheduleLine!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withValues(alpha: 0.92),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
        if (presentation.progress != null) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: presentation.progress,
              minHeight: 4,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
        ],
        if (presentation.supportingLine != null) ...[
          const SizedBox(height: 6),
          Text(
            presentation.supportingLine!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.68),
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

class _LiveHomeEpgSubtitle extends ConsumerWidget {
  const _LiveHomeEpgSubtitle({
    required this.streamId,
    required this.supportsEpg,
    required this.fallbackSubtitle,
    required this.defaultSubtitle,
    required this.style,
  });

  final String streamId;
  final bool supportsEpg;
  final String fallbackSubtitle;
  final String defaultSubtitle;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!supportsEpg) {
      return Text(
        fallbackSubtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final epgAsync = ref.watch(liveShortEpgProvider(streamId));
    final resolved = epgAsync.when(
      data: (entries) {
        final state = _resolveHomeLiveEpgState(entries);
        if (state.current != null) {
          return (
            label: 'Agora: ${state.current!.title}',
            progress: _homeEpgProgress(state.current!, now: DateTime.now()),
          );
        }
        if (state.next != null) {
          return (
            label: 'Prox: ${state.next!.title}',
            progress: null as double?,
          );
        }
        return (label: fallbackSubtitle, progress: null as double?);
      },
      loading: () => (label: defaultSubtitle, progress: null as double?),
      error: (_, _) => (label: fallbackSubtitle, progress: null as double?),
    );

    if (resolved.progress == null) {
      return Text(
        resolved.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          resolved.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: resolved.progress,
            minHeight: 3,
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

class _HomeLiveEpgState {
  const _HomeLiveEpgState({this.current, this.next});

  final LiveEpgEntry? current;
  final LiveEpgEntry? next;
}

class _MobileHomeLiveEpgPresentation {
  const _MobileHomeLiveEpgPresentation({
    required this.headline,
    this.scheduleLine,
    this.supportingLine,
    this.progress,
  });

  final String headline;
  final String? scheduleLine;
  final String? supportingLine;
  final double? progress;

  bool get hasStructuredEpg =>
      scheduleLine != null || supportingLine != null || progress != null;
}

_HomeLiveEpgState _resolveHomeLiveEpgState(List<LiveEpgEntry> entries) {
  if (entries.isEmpty) {
    return const _HomeLiveEpgState();
  }

  final sorted = [...entries]..sort((a, b) => a.startAt.compareTo(b.startAt));
  final now = DateTime.now();
  LiveEpgEntry? current;
  LiveEpgEntry? next;

  for (final entry in sorted) {
    if (entry.isOnAirAt(now)) {
      current = entry;
      continue;
    }
    if (entry.startAt.isAfter(now)) {
      next = entry;
      break;
    }
  }

  if (current == null && sorted.isNotEmpty) {
    final firstFuture = sorted.firstWhere(
      (entry) => entry.startAt.isAfter(now),
      orElse: () => sorted.first,
    );
    next = next ?? firstFuture;
  }

  return _HomeLiveEpgState(current: current, next: next);
}

_MobileHomeLiveEpgPresentation _resolveMobileHomeLiveEpgPresentation({
  required _HomeLiveEpgState epgState,
  required String fallbackSubtitle,
  required String defaultSubtitle,
  required bool hasReplay,
}) {
  final current = epgState.current;
  final next = epgState.next;

  if (current != null) {
    return _MobileHomeLiveEpgPresentation(
      headline: current.title,
      scheduleLine: _formatHomeTimeRange(current.startAt, current.endAt),
      supportingLine: next != null
          ? 'Depois ${_formatHomeClock(next.startAt)} • ${next.title}'
          : hasReplay
          ? 'Canal com replay disponivel'
          : null,
      progress: _homeEpgProgress(current, now: DateTime.now()),
    );
  }

  if (next != null) {
    return _MobileHomeLiveEpgPresentation(
      headline: 'A seguir: ${next.title}',
      scheduleLine: _formatHomeTimeRange(next.startAt, next.endAt),
      supportingLine: hasReplay ? 'Canal com replay disponivel' : null,
    );
  }

  return _MobileHomeLiveEpgPresentation(
    headline: fallbackSubtitle.isNotEmpty ? fallbackSubtitle : defaultSubtitle,
  );
}

String _formatHomeTimeRange(DateTime startAt, DateTime endAt) {
  return '${_formatHomeClock(startAt)} - ${_formatHomeClock(endAt)}';
}

String _formatHomeClock(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

double? _homeEpgProgress(LiveEpgEntry entry, {required DateTime now}) {
  final total = entry.endAt.difference(entry.startAt).inMilliseconds;
  if (total <= 0) {
    return null;
  }

  final elapsed = now.difference(entry.startAt).inMilliseconds;
  return (elapsed / total).clamp(0.0, 1.0);
}

class _RailPlaceholder extends StatelessWidget {
  const _RailPlaceholder({
    required this.layout,
    required this.height,
    required this.prefersLandscape,
  });

  final DeviceLayout layout;
  final double height;
  final bool prefersLandscape;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardWidth = switch ((layout.isTv, prefersLandscape)) {
      (true, true) => 320.0,
      (true, false) => 204.0,
      (false, true) => 236.0,
      (false, false) => 156.0,
    };

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: layout.isTv ? 6 : 4,
        separatorBuilder: (context, index) =>
            SizedBox(width: layout.cardSpacing),
        itemBuilder: (context, index) {
          return Container(
            width: cardWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(layout.isTv ? 22 : 18),
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RailEmptyCard extends StatelessWidget {
  const _RailEmptyCard({required this.layout, required this.onPressed});

  final DeviceLayout layout;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.cardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 22 : 18),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.36),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Nenhum item disponivel nesta secao agora.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onPressed,
            child: const Text('Abrir catalogo'),
          ),
        ],
      ),
    );
  }
}

class _RailErrorCard extends StatelessWidget {
  const _RailErrorCard({required this.layout, required this.onPressed});

  final DeviceLayout layout;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.cardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 22 : 18),
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Falha ao carregar conteudo desta secao.'),
          ),
          OutlinedButton(onPressed: onPressed, child: const Text('Abrir')),
        ],
      ),
    );
  }
}
