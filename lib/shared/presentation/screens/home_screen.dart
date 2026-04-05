import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/display_formatters.dart';
import '../../../core/tv/tv_focusable.dart';
import '../../../features/auth/domain/entities/xtream_session.dart';
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
const _kHomeTvPanelBorderColor = Colors.transparent;
const _kHomeTvPanelGradient = [Color(0xFF1C1330), Color(0xFF151022)];
const _kHomeTvSurface = Color(0xFF211637);
const _kHomeTvSurfaceAlt = Color(0xFF191226);
const _kHomeTvSurfaceFocus = Color(0xFF342052);
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
    final homeDiscoveryState = headerLayout.isTv
        ? const AsyncValue<HomeDiscoveryDto?>.data(null)
        : ref.watch(homeDiscoveryProvider(12));
    final playbackHistory = ref.watch(playbackHistoryControllerProvider);
    final expiresAt = DisplayFormatters.humanizeDate(session.expirationDate);

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

    final tvPrimaryNavigationItems = <_TvNavigationItem>[
      _TvNavigationItem(
        label: 'TV ao vivo',
        subtitle: 'Abrir guia e canais em tempo real',
        badge: 'LIVE',
        icon: Icons.live_tv_rounded,
        interactiveKey: AppTestKeys.homeLiveCard,
        testId: AppTestKeys.homeLiveCardId,
        onTap: () =>
            _openPrimaryDestination(context, LiveCategoriesScreen.routePath),
      ),
      _TvNavigationItem(
        label: 'Filmes',
        subtitle: 'Catalogo sob demanda',
        icon: Icons.movie_creation_outlined,
        interactiveKey: AppTestKeys.homeMoviesCard,
        testId: AppTestKeys.homeMoviesCardId,
        onTap: () =>
            _openPrimaryDestination(context, VodCategoriesScreen.routePath),
      ),
      _TvNavigationItem(
        label: 'Series',
        subtitle: 'Colecoes e temporadas',
        icon: Icons.tv_rounded,
        interactiveKey: AppTestKeys.homeSeriesCard,
        testId: AppTestKeys.homeSeriesCardId,
        onTap: () =>
            _openPrimaryDestination(context, SeriesCategoriesScreen.routePath),
      ),
      _TvNavigationItem(
        label: 'Minha assinatura',
        subtitle: _buildAccountCardDescription(session, expiresAt),
        icon: Icons.verified_user_rounded,
        interactiveKey: AppTestKeys.homeAccountCard,
        testId: AppTestKeys.homeAccountCardId,
        onTap: () => context.push(AccountScreen.routePath),
      ),
    ];

    final tvUtilityNavigationItems = <_TvNavigationItem>[
      _TvNavigationItem(
        label: 'Conta',
        icon: Icons.verified_user_rounded,
        interactiveKey: AppTestKeys.homeAccountAction,
        onTap: () => context.push(AccountScreen.routePath),
      ),
      _TvNavigationItem(
        label: 'Sair',
        icon: Icons.logout_rounded,
        interactiveKey: AppTestKeys.homeLogoutButton,
        onTap: () => ref.read(authControllerProvider.notifier).logout(),
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
    final discoveryAdditionalRails = _buildAdditionalDiscoveryRails(
      home: discoveryHome,
      context: context,
      liveStreams: resolvedLive ?? const <LiveStream>[],
      discoveryState: homeDiscoveryState,
    );

    if (headerLayout.isTv) {
      return WillPopScope(
        onWillPop: () => _handleHomeExitRequest(context),
        child: _TvHomeSurface(
          layout: headerLayout,
          primaryNavItems: tvPrimaryNavigationItems,
          utilityNavItems: tvUtilityNavigationItems,
          continueItem: continueItem,
          liveCards: liveCards,
          vodCards: vodCards,
          seriesCards: seriesCards,
          liveState: livePreview,
          vodState: vodPreview,
          seriesState: seriesPreview,
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
    subtitle:
        subtitleOverride ??
        '$typeLabel • Restando ${_formatRemaining(remaining)}',
    progress: progress,
    remainingLabel: _formatRemaining(remaining),
    imageUrl: imageUrlOverride ?? entry.artworkUrl,
    icon: switch (entry.contentType) {
      PlaybackContentType.vod => Icons.movie_creation_outlined,
      PlaybackContentType.seriesEpisode => Icons.tv_rounded,
      PlaybackContentType.live => Icons.live_tv_rounded,
    },
    onPressed: () => context.push(
      PlayerScreen.routePath,
      extra: PlaybackContext(
        contentType: entry.contentType,
        itemId: entry.itemId,
        title: entry.title,
        containerExtension: entry.containerExtension,
        artworkUrl: entry.artworkUrl,
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

class _TvHomeSurface extends StatelessWidget {
  const _TvHomeSurface({
    required this.layout,
    required this.primaryNavItems,
    required this.utilityNavItems,
    required this.continueItem,
    required this.liveCards,
    required this.vodCards,
    required this.seriesCards,
    required this.liveState,
    required this.vodState,
    required this.seriesState,
  });

  final DeviceLayout layout;
  final List<_TvNavigationItem> primaryNavItems;
  final List<_TvNavigationItem> utilityNavItems;
  final _ContinueWatchingData? continueItem;
  final List<_HomeRailCardData> liveCards;
  final List<_HomeRailCardData> vodCards;
  final List<_HomeRailCardData> seriesCards;
  final AsyncValue<dynamic> liveState;
  final AsyncValue<dynamic> vodState;
  final AsyncValue<dynamic> seriesState;

  @override
  Widget build(BuildContext context) {
    final highlights = _buildTvHighlights(liveCards: liveCards);
    final isLoading = liveState.isLoading && highlights.isEmpty;
    final hasHardError = liveState.hasError && highlights.isEmpty;

    return TvStageScaffold(
      backdrop: const TvStageBackdrop(
        gradientColors: [
          Color(0xFF12081E),
          Color(0xFF1B1032),
          Color(0xFF0D0718),
        ],
        topGlowColor: Color(0x4D7A3DF0),
        bottomGlowColor: Color(0x336529A8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final resolvedLayout = DeviceLayout.of(
            context,
            constraints: constraints,
          );
          final spacing = resolvedLayout.cardSpacing;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TvHomeHeader(
                layout: resolvedLayout,
                utilityItems: utilityNavItems,
              ),
              SizedBox(height: spacing),
              _TvHomePrimaryActions(
                layout: resolvedLayout,
                items: primaryNavItems,
              ),
              SizedBox(height: spacing),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _TvHighlightsPanel(
                        layout: resolvedLayout,
                        highlights: highlights,
                        isLoading: isLoading,
                        hasHardError: hasHardError,
                        onOpenLive: primaryNavItems.first.onTap,
                      ),
                    ),
                    if (continueItem != null) ...[
                      SizedBox(width: spacing),
                      SizedBox(
                        width: resolvedLayout.isTvCompact ? 350 : 390,
                        child: _TvContinuePanel(
                          layout: resolvedLayout,
                          item: continueItem!,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TvHomeHeader extends StatelessWidget {
  const _TvHomeHeader({required this.layout, required this.utilityItems});

  final DeviceLayout layout;
  final List<_TvNavigationItem> utilityItems;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvStagePanel(
      borderColor: _kHomeTvPanelBorderColor,
      gradientColors: _kHomeTvPanelGradient,
      padding: EdgeInsets.symmetric(
        horizontal: layout.isTvCompact ? 16 : 18,
        vertical: layout.isTvCompact ? 12 : 14,
      ),
      radius: 16,
      child: Row(
        children: [
          const BrandWordmark(height: 42, compact: true, showTagline: false),
          SizedBox(width: layout.isTvCompact ? 14 : 18),
          Expanded(
            child: Text(
              'Painel principal da experiencia TV',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.74),
              ),
            ),
          ),
          for (final item in utilityItems) ...[
            const SizedBox(width: 10),
            _TvHomeUtilityButton(item: item),
          ],
          const SizedBox(width: 12),
          const TvStageClock(),
        ],
      ),
    );
  }
}

class _TvHomeUtilityButton extends StatelessWidget {
  const _TvHomeUtilityButton({required this.item});

  final _TvNavigationItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: TvFocusable(
        onPressed: item.onTap,
        interactiveKey: item.interactiveKey,
        testId: item.testId,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: focused ? _kHomeTvSurfaceFocus : _kHomeTvSurfaceAlt,
              border: Border.all(
                color: focused ? _kHomeTvFocusColor : Colors.transparent,
                width: focused ? 2 : 1,
              ),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: _kHomeTvFocusGlow.withValues(alpha: 0.32),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 18, color: focused ? Colors.white : null),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: focused ? Colors.white : null,
                    ),
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

class _TvHomePrimaryActions extends StatelessWidget {
  const _TvHomePrimaryActions({required this.layout, required this.items});

  final DeviceLayout layout;
  final List<_TvNavigationItem> items;

  @override
  Widget build(BuildContext context) {
    return TvStagePanel(
      borderColor: _kHomeTvPanelBorderColor,
      gradientColors: _kHomeTvPanelGradient,
      padding: EdgeInsets.all(layout.isTvCompact ? 14 : 16),
      radius: 18,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              Expanded(
                child: FocusTraversalOrder(
                  order: NumericFocusOrder(index + 1),
                  child: _TvHomePrimaryTile(
                    item: items[index],
                    autofocus: index == 0,
                    compact: layout.isTvCompact,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TvHomePrimaryTile extends StatelessWidget {
  const _TvHomePrimaryTile({
    required this.item,
    required this.autofocus,
    required this.compact,
  });

  final _TvNavigationItem item;
  final bool autofocus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: compact ? 138 : 146,
      child: TvFocusable(
        autofocus: autofocus,
        onPressed: item.onTap,
        interactiveKey: item.interactiveKey,
        testId: item.testId,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 16,
              vertical: compact ? 12 : 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: focused
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4A2A77), Color(0xFF2E1A4A)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_kHomeTvSurface, _kHomeTvSurfaceAlt],
                    ),
              border: Border.all(
                color: focused ? _kHomeTvFocusColor : Colors.transparent,
                width: focused ? 2.2 : 1,
              ),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: _kHomeTvFocusGlow.withValues(alpha: 0.34),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.icon,
                      size: compact ? 28 : 30,
                      color: focused ? Colors.white : null,
                    ),
                    const Spacer(),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: focused ? Colors.white : null,
                      ),
                    ),
                    if (item.subtitle?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: focused
                              ? Colors.white.withValues(alpha: 0.82)
                              : colorScheme.onSurface.withValues(alpha: 0.74),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.badge != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: focused
                            ? const Color(0xCC161005)
                            : const Color(0xD9FF5D67),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.badge!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

class _TvHighlightsPanel extends StatelessWidget {
  const _TvHighlightsPanel({
    required this.layout,
    required this.highlights,
    required this.isLoading,
    required this.hasHardError,
    required this.onOpenLive,
  });

  final DeviceLayout layout;
  final List<_TvHomeHighlightItem> highlights;
  final bool isLoading;
  final bool hasHardError;
  final VoidCallback onOpenLive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget body;
    if (isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (hasHardError) {
      body = _TvHighlightsState(
        title: 'Falha ao carregar destaques ao vivo',
        message: 'Abra a TV ao vivo para tentar carregar o que esta no ar.',
        actionLabel: 'Abrir TV ao vivo',
        onAction: onOpenLive,
      );
    } else if (highlights.isEmpty) {
      body = _TvHighlightsState(
        title: 'Nenhum destaque ao vivo agora',
        message: 'Abra a TV ao vivo para navegar pelos canais do momento.',
        actionLabel: 'Abrir TV ao vivo',
        onAction: onOpenLive,
      );
    } else {
      body = _TvHighlightsShelf(layout: layout, highlights: highlights);
    }

    return Padding(
      padding: EdgeInsets.only(
        left: layout.isTvCompact ? 4 : 6,
        top: layout.isTvCompact ? 4 : 6,
        bottom: layout.isTvCompact ? 2 : 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TvPill(label: 'Destaques de agora', color: colorScheme.primary),
              _TvPill(
                label: '${highlights.length} canais',
                color: colorScheme.secondary,
              ),
            ],
          ),
          SizedBox(height: layout.isTvCompact ? 14 : 16),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _TvPill extends StatelessWidget {
  const _TvPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.18),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

class _TvHighlightsShelf extends StatelessWidget {
  const _TvHighlightsShelf({required this.layout, required this.highlights});

  final DeviceLayout layout;
  final List<_TvHomeHighlightItem> highlights;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: layout.isTvCompact ? 316 : 332,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: highlights.length,
        separatorBuilder: (_, _) => SizedBox(width: layout.cardSpacing + 10),
        itemBuilder: (context, index) {
          return _TvHighlightsCard(
            layout: layout,
            item: highlights[index],
            autofocus: false,
          );
        },
      ),
    );
  }
}

class _TvHighlightsCard extends ConsumerWidget {
  const _TvHighlightsCard({
    required this.layout,
    required this.item,
    required this.autofocus,
  });

  final DeviceLayout layout;
  final _TvHomeHighlightItem item;
  final bool autofocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = layout.isTvCompact ? 312.0 : 336.0;
    final epgState = item.data.supportsLiveEpg && item.data.liveStreamId != null
        ? ref
              .watch(liveShortEpgProvider(item.data.liveStreamId!))
              .maybeWhen(
                data: _resolveHomeLiveEpgState,
                orElse: () => const _HomeLiveEpgState(),
              )
        : const _HomeLiveEpgState();
    final presentation = _resolveTvLiveHighlightPresentation(
      data: item.data,
      epgState: epgState,
    );
    final hasDenseMetadata =
        presentation.scheduleLine != null ||
        presentation.supportingLine != null ||
        presentation.progress != null;
    final headlineMaxLines = hasDenseMetadata ? 2 : 3;
    final showSupportingLine = presentation.scheduleLine == null;
    final showFooterLabel = !hasDenseMetadata;
    final chipColor = switch (presentation.statusLabel) {
      'AGORA' => const Color(0xFFFF8A3D),
      'A SEGUIR' => colorScheme.tertiary,
      _ => colorScheme.primary,
    };

    return SizedBox(
      width: width,
      child: TvFocusable(
        autofocus: autofocus,
        onPressed: item.data.onPressed,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: focused
                  ? const Color(0xCC231338)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: focused
                    ? _kHomeTvFocusColor
                    : Colors.white.withValues(alpha: 0.12),
                width: focused ? 2.4 : 1.15,
              ),
              boxShadow: [
                if (focused)
                  BoxShadow(
                    color: _kHomeTvFocusGlow.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    layout.isTvCompact ? 16 : 18,
                    layout.isTvCompact ? 15 : 17,
                    layout.isTvCompact ? 14 : 16,
                    layout.isTvCompact ? 14 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TvHighlightChip(
                            label: presentation.statusLabel,
                            color: chipColor,
                            focused: focused,
                          ),
                          if (item.data.hasReplay)
                            _TvHighlightChip(
                              label: 'REPLAY',
                              color: colorScheme.secondary,
                              focused: focused,
                              emphasized: false,
                            ),
                        ],
                      ),
                      SizedBox(height: layout.isTvCompact ? 12 : 14),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    presentation.channelLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          letterSpacing: 0.7,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.78),
                                        ),
                                  ),
                                  SizedBox(height: layout.isTvCompact ? 8 : 10),
                                  Text(
                                    presentation.headline,
                                    maxLines: headlineMaxLines,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontSize: layout.isTvCompact
                                              ? 23
                                              : 25,
                                          fontWeight: FontWeight.w800,
                                          height: 1.04,
                                        ),
                                  ),
                                  if (presentation.scheduleLine != null) ...[
                                    SizedBox(
                                      height: layout.isTvCompact ? 8 : 10,
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 18,
                                          color: chipColor.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            presentation.scheduleLine!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.9),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (showSupportingLine &&
                                      presentation.supportingLine != null) ...[
                                    SizedBox(
                                      height: layout.isTvCompact ? 7 : 8,
                                    ),
                                    Text(
                                      presentation.supportingLine!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontSize: layout.isTvCompact
                                                ? 12.5
                                                : 13,
                                            height: 1.28,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.74),
                                          ),
                                    ),
                                  ],
                                  const Spacer(),
                                  if (presentation.progress != null) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value: presentation.progress,
                                        minHeight: 7,
                                        backgroundColor: colorScheme.onSurface
                                            .withValues(alpha: 0.12),
                                        valueColor: AlwaysStoppedAnimation(
                                          chipColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (showFooterLabel)
                                    Text(
                                      presentation.footerLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.76),
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(width: layout.isTvCompact ? 16 : 18),
                            Padding(
                              padding: EdgeInsets.only(
                                top: layout.isTvCompact ? 16 : 18,
                                bottom: 4,
                              ),
                              child: _TvLiveChannelLogo(
                                imageUrl: item.data.imageUrl,
                                channelLabel: presentation.channelLabel,
                                compact: layout.isTvCompact,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _TvHighlightsState extends StatelessWidget {
  const _TvHighlightsState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.chevron_right_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _TvContinuePanel extends StatelessWidget {
  const _TvContinuePanel({required this.layout, required this.item});

  final DeviceLayout layout;
  final _ContinueWatchingData item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvStagePanel(
      borderColor: _kHomeTvPanelBorderColor,
      gradientColors: _kHomeTvPanelGradient,
      padding: EdgeInsets.all(layout.isTvCompact ? 16 : 18),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continuar assistindo',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TvFocusable(
              onPressed: item.onPressed,
              builder: (context, focused) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: focused ? _kHomeTvSurfaceFocus : _kHomeTvSurfaceAlt,
                    border: Border.all(
                      color: focused ? _kHomeTvFocusColor : Colors.transparent,
                      width: focused ? 2.2 : 1,
                    ),
                    boxShadow: focused
                        ? [
                            BoxShadow(
                              color: _kHomeTvFocusGlow.withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : const [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BrandedArtwork(
                        imageUrl: item.imageUrl,
                        aspectRatio: 16 / 9,
                        placeholderLabel: 'Sem capa',
                        icon: item.icon,
                        borderRadius: 12,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.74),
                        ),
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: item.progress,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Restante ${item.remainingLabel}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TvHomeHighlightItem {
  const _TvHomeHighlightItem({required this.data});

  final _HomeRailCardData data;
}

List<_TvHomeHighlightItem> _buildTvHighlights({
  required List<_HomeRailCardData> liveCards,
}) {
  final prioritized = <_HomeRailCardData>[
    ...liveCards.where((item) => item.supportsLiveEpg),
    ...liveCards.where((item) => !item.supportsLiveEpg),
  ];

  return prioritized
      .take(10)
      .map((item) => _TvHomeHighlightItem(data: item))
      .toList();
}

// ignore: unused_element
class _TvHomeExperience extends StatelessWidget {
  const _TvHomeExperience({
    required this.layout,
    required this.hero,
    required this.primaryNavItems,
    required this.utilityNavItems,
    required this.continueItem,
    required this.liveCards,
    required this.vodCards,
    required this.seriesCards,
    required this.liveState,
    required this.vodState,
    required this.seriesState,
  });

  final DeviceLayout layout;
  final _HomeHeroChoice hero;
  final List<_TvNavigationItem> primaryNavItems;
  final List<_TvNavigationItem> utilityNavItems;
  final _ContinueWatchingData? continueItem;
  final List<_HomeRailCardData> liveCards;
  final List<_HomeRailCardData> vodCards;
  final List<_HomeRailCardData> seriesCards;
  final AsyncValue<dynamic> liveState;
  final AsyncValue<dynamic> vodState;
  final AsyncValue<dynamic> seriesState;

  @override
  Widget build(BuildContext context) {
    final hasContinue = continueItem != null;
    final hasLive = liveCards.isNotEmpty;
    final hasVod = vodCards.isNotEmpty;
    final hasSeries = seriesCards.isNotEmpty;
    final liveWithEpg = liveCards.where((card) => card.supportsLiveEpg).length;
    final liveWithoutEpg = (liveCards.length - liveWithEpg).clamp(0, 999);
    final liveSectionSubtitle = _buildLiveSectionSubtitle(
      liveWithEpg: liveWithEpg,
      liveWithoutEpg: liveWithoutEpg,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TvTopNavigationBar(
          layout: layout,
          primaryItems: primaryNavItems,
          utilityItems: utilityNavItems,
        ),
        if (hasLive) ...[
          SizedBox(height: layout.sectionSpacing + 4),
          _HomeRailSection(
            layout: layout,
            title: 'No ar agora',
            subtitle: liveSectionSubtitle,
            icon: Icons.live_tv_rounded,
            onViewAll: () => _openPrimaryDestination(
              context,
              LiveCategoriesScreen.routePath,
            ),
            cards: liveCards,
            state: liveState,
            collapseWhenEmptyOnTv: true,
          ),
        ] else ...[
          SizedBox(height: layout.sectionSpacing + 6),
          _CinematicHeroCard(layout: layout, hero: hero, tvMode: true),
        ],
        if (hasContinue) ...[
          SizedBox(height: layout.sectionSpacing + 8),
          _ContinueWatchingCard(
            layout: layout,
            item: continueItem,
            compactTvCard: true,
            heading: 'Retomar',
          ),
        ],
        if (hasVod) ...[
          SizedBox(height: layout.sectionSpacing + 10),
          _HomeRailSection(
            layout: layout,
            title: 'Filmes',
            subtitle: 'Sob demanda',
            icon: Icons.local_movies_rounded,
            onViewAll: () =>
                _openPrimaryDestination(context, VodCategoriesScreen.routePath),
            cards: vodCards,
            state: vodState,
            collapseWhenEmptyOnTv: true,
          ),
        ],
        if (hasSeries) ...[
          SizedBox(height: layout.sectionSpacing + 10),
          _HomeRailSection(
            layout: layout,
            title: 'Series',
            subtitle: 'Temporadas e colecoes',
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
      ],
    );
  }
}

String _buildLiveSectionSubtitle({
  required int liveWithEpg,
  required int liveWithoutEpg,
}) {
  if (liveWithEpg > 0 && liveWithoutEpg > 0) {
    return 'Programas no ar e canais ao vivo para zapear';
  }
  if (liveWithEpg > 0) {
    return 'Programas no ar agora';
  }
  return 'Canais ao vivo para assistir agora';
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

  for (final badge in badges) {
    final normalized = badge.trim().toUpperCase();
    if (normalized == 'TRENDING' || normalized == 'TRENDING_NOW') {
      return 'DESTAQUE';
    }
    if (normalized == 'TOP') {
      return 'TOP';
    }
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

  final highlightBadge = item.badges
      .map((badge) => badge.trim().toUpperCase())
      .where((badge) => badge == 'TOP' || badge == 'TRENDING')
      .map((badge) => badge == 'TRENDING' ? 'Destaque' : 'Top')
      .toList();
  values.addAll(highlightBadge.take(1));

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
    imageUrl: item.backdrop ?? item.image,
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
      imageUrlOverride: item.preferredArtwork,
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
    imageUrl: item.preferredArtwork,
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
          SizedBox(height: layout.sectionSpacing + 10),
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
          SizedBox(height: layout.sectionSpacing + 10),
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
    this.interactiveKey,
    this.testId,
  });

  final String label;
  final String? subtitle;
  final String? badge;
  final IconData icon;
  final VoidCallback onTap;
  final Key? interactiveKey;
  final String? testId;
}

class _TvTopNavigationBar extends StatelessWidget {
  const _TvTopNavigationBar({
    required this.layout,
    required this.primaryItems,
    required this.utilityItems,
  });

  final DeviceLayout layout;
  final List<_TvNavigationItem> primaryItems;
  final List<_TvNavigationItem> utilityItems;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: layout.isTvCompact ? 12 : 14,
        vertical: layout.isTvCompact ? 9 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xB9121D30), Color(0xA80D1626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.34)),
      ),
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  for (var index = 0; index < primaryItems.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _TvTopNavigationButton(
                        item: primaryItems[index],
                        layout: layout,
                        autofocus: index == 0,
                        focusOrder: index + 1,
                        kind: _TvNavigationButtonKind.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            for (var index = 0; index < utilityItems.length; index++) ...[
              const SizedBox(width: 8),
              _TvTopNavigationButton(
                item: utilityItems[index],
                layout: layout,
                autofocus: false,
                focusOrder: primaryItems.length + index + 1,
                kind: _TvNavigationButtonKind.utility,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _TvNavigationButtonKind { primary, utility }

class _TvTopNavigationButton extends StatelessWidget {
  const _TvTopNavigationButton({
    required this.item,
    required this.layout,
    required this.autofocus,
    required this.focusOrder,
    required this.kind,
  });

  final _TvNavigationItem item;
  final DeviceLayout layout;
  final bool autofocus;
  final int focusOrder;
  final _TvNavigationButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUtility = kind == _TvNavigationButtonKind.utility;
    final iconSize = isUtility ? 18.0 : 20.0;
    final fontSize = isUtility ? 16.0 : 18.0;
    final button = TvFocusable(
      autofocus: autofocus,
      onPressed: item.onTap,
      interactiveKey: item.interactiveKey,
      testId: item.testId,
      builder: (context, focused) {
        final active = focused;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.symmetric(
            horizontal: isUtility ? 10 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFFFFF0DE), Color(0xFFFFD6AE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.7),
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                    ],
                  ),
            border: Border.all(
              color: active
                  ? colorScheme.secondary
                  : colorScheme.outline.withValues(alpha: 0.34),
              width: active ? 2.0 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: iconSize,
                color: active ? const Color(0xFF130D03) : null,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: active ? const Color(0xFF130D03) : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    return FocusTraversalOrder(
      order: NumericFocusOrder(focusOrder.toDouble()),
      child: isUtility
          ? SizedBox(width: layout.isTvCompact ? 112 : 120, child: button)
          : button,
    );
  }
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
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          height: availableWidth / (16 / 8.8),
          child: PageView.builder(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              if (_currentIndex != index) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            itemCount: slides.length,
            itemBuilder: (context, index) {
              return _MobileHeroSlideCard(
                layout: widget.layout,
                hero: slides[index],
                hint: slides.length > 1
                    ? 'Deslize para trocar • ${index + 1}/${slides.length}'
                    : 'Toque para abrir',
              );
            },
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
    required this.hint,
  });

  final DeviceLayout layout;
  final _HomeHeroChoice hero;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = BrandedArtwork.normalizeArtworkUrl(hero.imageUrl);
    final metadata = hero.metadata.take(3).join('  •  ');

    return TvFocusable(
      onPressed: hero.onPrimary,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: focused
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.42),
              width: focused ? 1.8 : 1,
            ),
          ),
          child: Stack(
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
                      Color(0xF004080F),
                      Color(0xCC050A13),
                      Color(0x78050A13),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
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
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontSize: 28,
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
                    const SizedBox(height: 6),
                    Text(
                      hero.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.86),
                        height: 1.22,
                      ),
                    ),
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        metadata,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.84,
                              ),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_fill_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.82,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
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
      },
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

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 30 : 24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.44)),
      ),
      child: AspectRatio(
        aspectRatio: tvMode ? 16 / 3.9 : 16 / 9.8,
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
                ? (layout.isTvCompact ? 34.0 : 38.0)
                : (compactMobile ? 27.0 : 32.0);
            final metadataFontSize = tvMode
                ? 14.0
                : (compactMobile ? 13.0 : 14.0);
            final descriptionFontSize = tvMode
                ? 13.0
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
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.focused)) {
                        return const Color(0xFFFFF3E7);
                      }
                      if (states.contains(WidgetState.pressed)) {
                        return colorScheme.primary.withValues(alpha: 0.86);
                      }
                      return colorScheme.primary;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
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
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                  padding: EdgeInsets.all(
                    tvMode ? 16 : (compactMobile ? 14 : 16),
                  ),
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
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Colors.black,
                                letterSpacing: 0.9,
                                fontWeight: FontWeight.w900,
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
  });

  final String dedupeKey;
  final String title;
  final String subtitle;
  final double progress;
  final String remainingLabel;
  final String? imageUrl;
  final IconData icon;
  final VoidCallback onPressed;
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
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    section.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.76),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: layout.sectionSpacing),
        SizedBox(
          height: 244,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: section.items.length,
            separatorBuilder: (context, index) =>
                SizedBox(width: layout.cardSpacing),
            itemBuilder: (context, index) {
              return _ContinueWatchingRailCard(
                layout: layout,
                item: section.items[index],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContinueWatchingRailCard extends StatelessWidget {
  const _ContinueWatchingRailCard({required this.layout, required this.item});

  final DeviceLayout layout;
  final _ContinueWatchingData item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 214,
      child: TvFocusable(
        onPressed: item.onPressed,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: focused
                    ? [
                        colorScheme.primary.withValues(alpha: 0.22),
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.94,
                        ),
                      ]
                    : [
                        colorScheme.surface.withValues(alpha: 0.88),
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
                    : colorScheme.outline.withValues(alpha: 0.38),
                width: focused ? 1.8 : 1,
              ),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.16),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrandedArtwork(
                  imageUrl: item.imageUrl,
                  aspectRatio: 16 / 9,
                  placeholderLabel: 'Sem capa',
                  icon: item.icon,
                  borderRadius: 14,
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.78),
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Restando: ${item.remainingLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.76),
                    fontWeight: FontWeight.w600,
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
            fontSize: widget.layout.isTv ? 34 : 30,
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
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
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
      icon: Icons.movie_creation_outlined,
      badge: libraryKind == OnDemandLibraryKind.kids ? 'KIDS' : 'FILME',
      onPressed: () => context.push(VodDetailsScreen.buildLocation(item.id)),
      libraryKind: libraryKind,
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
      icon: Icons.tv_rounded,
      badge: isAnime ? 'ANIME' : 'SÉRIE',
      onPressed: () => context.push(SeriesDetailsScreen.buildLocation(item.id)),
      libraryKind: libraryKind,
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
  });

  final DeviceLayout layout;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onViewAll;
  final List<_HomeRailCardData> cards;
  final AsyncValue<dynamic> state;
  final bool collapseWhenEmptyOnTv;

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
    final sectionGap = layout.isTv
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
    final railHeight = _resolveRailHeight(
      layout,
      prefersLandscape: prefersLandscape,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: sectionIconSize,
              height: sectionIconSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  usePosterDominantMobileStyle ? 10 : 12,
                ),
                color: colorScheme.primary.withValues(
                  alpha: usePosterDominantMobileStyle ? 0.12 : 0.16,
                ),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: layout.isTv
                    ? 23
                    : usePosterDominantMobileStyle
                    ? 18
                    : 20,
              ),
            ),
            SizedBox(width: layout.isTv ? 12 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: layout.isTv
                          ? 27
                          : usePosterDominantMobileStyle
                          ? 21
                          : 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.76),
                      fontSize: layout.isTv ? 13.5 : 12,
                    ),
                  ),
                ],
              ),
            ),
            if (layout.isTv)
              _TvViewAllButton(onPressed: onViewAll)
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
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TvViewAllButton extends StatelessWidget {
  const _TvViewAllButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 158,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ver tudo',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: focused ? const Color(0xFF140B02) : null,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: focused ? const Color(0xFF140B02) : null,
                ),
              ],
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
}) {
  if (!layout.isTv && layout.deviceClass != DeviceClass.tablet) {
    return prefersLandscape ? 218 : 294;
  }
  if (prefersLandscape) {
    return layout.isTv ? 238 : 226;
  }
  return layout.isTv ? 368 : 304;
}

class _HomeRailCard extends StatelessWidget {
  const _HomeRailCard({
    required this.layout,
    required this.data,
    required this.autofocus,
  });

  final DeviceLayout layout;
  final _HomeRailCardData data;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscapeCard = data.aspectRatio >= 1.3;
    final usePosterDominantMobileStyle =
        !layout.isTv && layout.deviceClass != DeviceClass.tablet;
    final cardWidth = switch ((layout.isTv, isLandscapeCard)) {
      (true, true) => 320.0,
      (true, false) => 204.0,
      (false, true) => 236.0,
      (false, false) => 156.0,
    };
    final artworkAspectRatio = isLandscapeCard
        ? data.aspectRatio
        : layout.isTv
        ? 0.82
        : data.aspectRatio;

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
                                  fontSize: 13,
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
            padding: EdgeInsets.all(layout.isTv ? 9 : 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(layout.isTv ? 22 : 18),
              gradient: LinearGradient(
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
              border: Border.all(
                color: focused
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.5),
                width: focused ? 2.6 : 1,
              ),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.24),
                        blurRadius: 18,
                        offset: const Offset(0, 9),
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    BrandedArtwork(
                      imageUrl: data.imageUrl,
                      aspectRatio: artworkAspectRatio,
                      placeholderLabel: 'Imagem indisponivel',
                      icon: data.icon,
                      imagePadding: data.imagePadding,
                      fit: data.fit,
                      borderRadius: layout.isTv ? 16 : 14,
                    ),
                    if (isLandscapeCard)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              layout.isTv ? 16 : 14,
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
                                data.badge == 'LIVE' || data.badge == 'AO VIVO'
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
                                  letterSpacing: 0.7,
                                  fontWeight: FontWeight.w800,
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
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: layout.isTv ? 10 : 8),
                if (!isLandscapeCard)
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: layout.isTv ? 20 : 15,
                      fontWeight: FontWeight.w700,
                      height: 1.12,
                    ),
                  ),
                SizedBox(height: layout.isTv ? 5 : 4),
                if (layout.isTv && data.liveStreamId != null)
                  _LiveHomeEpgSubtitle(
                    streamId: data.liveStreamId!,
                    supportsEpg: data.supportsLiveEpg,
                    fallbackSubtitle: data.noEpgFallbackLabel,
                    defaultSubtitle: data.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.74),
                      fontSize: layout.isTv ? 13.5 : 11.5,
                      height: 1.3,
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
                      fontSize: layout.isTv ? 13.5 : 11.5,
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

    final epgAsync = ref.watch(liveShortEpgProvider(streamId));
    final resolved = epgAsync.when(
      data: (entries) {
        final state = _resolveHomeLiveEpgState(entries);
        if (state.current != null) {
          return 'Agora: ${state.current!.title}';
        }
        if (state.next != null) {
          return 'Prox: ${state.next!.title}';
        }
        return fallbackSubtitle;
      },
      loading: () => defaultSubtitle,
      error: (_, _) => fallbackSubtitle,
    );

    return Text(
      resolved,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
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

class _TvLiveHighlightPresentation {
  const _TvLiveHighlightPresentation({
    required this.statusLabel,
    required this.channelLabel,
    required this.headline,
    required this.footerLabel,
    this.scheduleLine,
    this.supportingLine,
    this.progress,
  });

  final String statusLabel;
  final String channelLabel;
  final String headline;
  final String footerLabel;
  final String? scheduleLine;
  final String? supportingLine;
  final double? progress;
}

_TvLiveHighlightPresentation _resolveTvLiveHighlightPresentation({
  required _HomeRailCardData data,
  required _HomeLiveEpgState epgState,
}) {
  final current = epgState.current;
  final next = epgState.next;

  if (current != null) {
    return _TvLiveHighlightPresentation(
      statusLabel: 'AGORA',
      channelLabel: data.title,
      headline: current.title,
      scheduleLine: _formatHomeTimeRange(current.startAt, current.endAt),
      supportingLine: next != null
          ? 'Depois ${_formatHomeClock(next.startAt)} • ${next.title}'
          : data.hasReplay
          ? 'Canal com replay disponivel'
          : 'Entre no canal para assistir agora',
      footerLabel: 'No ar neste momento',
      progress: _homeEpgProgress(current, now: DateTime.now()),
    );
  }

  if (next != null) {
    return _TvLiveHighlightPresentation(
      statusLabel: 'A SEGUIR',
      channelLabel: data.title,
      headline: next.title,
      scheduleLine: _formatHomeTimeRange(next.startAt, next.endAt),
      supportingLine: data.hasReplay
          ? 'Canal com replay disponivel'
          : 'Canal ao vivo agora',
      footerLabel: 'Abrir canal ao vivo',
    );
  }

  return _TvLiveHighlightPresentation(
    statusLabel: 'AO VIVO',
    channelLabel: data.title,
    headline: 'No ar agora',
    supportingLine: data.hasReplay
        ? 'Canal com replay disponivel'
        : 'Entre no canal para assistir agora',
    footerLabel: 'Canal ao vivo agora',
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

class _TvHighlightChip extends StatelessWidget {
  const _TvHighlightChip({
    required this.label,
    required this.color,
    required this.focused,
    this.emphasized = true,
  });

  final String label;
  final Color color;
  final bool focused;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final foreground = focused && emphasized
        ? const Color(0xFF1C1003)
        : color.computeLuminance() > 0.45
        ? const Color(0xFF1C1003)
        : Colors.white;
    final background = emphasized
        ? color.withValues(alpha: focused ? 0.92 : 0.82)
        : color.withValues(alpha: focused ? 0.24 : 0.16);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: emphasized ? foreground : color,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TvLiveChannelLogo extends StatelessWidget {
  const _TvLiveChannelLogo({
    required this.imageUrl,
    required this.channelLabel,
    required this.compact,
  });

  final String? imageUrl;
  final String channelLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = BrandedArtwork.normalizeArtworkUrl(imageUrl);
    final size = compact ? 92.0 : 102.0;
    final radius = compact ? 22.0 : 24.0;

    Widget fallback() => _TvLiveChannelLogoFallback(
      channelLabel: channelLabel,
      compact: compact,
    );

    if (normalizedUrl != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: EdgeInsets.all(compact ? 6 : 8),
          child: Image.network(
            normalizedUrl,
            fit: BoxFit.contain,
            headers: const {'Accept-Encoding': 'identity'},
            filterQuality: FilterQuality.high,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return fallback();
            },
            errorBuilder: (context, error, stackTrace) {
              return fallback();
            },
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: fallback(),
        ),
      ),
    );
  }
}

class _TvLiveChannelLogoFallback extends StatelessWidget {
  const _TvLiveChannelLogoFallback({
    required this.channelLabel,
    required this.compact,
  });

  final String channelLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final monogram = _buildChannelMonogram(channelLabel);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.tertiary.withValues(alpha: 0.06),
            colorScheme.surface.withValues(alpha: 0.88),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  monogram,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  'Canal',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _buildChannelMonogram(String channelLabel) {
  final cleaned = channelLabel
      .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ')
      .trim()
      .toUpperCase();
  if (cleaned.isEmpty) {
    return 'TV';
  }

  final tokens = cleaned
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList();
  if (tokens.isEmpty) {
    return 'TV';
  }

  final preferred = tokens.firstWhere(
    (token) => token.length >= 2,
    orElse: () => tokens.first,
  );
  if (preferred.length <= 4) {
    return preferred;
  }

  final initials = tokens.take(3).map((token) => token[0]).join();
  return initials.length >= 2 ? initials : preferred.substring(0, 3);
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

String _buildAccountCardDescription(XtreamSession session, String? expiresAt) {
  final parts = [
    DisplayFormatters.humanizeAccountStatus(session.accountStatus),
    if (expiresAt != null) 'Vence em $expiresAt',
  ];

  if (parts.isEmpty) {
    return 'Consulte os dados do acesso neste aparelho.';
  }

  return parts.join(' • ');
}
