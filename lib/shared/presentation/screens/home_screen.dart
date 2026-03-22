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

    return AppScaffold(
      title: 'Inicio',
      subtitle: 'TV, filmes e series em um fluxo unico.',
      decoratedHeader: false,
      actions: [
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
      ],
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
          final continueItem = vodCards.isNotEmpty
              ? vodCards.first
              : (seriesCards.isNotEmpty ? seriesCards.first : null);

          final homeBody = layout.isTv
              ? _TvHomeExperience(
                  layout: layout,
                  hero: hero,
                  quickActions: quickActions,
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

class _TvHomeExperience extends StatelessWidget {
  const _TvHomeExperience({
    required this.layout,
    required this.hero,
    required this.quickActions,
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
        _TvHubTabs(layout: layout, actions: quickActions),
        SizedBox(height: layout.sectionSpacing + 8),
        _CinematicHeroCard(layout: layout, hero: hero, tvMode: true),
        SizedBox(height: layout.sectionSpacing + 14),
        _HomeRailSection(
          layout: layout,
          title: 'TV ao vivo em destaque',
          subtitle: 'Canais ativos e favoritos do momento.',
          icon: Icons.live_tv_rounded,
          onViewAll: () => context.go(LiveCategoriesScreen.routePath),
          cards: liveCards,
          state: liveState,
        ),
        SizedBox(height: layout.sectionSpacing + 12),
        _HomeRailSection(
          layout: layout,
          title: 'Filmes para assistir agora',
          subtitle: 'VOD com maior potencial de clique rapido.',
          icon: Icons.local_movies_rounded,
          onViewAll: () => context.go(VodCategoriesScreen.routePath),
          cards: vodCards,
          state: vodState,
        ),
        SizedBox(height: layout.sectionSpacing + 12),
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
  final _HomeRailCardData? continueItem;
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
        _CategoryChipRail(layout: layout, categories: categories),
        SizedBox(height: layout.sectionSpacing + 10),
        _MobileHubPills(layout: layout, actions: quickActions),
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

class _TvHubTabs extends StatelessWidget {
  const _TvHubTabs({required this.layout, required this.actions});

  final DeviceLayout layout;
  final List<_HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final visibleActions = actions.take(4).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(layout.isTv ? 12 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 20 : 16),
        color: colorScheme.surface.withValues(alpha: 0.7),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.36)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < visibleActions.length; index++) ...[
            Expanded(
              child: _HubActionPill(
                action: visibleActions[index],
                autofocus: index == 0,
                layout: layout,
                showDescription: false,
              ),
            ),
            if (index != visibleActions.length - 1)
              SizedBox(width: layout.cardSpacing - 4),
          ],
        ],
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
        aspectRatio: tvMode ? 16 / 6.5 : 16 / 12,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactMobile = !tvMode && constraints.maxHeight < 260;
            final metadata = hero.metadata
                .take(tvMode ? 3 : (compactMobile ? 1 : 2))
                .toList();
            final titleFontSize = tvMode ? 48.0 : (compactMobile ? 32.0 : 36.0);
            final metadataFontSize = tvMode
                ? 27.0
                : (compactMobile ? 16.0 : 18.0);

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
                    tvMode ? 28 : (compactMobile ? 14 : 16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
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
                      SizedBox(height: tvMode ? 14 : (compactMobile ? 8 : 10)),
                      Text(
                        hero.title,
                        maxLines: tvMode ? 2 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontSize: titleFontSize,
                              height: 0.98,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (metadata.isNotEmpty) ...[
                        SizedBox(height: tvMode ? 12 : (compactMobile ? 6 : 8)),
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
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                      SizedBox(height: tvMode ? 16 : (compactMobile ? 10 : 12)),
                      Wrap(
                        spacing: compactMobile ? 10 : 12,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
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

class _ContinueWatchingCard extends StatelessWidget {
  const _ContinueWatchingCard({required this.layout, required this.item});

  final DeviceLayout layout;
  final _HomeRailCardData? item;

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
          ).textTheme.headlineSmall?.copyWith(fontSize: layout.isTv ? 34 : 30),
        ),
        SizedBox(height: layout.sectionSpacing - 2),
        Container(
          padding: EdgeInsets.all(layout.isTv ? 16 : 12),
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
          child: item == null
              ? Text(
                  'Nenhum titulo em andamento neste momento.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : Row(
                  children: [
                    SizedBox(
                      width: layout.isTv ? 210 : 150,
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
                                ?.copyWith(fontSize: layout.isTv ? 34 : 26),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: 0.62,
                              minHeight: layout.isTv ? 10 : 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Restando: 24min',
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
                      size: layout.isTv ? 44 : 36,
                      color: colorScheme.onSurface.withValues(alpha: 0.56),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CategoryChipRail extends StatelessWidget {
  const _CategoryChipRail({required this.layout, required this.categories});

  final DeviceLayout layout;
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorias',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontSize: layout.isTv ? 34 : 30),
        ),
        SizedBox(height: layout.sectionSpacing - 2),
        SizedBox(
          height: layout.isTv ? 58 : 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) =>
                SizedBox(width: layout.cardSpacing - 4),
            itemBuilder: (context, index) {
              final selected = index == 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: selected
                      ? LinearGradient(
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.45),
                            colorScheme.secondary.withValues(alpha: 0.2),
                          ],
                        )
                      : null,
                  color: selected
                      ? null
                      : colorScheme.surface.withValues(alpha: 0.55),
                  border: Border.all(
                    color: selected
                        ? colorScheme.primary.withValues(alpha: 0.7)
                        : colorScheme.outline.withValues(alpha: 0.35),
                  ),
                ),
                child: Center(
                  child: Text(
                    categories[index],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withValues(alpha: 0.88),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
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
      aspectRatio: 1,
      imagePadding: const EdgeInsets.all(16),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: layout.isTv ? 44 : 36,
              height: layout.isTv ? 44 : 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.primary.withValues(alpha: 0.16),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: layout.isTv ? 25 : 20,
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
                      fontSize: layout.isTv ? 30 : 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.76),
                      fontSize: layout.isTv ? 14 : 12.5,
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
          _RailPlaceholder(layout: layout)
        else if (hasError)
          _RailErrorCard(layout: layout, onPressed: onViewAll)
        else if (cards.isEmpty)
          _RailEmptyCard(layout: layout, onPressed: onViewAll)
        else
          SizedBox(
            height: layout.isTv ? 314 : 278,
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
    final cardWidth = layout.isTv ? 188.0 : 146.0;
    final artworkAspectRatio = data.aspectRatio == 1
        ? 1.0
        : layout.isTv
        ? 0.82
        : 1.12;

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
              color: colorScheme.surface.withValues(alpha: 0.9),
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
                  ],
                ),
                SizedBox(height: layout.isTv ? 10 : 8),
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
                  maxLines: layout.isTv ? 2 : 1,
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
  const _RailPlaceholder({required this.layout});

  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: layout.isTv ? 314 : 278,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: layout.isTv ? 6 : 4,
        separatorBuilder: (context, index) =>
            SizedBox(width: layout.cardSpacing),
        itemBuilder: (context, index) {
          return Container(
            width: layout.isTv ? 188 : 146,
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
