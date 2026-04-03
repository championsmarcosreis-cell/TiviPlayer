import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/display_formatters.dart';
import '../../../core/tv/tv_focusable.dart';
import '../../../features/auth/domain/entities/xtream_session.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../features/auth/presentation/screens/account_screen.dart';
import '../../../features/live/domain/entities/live_epg_entry.dart';
import '../../../features/live/domain/entities/live_stream.dart';
import '../../../features/live/presentation/providers/live_providers.dart';
import '../../../features/live/presentation/screens/live_categories_screen.dart';
import '../../../features/live/presentation/support/live_playback_context.dart';
import '../../../features/player/domain/entities/playback_context.dart';
import '../../../features/player/domain/entities/playback_history_entry.dart';
import '../../../features/player/presentation/controllers/playback_history_controller.dart';
import '../../../features/player/presentation/screens/player_screen.dart';
import '../../../features/series/domain/entities/series_item.dart';
import '../../../features/series/presentation/providers/series_providers.dart';
import '../../../features/series/presentation/screens/series_categories_screen.dart';
import '../../../features/series/presentation/screens/series_details_screen.dart';
import '../../../features/vod/domain/entities/vod_stream.dart';
import '../../../features/vod/presentation/providers/vod_providers.dart';
import '../../../features/vod/presentation/screens/vod_categories_screen.dart';
import '../../../features/vod/presentation/screens/vod_details_screen.dart';
import '../../testing/app_test_keys.dart';
import '../layout/device_layout.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/branded_artwork.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/tv_stage.dart';

const _kHomeTvFocusColor = Color(0xFFAF7BFF);
const _kHomeTvFocusGlow = Color(0x66AF7BFF);
const _kHomeTvPanelBorderColor = Colors.transparent;
const _kHomeTvPanelGradient = [Color(0xFF1C1330), Color(0xFF151022)];
const _kHomeTvSurface = Color(0xFF211637);
const _kHomeTvSurfaceAlt = Color(0xFF191226);
const _kHomeTvSurfaceFocus = Color(0xFF342052);

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
    final playbackHistory = ref.watch(playbackHistoryControllerProvider);
    final expiresAt = DisplayFormatters.humanizeDate(session.expirationDate);

    final mobileTopActions = [
      _HomeQuickAction(
        title: 'Guia ao vivo',
        description: 'Abrir guia',
        icon: Icons.live_tv_rounded,
        interactiveKey: AppTestKeys.homeLiveCard,
        testId: AppTestKeys.homeLiveCardId,
        badge: 'LIVE',
        onTap: () =>
            _openPrimaryDestination(context, LiveCategoriesScreen.routePath),
      ),
      _HomeQuickAction(
        title: 'Filmes',
        description: 'Catalogo',
        icon: Icons.movie_creation_outlined,
        interactiveKey: AppTestKeys.homeMoviesCard,
        testId: AppTestKeys.homeMoviesCardId,
        onTap: () =>
            _openPrimaryDestination(context, VodCategoriesScreen.routePath),
      ),
      _HomeQuickAction(
        title: 'Series',
        description: 'Colecoes',
        icon: Icons.tv_rounded,
        interactiveKey: AppTestKeys.homeSeriesCard,
        testId: AppTestKeys.homeSeriesCardId,
        onTap: () =>
            _openPrimaryDestination(context, SeriesCategoriesScreen.routePath),
      ),
      _HomeQuickAction(
        title: 'Minha assinatura',
        description: DisplayFormatters.humanizeAccountStatus(
          session.accountStatus,
        ),
        icon: Icons.verified_user_rounded,
        interactiveKey: AppTestKeys.homeAccountCard,
        testId: AppTestKeys.homeAccountCardId,
        onTap: () => context.push(AccountScreen.routePath),
      ),
      _HomeQuickAction(
        title: 'Conta',
        description: 'Preferencias e dados da conta',
        icon: Icons.verified_user_rounded,
        interactiveKey: AppTestKeys.homeAccountAction,
        kind: _HomeQuickActionKind.utility,
        onTap: () => context.push(AccountScreen.routePath),
      ),
      _HomeQuickAction(
        title: 'Sair',
        description: 'Encerrar sessao neste aparelho',
        icon: Icons.logout_rounded,
        interactiveKey: AppTestKeys.homeLogoutButton,
        kind: _HomeQuickActionKind.utility,
        onTap: () => ref.read(authControllerProvider.notifier).logout(),
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
    final vodCards = _buildVodCards(resolvedVod, context);
    final seriesCards = _buildSeriesCards(resolvedSeries, context);
    final liveCards = _buildLiveCards(resolvedLive, context);
    final continueItem = _resolveContinueItem(playbackHistory, context);

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
        title: 'Inicio',
        subtitle: 'Sua central para ao vivo e catalogo sob demanda.',
        decoratedHeader: true,
        showBrand: true,
        actions: const [],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = DeviceLayout.of(context, constraints: constraints);
            final homeBody = _MobileHomeExperience(
              layout: layout,
              topActions: mobileTopActions,
              continueItem: continueItem,
              liveCards: liveCards,
              liveState: livePreview,
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
  });

  final String title;
  final String kicker;
  final String description;
  final String? imageUrl;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final List<String> metadata = const <String>[];
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

_ContinueWatchingData? _resolveContinueItem(
  List<PlaybackHistoryEntry> history,
  BuildContext context,
) {
  if (history.isEmpty) {
    return null;
  }

  final entry = history.first;
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
    title: entry.title,
    subtitle: '$typeLabel • Restando ${_formatRemaining(remaining)}',
    progress: progress,
    remainingLabel: _formatRemaining(remaining),
    imageUrl: entry.artworkUrl,
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

class _MobileHomeExperience extends StatelessWidget {
  const _MobileHomeExperience({
    required this.layout,
    required this.topActions,
    required this.continueItem,
    required this.liveCards,
    required this.liveState,
  });

  final DeviceLayout layout;
  final List<_HomeQuickAction> topActions;
  final _ContinueWatchingData? continueItem;
  final List<_HomeRailCardData> liveCards;
  final AsyncValue<dynamic> liveState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MobileTopActionStrip(layout: layout, actions: topActions),
        SizedBox(height: layout.sectionSpacing + 10),
        _HomeRailSection(
          layout: layout,
          title: 'No ar agora',
          subtitle: 'Entre pelo live com contexto do que esta acontecendo.',
          icon: Icons.live_tv_rounded,
          onViewAll: () =>
              _openPrimaryDestination(context, LiveCategoriesScreen.routePath),
          cards: liveCards,
          state: liveState,
        ),
        if (continueItem != null) ...[
          SizedBox(height: layout.sectionSpacing + 10),
          _ContinueWatchingCard(layout: layout, item: continueItem),
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

class _MobileTopActionStrip extends StatelessWidget {
  const _MobileTopActionStrip({required this.layout, required this.actions});

  final DeviceLayout layout;
  final List<_HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface.withValues(alpha: 0.84),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.34)),
      ),
      child: SizedBox(
        height: layout.width >= 720 ? 126 : 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: actions.length,
          separatorBuilder: (context, index) =>
              SizedBox(width: layout.cardSpacing - 2),
          itemBuilder: (context, index) {
            return _MobileTopActionCard(layout: layout, action: actions[index]);
          },
        ),
      ),
    );
  }
}

class _MobileTopActionCard extends StatelessWidget {
  const _MobileTopActionCard({required this.layout, required this.action});

  final DeviceLayout layout;
  final _HomeQuickAction action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUtility = action.kind == _HomeQuickActionKind.utility;
    final isLive = action.badge == 'LIVE';
    final accentColor = isLive ? colorScheme.secondary : colorScheme.primary;
    final cardWidth = isUtility
        ? (layout.width >= 720 ? 110.0 : 88.0)
        : (layout.width >= 720 ? 132.0 : 112.0);

    return SizedBox(
      width: cardWidth,
      child: TvFocusable(
        autofocus: false,
        interactiveKey: action.interactiveKey,
        testId: action.testId,
        onPressed: action.onTap,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: focused
                    ? [
                        const Color(0x22FF6A1A),
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.94,
                        ),
                      ]
                    : isLive
                    ? [
                        const Color(0x2221C7FF),
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.9,
                        ),
                      ]
                    : isUtility
                    ? [
                        colorScheme.surface.withValues(alpha: 0.72),
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.62,
                        ),
                      ]
                    : [
                        colorScheme.surface.withValues(alpha: 0.84),
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.72,
                        ),
                      ],
              ),
              border: Border.all(
                color: focused
                    ? colorScheme.primary
                    : isLive
                    ? colorScheme.secondary.withValues(alpha: 0.44)
                    : isUtility
                    ? colorScheme.outline.withValues(alpha: 0.34)
                    : colorScheme.outline.withValues(alpha: 0.42),
                width: focused ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isUtility ? 28 : 32,
                      height: isUtility ? 28 : 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: accentColor.withValues(alpha: 0.16),
                      ),
                      child: Icon(
                        action.icon,
                        size: isUtility ? 15 : 17,
                        color: accentColor,
                      ),
                    ),
                    const Spacer(),
                    if (action.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: accentColor.withValues(alpha: 0.16),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Text(
                          action.badge!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                letterSpacing: 0.7,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  action.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: isUtility ? 13 : 15,
                    fontWeight: FontWeight.w700,
                    height: 1.08,
                  ),
                ),
                if (!isUtility) ...[
                  const SizedBox(height: 4),
                  Text(
                    action.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.74),
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
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

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 30 : 24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.44)),
      ),
      child: AspectRatio(
        aspectRatio: tvMode ? 16 / 3.9 : 16 / 12,
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
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.remainingLabel,
    required this.icon,
    required this.onPressed,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final double progress;
  final String remainingLabel;
  final String? imageUrl;
  final IconData icon;
  final VoidCallback onPressed;
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
    final headerSize = useCompactTvVariant ? 24.0 : 30.0;
    final artworkWidth = useCompactTvVariant
        ? 148.0
        : (layout.isTv ? 180.0 : 150.0);
    final titleSize = useCompactTvVariant ? 23.0 : (layout.isTv ? 28.0 : 26.0);
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
    this.kind = _HomeQuickActionKind.primary,
    this.badge,
    this.interactiveKey,
    this.testId,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final _HomeQuickActionKind kind;
  final String? badge;
  final Key? interactiveKey;
  final String? testId;
}

enum _HomeQuickActionKind { primary, utility }

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
}

List<_HomeRailCardData> _buildVodCards(
  List<VodStream>? items,
  BuildContext context,
) {
  if (items == null || items.isEmpty) {
    return const [];
  }

  return items.take(14).map((item) {
    final subtitle = item.rating?.trim().isNotEmpty == true
        ? 'Nota ${item.rating}'
        : 'Filme';
    return _HomeRailCardData(
      title: item.name,
      subtitle: subtitle,
      imageUrl: item.coverUrl,
      icon: Icons.movie_creation_outlined,
      badge: item.rating?.trim().isNotEmpty == true ? 'HD' : null,
      onPressed: () => context.push(VodDetailsScreen.buildLocation(item.id)),
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
    return _HomeRailCardData(
      title: item.name,
      subtitle: item.plot?.trim().isNotEmpty == true ? item.plot! : 'Serie',
      imageUrl: item.coverUrl,
      icon: Icons.tv_rounded,
      onPressed: () => context.push(SeriesDetailsScreen.buildLocation(item.id)),
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

  return visibleItems.asMap().entries.map((entry) {
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
      onPressed: () => context.push(
        PlayerScreen.routePath,
        extra: buildLivePlaybackContext(visibleItems, index),
      ),
    );
  }).toList();
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
              width: layout.isTv ? 40 : 36,
              height: layout.isTv ? 40 : 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.primary.withValues(alpha: 0.16),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: layout.isTv ? 23 : 20,
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
                      fontSize: layout.isTv ? 27 : 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.76),
                      fontSize: layout.isTv ? 13.5 : 12.5,
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
        SizedBox(
          height: layout.isTv
              ? (layout.sectionSpacing - 2).clamp(0, 999).toDouble()
              : layout.sectionSpacing,
        ),
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
                  SizedBox(width: layout.cardSpacing),
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
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: data.badge == 'LIVE'
                                ? const Color(0xCCFF4A57)
                                : Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            data.badge!,
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
