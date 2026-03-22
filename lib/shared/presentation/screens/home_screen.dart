import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/display_formatters.dart';
import '../../../core/tv/tv_focusable.dart';
import '../../../features/auth/domain/entities/xtream_session.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../features/auth/presentation/screens/account_screen.dart';
import '../../../features/live/domain/entities/live_stream.dart';
import '../../../features/live/presentation/providers/live_providers.dart';
import '../../../features/live/presentation/screens/live_categories_screen.dart';
import '../../../features/player/domain/entities/playback_context.dart';
import '../../../features/player/domain/entities/playback_history_entry.dart';
import '../../../features/player/presentation/controllers/playback_history_controller.dart';
import '../../../features/player/presentation/screens/player_screen.dart';
import '../../../features/series/domain/entities/series_item.dart';
import '../../../features/series/presentation/providers/series_providers.dart';
import '../../../features/series/presentation/screens/series_categories_screen.dart';
import '../../../features/series/presentation/screens/series_details_screen.dart';
import '../../../features/vod/domain/entities/vod_category.dart';
import '../../../features/vod/domain/entities/vod_stream.dart';
import '../../../features/vod/presentation/providers/vod_providers.dart';
import '../../../features/vod/presentation/screens/vod_categories_screen.dart';
import '../../../features/vod/presentation/screens/vod_details_screen.dart';
import '../../testing/app_test_keys.dart';
import '../layout/device_layout.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/branded_artwork.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerLayout = DeviceLayout.of(context);
    final session = ref.watch(currentSessionProvider);
    if (session == null) {
      return const AppScaffold(
        title: 'Inicio',
        subtitle: 'Preparando seu painel de conteudo.',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final livePreview = ref.watch(liveStreamsProvider(null));
    final vodPreview = ref.watch(vodStreamsProvider(null));
    final seriesPreview = ref.watch(seriesItemsProvider(null));
    final vodCategories = ref.watch(vodCategoriesProvider);
    final playbackHistory = ref.watch(playbackHistoryControllerProvider);
    final expiresAt = DisplayFormatters.humanizeDate(session.expirationDate);

    final hero = _resolveHero(
      _asyncDataOrNull(vodPreview),
      _asyncDataOrNull(seriesPreview),
      _asyncDataOrNull(livePreview),
      context,
    );

    final quickActions = [
      _HomeQuickAction(
        title: 'Ao vivo',
        description: 'Abrir canais e grade em tempo real',
        icon: Icons.live_tv_rounded,
        interactiveKey: AppTestKeys.homeLiveCard,
        testId: AppTestKeys.homeLiveCardId,
        badge: 'LIVE',
        onTap: () => context.go(LiveCategoriesScreen.routePath),
      ),
      _HomeQuickAction(
        title: 'Filmes',
        description: 'Catalogo sob demanda para assistir agora',
        icon: Icons.movie_creation_outlined,
        interactiveKey: AppTestKeys.homeMoviesCard,
        testId: AppTestKeys.homeMoviesCardId,
        onTap: () => context.go(VodCategoriesScreen.routePath),
      ),
      _HomeQuickAction(
        title: 'Series',
        description: 'Temporadas e colecoes em destaque',
        icon: Icons.tv_rounded,
        interactiveKey: AppTestKeys.homeSeriesCard,
        testId: AppTestKeys.homeSeriesCardId,
        onTap: () => context.go(SeriesCategoriesScreen.routePath),
      ),
      _HomeQuickAction(
        title: 'Minha assinatura',
        description: _buildAccountCardDescription(session, expiresAt),
        icon: Icons.verified_user_rounded,
        interactiveKey: AppTestKeys.homeAccountCard,
        testId: AppTestKeys.homeAccountCardId,
        onTap: () => context.push(AccountScreen.routePath),
      ),
    ];

    final headerActions = <Widget>[
      FilledButton.tonalIcon(
        key: AppTestKeys.homeAccountAction,
        onPressed: () => context.push(AccountScreen.routePath),
        icon: const Icon(Icons.verified_user_rounded),
        label: const Text('Conta'),
      ),
      FilledButton.tonalIcon(
        key: AppTestKeys.homeLogoutButton,
        onPressed: () => ref.read(authControllerProvider.notifier).logout(),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sair'),
      ),
    ];

    final tvNavigationItems = <_TvNavigationItem>[
      _TvNavigationItem(
        label: 'Inicio',
        icon: Icons.home_rounded,
        isCurrent: true,
        onTap: () {},
      ),
      _TvNavigationItem(
        label: 'TV ao vivo',
        icon: Icons.live_tv_rounded,
        onTap: () => context.go(LiveCategoriesScreen.routePath),
      ),
      _TvNavigationItem(
        label: 'Filmes',
        icon: Icons.movie_creation_outlined,
        onTap: () => context.go(VodCategoriesScreen.routePath),
      ),
      _TvNavigationItem(
        label: 'Series',
        icon: Icons.tv_rounded,
        onTap: () => context.go(SeriesCategoriesScreen.routePath),
      ),
      _TvNavigationItem(
        label: 'Conta',
        icon: Icons.verified_user_rounded,
        onTap: () => context.push(AccountScreen.routePath),
      ),
      _TvNavigationItem(
        label: 'Sair',
        icon: Icons.logout_rounded,
        onTap: () => ref.read(authControllerProvider.notifier).logout(),
      ),
    ];

    return AppScaffold(
      title: 'Inicio',
      subtitle: 'TV, filmes e series em um fluxo unico.',
      decoratedHeader: false,
      actions: headerLayout.isTv ? const [] : headerActions,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = DeviceLayout.of(context, constraints: constraints);
          final resolvedVod = _asyncDataOrNull(vodPreview);
          final resolvedSeries = _asyncDataOrNull(seriesPreview);
          final resolvedLive = _asyncDataOrNull(livePreview);
          final categories = _resolveCategoryChips(
            _asyncDataOrNull(vodCategories),
          );

          final vodCards = _buildVodCards(resolvedVod, context);
          final seriesCards = _buildSeriesCards(resolvedSeries, context);
          final liveCards = _buildLiveCards(resolvedLive, context);
          final continueItem = _resolveContinueItem(playbackHistory, context);

          final homeBody = layout.isTv
              ? _TvHomeExperience(
                  layout: layout,
                  hero: hero,
                  navItems: tvNavigationItems,
                  continueItem: continueItem,
                  liveCards: liveCards,
                  vodCards: vodCards,
                  seriesCards: seriesCards,
                  liveState: livePreview,
                  vodState: vodPreview,
                  seriesState: seriesPreview,
                )
              : _MobileHomeExperience(
                  layout: layout,
                  hero: hero,
                  quickActions: quickActions,
                  categories: categories,
                  continueItem: continueItem,
                  liveCards: liveCards,
                  vodCards: vodCards,
                  seriesCards: seriesCards,
                  liveState: livePreview,
                  vodState: vodPreview,
                  seriesState: seriesPreview,
                );

          return Scrollbar(
            thumbVisibility: layout.isTv,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
              child: homeBody,
            ),
          );
        },
      ),
    );
  }
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

T? _asyncDataOrNull<T>(AsyncValue<T> value) {
  return value.when(
    data: (data) => data,
    loading: () => null,
    error: (_, _) => null,
  );
}

_HomeHeroChoice _resolveHero(
  List<VodStream>? vodItems,
  List<SeriesItem>? seriesItems,
  List<LiveStream>? liveItems,
  BuildContext context,
) {
  if (vodItems != null && vodItems.isNotEmpty) {
    final topVod = vodItems.firstWhere(
      (item) => BrandedArtwork.normalizeArtworkUrl(item.coverUrl) != null,
      orElse: () => vodItems.first,
    );
    return _HomeHeroChoice(
      title: topVod.name,
      kicker: 'Filme em destaque',
      description:
          'Abra o titulo principal da home ou explore o catalogo completo.',
      imageUrl: topVod.coverUrl,
      primaryLabel: 'Assistir agora',
      secondaryLabel: 'Ver filmes',
      onPrimary: () => context.push(VodDetailsScreen.buildLocation(topVod.id)),
      onSecondary: () => context.go(VodCategoriesScreen.routePath),
      metadata: [
        'VOD',
        if (topVod.rating?.trim().isNotEmpty == true) 'Nota ${topVod.rating}',
      ],
    );
  }

  if (seriesItems != null && seriesItems.isNotEmpty) {
    final topSeries = seriesItems.firstWhere(
      (item) => BrandedArtwork.normalizeArtworkUrl(item.coverUrl) != null,
      orElse: () => seriesItems.first,
    );
    return _HomeHeroChoice(
      title: topSeries.name,
      kicker: 'Serie sugerida',
      description: 'Entre direto no detalhe da serie em destaque.',
      imageUrl: topSeries.coverUrl,
      primaryLabel: 'Abrir detalhe',
      secondaryLabel: 'Ver series',
      onPrimary: () =>
          context.push(SeriesDetailsScreen.buildLocation(topSeries.id)),
      onSecondary: () => context.go(SeriesCategoriesScreen.routePath),
      metadata: const ['SERIES'],
    );
  }

  if (liveItems != null && liveItems.isNotEmpty) {
    final topLive = liveItems.first;
    return _HomeHeroChoice(
      title: topLive.name,
      kicker: 'Canal ao vivo',
      description: 'Entre no player ao vivo ou abra todas as categorias.',
      imageUrl: topLive.iconUrl,
      primaryLabel: 'Assistir canal',
      secondaryLabel: 'Ver canais',
      onPrimary: () => context.push(
        PlayerScreen.routePath,
        extra: PlaybackContext(
          contentType: PlaybackContentType.live,
          itemId: topLive.id,
          title: topLive.name,
          containerExtension: topLive.containerExtension,
        ),
      ),
      onSecondary: () => context.go(LiveCategoriesScreen.routePath),
      metadata: ['LIVE', if (topLive.hasArchive) 'Com replay'],
    );
  }

  return _HomeHeroChoice(
    title: 'Escolha algo para assistir',
    kicker: 'Catalogo pronto',
    description:
        'A home foi preparada para filmes, series, canais ao vivo e novos tipos de colecao.',
    imageUrl: null,
    primaryLabel: 'Explorar filmes',
    secondaryLabel: 'Abrir canais',
    onPrimary: () => context.go(VodCategoriesScreen.routePath),
    onSecondary: () => context.go(LiveCategoriesScreen.routePath),
    metadata: const ['TV-FIRST'],
  );
}

List<String> _resolveCategoryChips(List<VodCategory>? categories) {
  final names = categories
      ?.map((item) => item.name.trim())
      .where((name) => name.isNotEmpty)
      .toList();

  if (names == null || names.isEmpty) {
    return const [
      'Acao',
      'Animes',
      'Novelas',
      'Infantil',
      'Series',
      'Documentarios',
    ];
  }

  return names.take(10).toList();
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

class _TvHomeExperience extends StatelessWidget {
  const _TvHomeExperience({
    required this.layout,
    required this.hero,
    required this.navItems,
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
  final List<_TvNavigationItem> navItems;
  final _ContinueWatchingData? continueItem;
  final List<_HomeRailCardData> liveCards;
  final List<_HomeRailCardData> vodCards;
  final List<_HomeRailCardData> seriesCards;
  final AsyncValue<dynamic> liveState;
  final AsyncValue<dynamic> vodState;
  final AsyncValue<dynamic> seriesState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TvTopNavigationBar(layout: layout, items: navItems),
        SizedBox(height: layout.sectionSpacing + 4),
        _CinematicHeroCard(layout: layout, hero: hero, tvMode: true),
        SizedBox(height: layout.sectionSpacing + 8),
        _HomeRailSection(
          layout: layout,
          title: 'TV ao vivo em destaque',
          subtitle: 'Canais ativos e favoritos do momento.',
          icon: Icons.live_tv_rounded,
          onViewAll: () => context.go(LiveCategoriesScreen.routePath),
          cards: liveCards,
          state: liveState,
        ),
        SizedBox(height: layout.sectionSpacing + 10),
        _ContinueWatchingCard(layout: layout, item: continueItem),
        SizedBox(height: layout.sectionSpacing + 10),
        _HomeRailSection(
          layout: layout,
          title: 'Filmes para assistir agora',
          subtitle: 'VOD com maior potencial de clique rapido.',
          icon: Icons.local_movies_rounded,
          onViewAll: () => context.go(VodCategoriesScreen.routePath),
          cards: vodCards,
          state: vodState,
        ),
        SizedBox(height: layout.sectionSpacing + 10),
        _HomeRailSection(
          layout: layout,
          title: 'Series em alta',
          subtitle: 'Temporadas e colecoes para maratona.',
          icon: Icons.tv_rounded,
          onViewAll: () => context.go(SeriesCategoriesScreen.routePath),
          cards: seriesCards,
          state: seriesState,
        ),
      ],
    );
  }
}

class _MobileHomeExperience extends StatelessWidget {
  const _MobileHomeExperience({
    required this.layout,
    required this.hero,
    required this.quickActions,
    required this.categories,
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
  final List<_HomeQuickAction> quickActions;
  final List<String> categories;
  final _ContinueWatchingData? continueItem;
  final List<_HomeRailCardData> liveCards;
  final List<_HomeRailCardData> vodCards;
  final List<_HomeRailCardData> seriesCards;
  final AsyncValue<dynamic> liveState;
  final AsyncValue<dynamic> vodState;
  final AsyncValue<dynamic> seriesState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CinematicHeroCard(layout: layout, hero: hero, tvMode: false),
        SizedBox(height: layout.sectionSpacing + 10),
        _HomeRailSection(
          layout: layout,
          title: 'TV ao vivo em destaque',
          subtitle: 'Canais ativos com acesso rapido.',
          icon: Icons.live_tv_rounded,
          onViewAll: () => context.go(LiveCategoriesScreen.routePath),
          cards: liveCards,
          state: liveState,
        ),
        SizedBox(height: layout.sectionSpacing + 10),
        _ContinueWatchingCard(layout: layout, item: continueItem),
        SizedBox(height: layout.sectionSpacing + 10),
        _MobileHubPills(layout: layout, actions: quickActions),
        SizedBox(height: layout.sectionSpacing + 10),
        _CategoryChipRail(layout: layout, categories: categories),
        SizedBox(height: layout.sectionSpacing + 14),
        _HomeRailSection(
          layout: layout,
          title: 'Populares',
          subtitle: 'Titulos mais fortes do catalogo.',
          icon: Icons.trending_up_rounded,
          onViewAll: () => context.go(VodCategoriesScreen.routePath),
          cards: vodCards,
          state: vodState,
        ),
        SizedBox(height: layout.sectionSpacing + 10),
        _HomeRailSection(
          layout: layout,
          title: 'Adicionados recentemente',
          subtitle: 'Novas entradas para explorar hoje.',
          icon: Icons.new_releases_rounded,
          onViewAll: () => context.go(SeriesCategoriesScreen.routePath),
          cards: seriesCards,
          state: seriesState,
        ),
      ],
    );
  }
}

class _TvNavigationItem {
  const _TvNavigationItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isCurrent = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isCurrent;
}

class _TvTopNavigationBar extends StatelessWidget {
  const _TvTopNavigationBar({required this.layout, required this.items});

  final DeviceLayout layout;
  final List<_TvNavigationItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colorScheme.surface.withValues(alpha: 0.68),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.34)),
      ),
      child: SizedBox(
        height: 58,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            return _TvTopNavigationButton(
              item: item,
              layout: layout,
              autofocus: index == 0,
            );
          },
        ),
      ),
    );
  }
}

class _TvTopNavigationButton extends StatelessWidget {
  const _TvTopNavigationButton({
    required this.item,
    required this.layout,
    required this.autofocus,
  });

  final _TvNavigationItem item;
  final DeviceLayout layout;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: layout.isTvCompact ? 170 : 184,
      child: TvFocusable(
        autofocus: autofocus,
        onPressed: item.onTap,
        builder: (context, focused) {
          final current = item.isCurrent;
          final active = focused;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: active
                  ? LinearGradient(
                      colors: [
                        const Color(0xFFFFF3E7),
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.9,
                        ),
                      ],
                    )
                  : current
                  ? LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.2),
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.82,
                        ),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        colorScheme.surface.withValues(alpha: 0.84),
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.72,
                        ),
                      ],
                    ),
              border: Border.all(
                color: active
                    ? colorScheme.secondary
                    : current
                    ? colorScheme.primary.withValues(alpha: 0.72)
                    : colorScheme.outline.withValues(alpha: 0.4),
                width: active ? 2.6 : 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: colorScheme.secondary.withValues(alpha: 0.24),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 21,
                  color: active ? const Color(0xFF161005) : null,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: active ? const Color(0xFF161005) : null,
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

class _MobileHubPills extends StatelessWidget {
  const _MobileHubPills({required this.layout, required this.actions});

  final DeviceLayout layout;
  final List<_HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: layout.isTv ? 128 : 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (context, index) =>
            SizedBox(width: layout.cardSpacing),
        itemBuilder: (context, index) {
          return SizedBox(
            width: layout.isTv ? 280 : 220,
            child: _HubActionPill(
              action: actions[index],
              autofocus: index == 0,
              layout: layout,
              showDescription: true,
            ),
          );
        },
      ),
    );
  }
}

class _HubActionPill extends StatelessWidget {
  const _HubActionPill({
    required this.action,
    required this.autofocus,
    required this.layout,
    required this.showDescription,
  });

  final _HomeQuickAction action;
  final bool autofocus;
  final DeviceLayout layout;
  final bool showDescription;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusable(
      autofocus: autofocus,
      interactiveKey: action.interactiveKey,
      testId: action.testId,
      onPressed: action.onTap,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.symmetric(
            horizontal: layout.isTv ? 14 : 12,
            vertical: layout.isTv ? 12 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.isTv ? 16 : 14),
            gradient: LinearGradient(
              colors: focused
                  ? [
                      colorScheme.primary.withValues(alpha: 0.26),
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.94,
                      ),
                    ]
                  : [
                      colorScheme.surface.withValues(alpha: 0.86),
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.7,
                      ),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: focused
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.46),
              width: focused ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(action.icon, size: layout.isTv ? 22 : 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: layout.isTv ? 20 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showDescription) ...[
                      const SizedBox(height: 4),
                      Text(
                        action.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.74),
                        ),
                      ),
                    ],
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
        aspectRatio: tvMode ? 16 / 4.2 : 16 / 12,
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
            final titleFontSize = tvMode ? 34.0 : (compactMobile ? 27.0 : 32.0);
            final metadataFontSize = tvMode
                ? 14.0
                : (compactMobile ? 13.0 : 14.0);
            final descriptionFontSize = tvMode
                ? 13.5
                : (compactMobile ? 11.8 : 12.6);
            final actionStyle = tvMode
                ? ButtonStyle(
                    minimumSize: const WidgetStatePropertyAll(Size(0, 56)),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                          width: 3,
                        );
                      }
                      return BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.9),
                      );
                    }),
                    elevation: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.focused) ? 11 : 2;
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
                  Container(color: colorScheme.surfaceContainerHighest),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xEE060A13),
                        Color(0xB2060A13),
                        Color(0x55060A13),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(
                    tvMode ? 20 : (compactMobile ? 14 : 16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tvMode) const Spacer(),
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
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      SizedBox(height: tvMode ? 10 : (compactMobile ? 6 : 8)),
                      Text(
                        hero.title,
                        maxLines: tvMode ? 2 : (veryCompactMobile ? 2 : 3),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontSize: titleFontSize,
                              height: veryCompactMobile ? 1.02 : 0.99,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (showDescription) ...[
                        SizedBox(height: tvMode ? 6 : 6),
                        Text(
                          hero.description,
                          maxLines: veryCompactMobile ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: descriptionFontSize,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                        ),
                      ],
                      if (metadata.isNotEmpty) ...[
                        SizedBox(height: tvMode ? 8 : (compactMobile ? 5 : 7)),
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
                      SizedBox(height: tvMode ? 10 : (compactMobile ? 8 : 10)),
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
                          if (tvMode)
                            OutlinedButton.icon(
                              onPressed: hero.onSecondary,
                              icon: const Icon(Icons.grid_view_rounded),
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
  const _ContinueWatchingCard({required this.layout, required this.item});

  final DeviceLayout layout;
  final _ContinueWatchingData? item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Continuar assistindo',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontSize: layout.isTv ? 30 : 30),
        ),
        SizedBox(height: layout.sectionSpacing - 2),
        if (item == null)
          Container(
            padding: EdgeInsets.all(layout.isTv ? 14 : 12),
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
                padding: EdgeInsets.all(layout.isTv ? 14 : 12),
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
                      width: layout.isTv ? 180 : 150,
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
                                ?.copyWith(fontSize: layout.isTv ? 28 : 26),
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
                              minHeight: layout.isTv ? 9 : 8,
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
                      size: layout.isTv ? 40 : 36,
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

  return items.take(16).map((item) {
    return _HomeRailCardData(
      title: item.name,
      subtitle: item.hasArchive ? 'Replay disponivel' : 'Canal ao vivo',
      imageUrl: item.iconUrl,
      icon: Icons.live_tv_rounded,
      badge: 'LIVE',
      aspectRatio: 16 / 9,
      imagePadding: const EdgeInsets.all(18),
      fit: BoxFit.contain,
      onPressed: () => context.push(
        PlayerScreen.routePath,
        extra: PlaybackContext(
          contentType: PlaybackContentType.live,
          itemId: item.id,
          title: item.name,
          containerExtension: item.containerExtension,
        ),
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
  });

  final DeviceLayout layout;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onViewAll;
  final List<_HomeRailCardData> cards;
  final AsyncValue<dynamic> state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = state.isLoading && cards.isEmpty;
    final hasError = state.hasError && cards.isEmpty;
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
                      fontSize: layout.isTv ? 26 : 23,
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
            TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Ver tudo'),
            ),
          ],
        ),
        SizedBox(height: layout.sectionSpacing),
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

double _resolveRailHeight(
  DeviceLayout layout, {
  required bool prefersLandscape,
}) {
  if (prefersLandscape) {
    return layout.isTv ? 226 : 226;
  }
  return layout.isTv ? 352 : 304;
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
      (true, true) => 296.0,
      (true, false) => 188.0,
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
                        colorScheme.primary.withValues(alpha: 0.22),
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.92,
                        ),
                      ]
                    : [
                        colorScheme.surface.withValues(alpha: 0.9),
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.74,
                        ),
                      ],
              ),
              border: Border.all(
                color: focused
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.5),
                width: focused ? 2 : 1,
              ),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
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
                      fontSize: layout.isTv ? 18 : 15,
                      fontWeight: FontWeight.w700,
                      height: 1.12,
                    ),
                  ),
                SizedBox(height: layout.isTv ? 5 : 4),
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
      (true, true) => 296.0,
      (true, false) => 188.0,
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
