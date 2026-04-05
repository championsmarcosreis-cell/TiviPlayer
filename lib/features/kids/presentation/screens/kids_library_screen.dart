import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/series/domain/entities/series_category.dart';
import '../../../../features/series/domain/entities/series_item.dart';
import '../../../../features/series/presentation/providers/series_providers.dart';
import '../../../../features/series/presentation/screens/series_details_screen.dart';
import '../../../../features/series/presentation/screens/series_items_screen.dart';
import '../../../../features/vod/domain/entities/vod_category.dart';
import '../../../../features/vod/domain/entities/vod_stream.dart';
import '../../../../features/vod/presentation/providers/vod_providers.dart';
import '../../../../features/vod/presentation/screens/vod_details_screen.dart';
import '../../../../features/vod/presentation/screens/vod_streams_screen.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/presentation/support/on_demand_library.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/branded_artwork.dart';
import '../../../../shared/widgets/mobile_primary_dock.dart';

class KidsLibraryScreen extends ConsumerStatefulWidget {
  const KidsLibraryScreen({super.key});

  static const routePath = '/kids';

  @override
  ConsumerState<KidsLibraryScreen> createState() => _KidsLibraryScreenState();
}

class _KidsLibraryScreenState extends ConsumerState<KidsLibraryScreen> {
  _KidsLibraryFilter _selectedFilter = _KidsLibraryFilter.all;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);
    final spec = OnDemandLibrarySpec.resolve(OnDemandLibraryKind.kids);
    final vodCategoriesAsync = ref.watch(vodCategoriesProvider);
    final vodItemsAsync = ref.watch(vodStreamsProvider(null));
    final seriesCategoriesAsync = ref.watch(seriesCategoriesProvider);
    final seriesItemsAsync = ref.watch(seriesItemsProvider(null));

    final vodCategories =
        vodCategoriesAsync.asData?.value ?? const <VodCategory>[];
    final vodItems = vodItemsAsync.asData?.value ?? const <VodStream>[];
    final seriesCategories =
        seriesCategoriesAsync.asData?.value ?? const <SeriesCategory>[];
    final seriesItems = seriesItemsAsync.asData?.value ?? const <SeriesItem>[];

    final vodCategoryIds = _matchingVodCategoryIds(vodCategories, spec);
    final seriesCategoryIds = _matchingSeriesCategoryIds(
      seriesCategories,
      spec,
    );
    final filteredVodItems = _filterVodItems(
      items: vodItems,
      categoryIds: vodCategoryIds,
      spec: spec,
    );
    final filteredSeriesItems = _filterSeriesItems(
      items: seriesItems,
      categoryIds: seriesCategoryIds,
      spec: spec,
    );

    final isLoading =
        vodCategoriesAsync.isLoading ||
        vodItemsAsync.isLoading ||
        seriesCategoriesAsync.isLoading ||
        seriesItemsAsync.isLoading;
    final hasError =
        vodCategoriesAsync.hasError ||
        vodItemsAsync.hasError ||
        seriesCategoriesAsync.hasError ||
        seriesItemsAsync.hasError;
    final hasContent =
        filteredVodItems.isNotEmpty || filteredSeriesItems.isNotEmpty;
    final featured = filteredVodItems.isNotEmpty
        ? filteredVodItems.first
        : filteredSeriesItems.isNotEmpty
        ? filteredSeriesItems.first
        : null;
    final mobileCatalogItems = _buildKidsCatalogItems(
      vodItems: filteredVodItems,
      seriesItems: filteredSeriesItems,
      context: context,
    );
    final visibleMobileItems = _filterKidsCatalogItems(
      items: mobileCatalogItems,
      filter: _selectedFilter,
    );

    return AppScaffold(
      title: spec.title,
      subtitle: layout.isTv ? spec.subtitle : null,
      showBack: true,
      showBrand: false,
      decoratedHeader: layout.isTv,
      mobileBottomBar: const MobilePrimaryDock(),
      child: Builder(
        builder: (context) {
          if (isLoading && !hasContent && !hasError) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!hasContent) {
            return _KidsEmptyState(layout: layout, hasError: hasError);
          }

          if (!layout.isTv) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _KidsMobileCatalogLead(
                    spec: spec,
                    totalItems: mobileCatalogItems.length,
                    movieCount: filteredVodItems.length,
                    seriesCount: filteredSeriesItems.length,
                    selectedFilter: _selectedFilter,
                    onFilterSelected: (filter) {
                      if (_selectedFilter == filter) {
                        return;
                      }
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                ),
                if (visibleMobileItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Nenhum item encontrado neste recorte.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: layout.pageBottomPadding,
                    ),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = visibleMobileItems[index];
                        return _KidsPosterCard(
                          layout: layout,
                          title: item.title,
                          subtitle: item.subtitle,
                          imageUrl: item.imageUrl,
                          icon: item.icon,
                          badge: item.badge,
                          onPressed: item.onPressed,
                        );
                      }, childCount: visibleMobileItems.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: switch (layout.deviceClass) {
                          DeviceClass.mobilePortrait => 3,
                          DeviceClass.mobileLandscape => 4,
                          DeviceClass.tablet => 4,
                          DeviceClass.tvCompact || DeviceClass.tvLarge => 3,
                        },
                        mainAxisSpacing: layout.cardSpacing,
                        crossAxisSpacing: layout.cardSpacing,
                        childAspectRatio: switch (layout.deviceClass) {
                          DeviceClass.mobilePortrait => 0.69,
                          DeviceClass.mobileLandscape => 0.72,
                          DeviceClass.tablet => 0.74,
                          DeviceClass.tvCompact || DeviceClass.tvLarge => 0.56,
                        },
                      ),
                    ),
                  ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _KidsHero(
                  layout: layout,
                  spec: spec,
                  featuredTitle: _featuredTitle(featured),
                  featuredImageUrl: _featuredImageUrl(featured),
                  movieCount: filteredVodItems.length,
                  seriesCount: filteredSeriesItems.length,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: layout.sectionSpacing),
              ),
              if (filteredVodItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: _KidsSectionHeader(
                    layout: layout,
                    title: 'Filmes Kids',
                    subtitle:
                        '${filteredVodItems.length} títulos infantis disponíveis agora.',
                    buttonLabel: 'Ver catálogo',
                    onPressed: () => context.push(
                      VodStreamsScreen.buildLocation(
                        'all',
                        library: OnDemandLibraryKind.kids,
                      ),
                    ),
                  ),
                ),
              if (filteredVodItems.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.only(top: layout.cardSpacing),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredVodItems[index];
                      return _KidsPosterCard(
                        layout: layout,
                        title: item.name,
                        subtitle: item.rating?.trim().isNotEmpty == true
                            ? 'Nota ${item.rating}'
                            : 'Filme infantil',
                        imageUrl: item.coverUrl,
                        icon: Icons.movie_creation_outlined,
                        badge: 'FILME',
                        onPressed: () => context.push(
                          VodDetailsScreen.buildLocation(item.id),
                        ),
                      );
                    }, childCount: filteredVodItems.length.clamp(0, 6)),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: layout.deviceClass == DeviceClass.tablet
                          ? 3
                          : 2,
                      mainAxisSpacing: layout.cardSpacing,
                      crossAxisSpacing: layout.cardSpacing,
                      childAspectRatio: 0.56,
                    ),
                  ),
                ),
              if (filteredSeriesItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: layout.sectionSpacing),
                    child: _KidsSectionHeader(
                      layout: layout,
                      title: 'Séries Kids',
                      subtitle:
                          '${filteredSeriesItems.length} séries infantis para explorar.',
                      buttonLabel: 'Ver séries',
                      onPressed: () => context.push(
                        SeriesItemsScreen.buildLocation(
                          'all',
                          library: OnDemandLibraryKind.kids,
                        ),
                      ),
                    ),
                  ),
                ),
              if (filteredSeriesItems.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.only(
                    top: layout.cardSpacing,
                    bottom: layout.pageBottomPadding,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredSeriesItems[index];
                      return _KidsPosterCard(
                        layout: layout,
                        title: item.name,
                        subtitle: item.plot?.trim().isNotEmpty == true
                            ? item.plot!
                            : 'Série infantil',
                        imageUrl: item.coverUrl,
                        icon: Icons.tv_rounded,
                        badge: 'SÉRIE',
                        onPressed: () => context.push(
                          SeriesDetailsScreen.buildLocation(item.id),
                        ),
                      );
                    }, childCount: filteredSeriesItems.length.clamp(0, 6)),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: layout.deviceClass == DeviceClass.tablet
                          ? 3
                          : 2,
                      mainAxisSpacing: layout.cardSpacing,
                      crossAxisSpacing: layout.cardSpacing,
                      childAspectRatio: 0.56,
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: SizedBox(height: layout.pageBottomPadding),
                ),
            ],
          );
        },
      ),
    );
  }
}

enum _KidsLibraryFilter { all, movies, series }

enum _KidsCatalogItemType { movie, series }

class _KidsCatalogItem {
  const _KidsCatalogItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
    required this.badge,
    required this.onPressed,
  });

  final _KidsCatalogItemType type;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData icon;
  final String badge;
  final VoidCallback onPressed;
}

List<_KidsCatalogItem> _buildKidsCatalogItems({
  required List<VodStream> vodItems,
  required List<SeriesItem> seriesItems,
  required BuildContext context,
}) {
  return [
    ...vodItems.map(
      (item) => _KidsCatalogItem(
        type: _KidsCatalogItemType.movie,
        title: item.name,
        subtitle: item.rating?.trim().isNotEmpty == true
            ? 'Nota ${item.rating}'
            : 'Filme infantil',
        imageUrl: item.coverUrl,
        icon: Icons.movie_creation_outlined,
        badge: 'FILME',
        onPressed: () => context.push(VodDetailsScreen.buildLocation(item.id)),
      ),
    ),
    ...seriesItems.map(
      (item) => _KidsCatalogItem(
        type: _KidsCatalogItemType.series,
        title: item.name,
        subtitle: item.plot?.trim().isNotEmpty == true
            ? item.plot!
            : 'Série infantil',
        imageUrl: item.coverUrl,
        icon: Icons.tv_rounded,
        badge: 'SÉRIE',
        onPressed: () =>
            context.push(SeriesDetailsScreen.buildLocation(item.id)),
      ),
    ),
  ];
}

List<_KidsCatalogItem> _filterKidsCatalogItems({
  required List<_KidsCatalogItem> items,
  required _KidsLibraryFilter filter,
}) {
  return switch (filter) {
    _KidsLibraryFilter.all => items,
    _KidsLibraryFilter.movies =>
      items
          .where((item) => item.type == _KidsCatalogItemType.movie)
          .toList(growable: false),
    _KidsLibraryFilter.series =>
      items
          .where((item) => item.type == _KidsCatalogItemType.series)
          .toList(growable: false),
  };
}

class _KidsMobileCatalogLead extends StatelessWidget {
  const _KidsMobileCatalogLead({
    required this.spec,
    required this.totalItems,
    required this.movieCount,
    required this.seriesCount,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final OnDemandLibrarySpec spec;
  final int totalItems;
  final int movieCount;
  final int seriesCount;
  final _KidsLibraryFilter selectedFilter;
  final ValueChanged<_KidsLibraryFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.catalogLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalItems títulos • $movieCount filmes • $seriesCount séries',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              if (spec.badge != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    spec.badge!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_KidsLibraryFilter>(
              showSelectedIcon: false,
              style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.primary.withValues(alpha: 0.14);
                  }
                  return colorScheme.surface.withValues(alpha: 0.22);
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.onSurface;
                  }
                  return colorScheme.onSurface.withValues(alpha: 0.76);
                }),
                side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                    );
                  }
                  return BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  );
                }),
                textStyle: WidgetStatePropertyAll(
                  Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              segments: const [
                ButtonSegment<_KidsLibraryFilter>(
                  value: _KidsLibraryFilter.all,
                  label: Text('Tudo'),
                ),
                ButtonSegment<_KidsLibraryFilter>(
                  value: _KidsLibraryFilter.movies,
                  label: Text('Filmes'),
                ),
                ButtonSegment<_KidsLibraryFilter>(
                  value: _KidsLibraryFilter.series,
                  label: Text('Séries'),
                ),
              ],
              selected: <_KidsLibraryFilter>{selectedFilter},
              onSelectionChanged: (selection) {
                final filter = selection.firstOrNull;
                if (filter != null) {
                  onFilterSelected(filter);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KidsHero extends StatelessWidget {
  const _KidsHero({
    required this.layout,
    required this.spec,
    required this.featuredTitle,
    required this.featuredImageUrl,
    required this.movieCount,
    required this.seriesCount,
  });

  final DeviceLayout layout;
  final OnDemandLibrarySpec spec;
  final String featuredTitle;
  final String? featuredImageUrl;
  final int movieCount;
  final int seriesCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = BrandedArtwork.normalizeArtworkUrl(featuredImageUrl);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 24 : 20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.28)),
      ),
      child: AspectRatio(
        aspectRatio: layout.isTv ? 16 / 5 : 16 / 9.4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1B1638),
                    Color(0xFF21304C),
                    Color(0xFF342214),
                  ],
                ),
              ),
            ),
            if (image != null)
              Opacity(
                opacity: 0.34,
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  headers: const {'Accept-Encoding': 'identity'},
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xF2111220),
                    const Color(0xD9111220),
                    const Color(0x55111220),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(layout.isTv ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      'BIBLIOTECA KIDS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: layout.isTv ? 12 : 10),
                  Text(
                    spec.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: layout.isTv ? 12 : 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _KidsHeroChip(label: '$movieCount filmes'),
                      _KidsHeroChip(label: '$seriesCount séries'),
                      if (featuredTitle.isNotEmpty)
                        _KidsHeroChip(label: 'Destaque: $featuredTitle'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KidsHeroChip extends StatelessWidget {
  const _KidsHeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _KidsSectionHeader extends StatelessWidget {
  const _KidsSectionHeader({
    required this.layout,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final DeviceLayout layout;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: layout.isTv ? 28 : 22,
                ),
              ),
              SizedBox(height: layout.isTv ? 6 : 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.74),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: layout.isTv ? 16 : 12),
        OutlinedButton(onPressed: onPressed, child: Text(buttonLabel)),
      ],
    );
  }
}

class _KidsPosterCard extends StatelessWidget {
  const _KidsPosterCard({
    required this.layout,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
    required this.onPressed,
    required this.badge,
  });

  final DeviceLayout layout;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData icon;
  final VoidCallback onPressed;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!layout.isTv) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BrandedArtwork(
                    imageUrl: imageUrl,
                    aspectRatio: 2 / 3,
                    borderRadius: 16,
                    icon: icon,
                    placeholderLabel: 'Poster indisponível',
                    chrome: BrandedArtworkChrome.subtle,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.78),
                        ],
                        stops: const [0.45, 0.68, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.black.withValues(alpha: 0.62),
                      ),
                      child: Text(
                        badge,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.08,
                              ),
                        ),
                        if (subtitle.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  BrandedArtwork(
                    imageUrl: imageUrl,
                    aspectRatio: 2 / 3,
                    borderRadius: 18,
                    icon: icon,
                    placeholderLabel: 'Poster indisponível',
                    chrome: BrandedArtworkChrome.subtle,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.black.withValues(alpha: 0.62),
                      ),
                      child: Text(
                        badge,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: layout.isTv ? 12 : 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.12,
              ),
            ),
            SizedBox(height: layout.isTv ? 6 : 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.74),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KidsEmptyState extends StatelessWidget {
  const _KidsEmptyState({required this.layout, required this.hasError});

  final DeviceLayout layout;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: EdgeInsets.all(layout.isTv ? 28 : 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.54),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasError
                    ? Icons.cloud_off_rounded
                    : Icons.rocket_launch_rounded,
                size: layout.isTv ? 48 : 40,
              ),
              SizedBox(height: layout.isTv ? 16 : 12),
              Text(
                hasError
                    ? 'Não foi possível montar a biblioteca Kids agora.'
                    : 'Nenhum conteúdo Kids apareceu neste acesso.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: layout.isTv ? 10 : 8),
              Text(
                hasError
                    ? 'Os catálogos sob demanda não responderam como esperado.'
                    : 'Se o provedor não expõe categorias infantis, a biblioteca fica vazia até que esse conteúdo exista no catálogo.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.76),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Set<String> _matchingVodCategoryIds(
  List<VodCategory> categories,
  OnDemandLibrarySpec spec,
) {
  return categories
      .where((category) => spec.hasExplicitSignal(category.libraryKind))
      .map((category) => category.id)
      .toSet();
}

Set<String> _matchingSeriesCategoryIds(
  List<SeriesCategory> categories,
  OnDemandLibrarySpec spec,
) {
  return categories
      .where((category) => spec.hasExplicitSignal(category.libraryKind))
      .map((category) => category.id)
      .toSet();
}

List<VodStream> _filterVodItems({
  required List<VodStream> items,
  required Set<String> categoryIds,
  required OnDemandLibrarySpec spec,
}) {
  return items
      .where((item) {
        final categoryMatch =
            item.categoryId != null && categoryIds.contains(item.categoryId);
        return categoryMatch || spec.hasExplicitSignal(item.libraryKind);
      })
      .toList(growable: false);
}

List<SeriesItem> _filterSeriesItems({
  required List<SeriesItem> items,
  required Set<String> categoryIds,
  required OnDemandLibrarySpec spec,
}) {
  return items
      .where((item) {
        final categoryMatch =
            item.categoryId != null && categoryIds.contains(item.categoryId);
        return categoryMatch || spec.hasExplicitSignal(item.libraryKind);
      })
      .toList(growable: false);
}

String _featuredTitle(Object? featured) {
  if (featured is VodStream) {
    return featured.name;
  }
  if (featured is SeriesItem) {
    return featured.name;
  }
  return '';
}

String? _featuredImageUrl(Object? featured) {
  if (featured is VodStream) {
    return featured.coverUrl;
  }
  if (featured is SeriesItem) {
    return featured.coverUrl;
  }
  return null;
}
