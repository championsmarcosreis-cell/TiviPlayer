import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/tv/tv_focusable.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/presentation/support/on_demand_library.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/branded_artwork.dart';
import '../../../../shared/widgets/mobile_primary_dock.dart';
import '../../domain/entities/series_category.dart';
import '../../domain/entities/series_item.dart';
import '../providers/series_providers.dart';
import 'series_details_screen.dart';

class SeriesItemsScreen extends ConsumerWidget {
  const SeriesItemsScreen({
    super.key,
    required this.categoryId,
    this.library = OnDemandLibraryKind.series,
  });

  static const routePath = '/series/category/:categoryId';

  static String buildLocation(
    String categoryId, {
    OnDemandLibraryKind library = OnDemandLibraryKind.series,
  }) {
    return buildLibraryLocation(
      '/series/category/$categoryId',
      kind: library,
      defaultKind: OnDemandLibraryKind.series,
    );
  }

  final String categoryId;
  final OnDemandLibraryKind library;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenLayout = DeviceLayout.of(context);
    final spec = OnDemandLibrarySpec.resolve(library);
    final effectiveCategoryId = categoryId == 'all' ? null : categoryId;
    final itemsAsync = ref.watch(seriesItemsProvider(effectiveCategoryId));
    final categoriesAsync = ref.watch(seriesCategoriesProvider);

    return AppScaffold(
      title: spec.title,
      subtitle: screenLayout.isTv ? spec.subtitle : null,
      showBack: true,
      showBrand: false,
      decoratedHeader: screenLayout.isTv,
      mobileBottomBar: const MobilePrimaryDock(),
      child: AsyncStateBuilder(
        value: itemsAsync,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem séries disponíveis',
        emptyMessage: 'Nenhuma série foi encontrada para o filtro selecionado.',
        dataBuilder: (items) {
          final categories =
              categoriesAsync.asData?.value ?? const <SeriesCategory>[];
          final filteredCategories = _filterSeriesCategories(
            categories,
            library,
          );
          final filteredCategoryIds = filteredCategories
              .map((category) => category.id)
              .toSet();
          final visibleItems = _filterSeriesItems(
            items: items,
            library: library,
            categoryIds: filteredCategoryIds,
          );

          if (visibleItems.isEmpty) {
            return _SeriesLibraryEmptyState(spec: spec);
          }

          final featured = _resolveFeatured(visibleItems);

          return LayoutBuilder(
            builder: (context, constraints) {
              final layout = DeviceLayout.of(context, constraints: constraints);
              if (layout.isTv) {
                final spacing = layout.cardSpacing;
                final columns = layout.columnsForWidth(
                  constraints.maxWidth,
                  minTileWidth: 220,
                  maxColumns: 6,
                );
                final itemWidth = layout.itemWidth(
                  constraints.maxWidth,
                  columns: columns,
                  spacing: spacing,
                );

                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SeriesHeroShelf(
                        layout: layout,
                        item: featured,
                        totalItems: visibleItems.length,
                        spec: spec,
                      ),
                      SizedBox(height: layout.cardSpacing),
                      _SeriesCatalogHeader(
                        layout: layout,
                        totalItems: visibleItems.length,
                        spec: spec,
                      ),
                      SizedBox(height: layout.cardSpacing),
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (
                            var index = 0;
                            index < visibleItems.length;
                            index++
                          )
                            SizedBox(
                              width: itemWidth,
                              child: _SeriesPosterCard(
                                layout: layout,
                                item: visibleItems[index],
                                badge: spec.badge,
                                autofocus: index == 0,
                                onPressed: () => context.push(
                                  SeriesDetailsScreen.buildLocation(
                                    visibleItems[index].id,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _SeriesMobileLibraryHeader(
                      spec: spec,
                      totalItems: visibleItems.length,
                      currentCategoryLabel: _resolveSeriesCategoryLabel(
                        categories: filteredCategories,
                        categoryId: categoryId,
                      ),
                      categoryStrip: _SeriesCategoryStrip(
                        spec: spec,
                        currentCategoryId: categoryId,
                        categories: filteredCategories,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      top: 12,
                      bottom: layout.pageBottomPadding,
                    ),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = visibleItems[index];
                        return _SeriesPosterCard(
                          layout: layout,
                          item: item,
                          badge: spec.badge,
                          autofocus: index == 0,
                          onPressed: () => context.push(
                            SeriesDetailsScreen.buildLocation(item.id),
                          ),
                        );
                      }, childCount: visibleItems.length),
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
                ],
              );
            },
          );
        },
      ),
    );
  }
}

SeriesItem _resolveFeatured(List<SeriesItem> items) {
  return items.firstWhere(
    (item) => BrandedArtwork.normalizeArtworkUrl(item.coverUrl) != null,
    orElse: () => items.first,
  );
}

String? _resolveSeriesCategoryLabel({
  required List<SeriesCategory> categories,
  required String categoryId,
}) {
  if (categoryId == 'all') {
    return null;
  }

  for (final category in categories) {
    if (category.id == categoryId) {
      return category.name;
    }
  }

  return null;
}

List<SeriesCategory> _filterSeriesCategories(
  List<SeriesCategory> categories,
  OnDemandLibraryKind library,
) {
  final spec = OnDemandLibrarySpec.resolve(library);
  return categories
      .where(
        (category) => spec.matchesCategory(
          value: category.name,
          libraryKind: category.libraryKind,
        ),
      )
      .toList(growable: false);
}

List<SeriesItem> _filterSeriesItems({
  required List<SeriesItem> items,
  required OnDemandLibraryKind library,
  required Set<String> categoryIds,
}) {
  final spec = OnDemandLibrarySpec.resolve(library);
  if (!spec.isFilteredVariant) {
    return items;
  }
  return items
      .where((item) {
        final matchesCategory =
            item.categoryId != null && categoryIds.contains(item.categoryId);
        final hasCanonicalLibrary =
            OnDemandLibraryKind.tryParse(item.libraryKind) != null;
        if (hasCanonicalLibrary) {
          return spec.hasExplicitSignal(item.libraryKind);
        }
        return matchesCategory ||
            spec.matchesTextContent(
              primary: item.name,
              secondary: item.plot ?? '',
            );
      })
      .toList(growable: false);
}

class _SeriesHeroShelf extends StatelessWidget {
  const _SeriesHeroShelf({
    required this.layout,
    required this.item,
    required this.totalItems,
    required this.spec,
  });

  final DeviceLayout layout;
  final SeriesItem item;
  final int totalItems;
  final OnDemandLibrarySpec spec;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = BrandedArtwork.normalizeArtworkUrl(item.coverUrl);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 28 : 22),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.45)),
      ),
      child: AspectRatio(
        aspectRatio: layout.isTv ? 16 / 5 : 16 / 10.2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              Image.network(
                image,
                fit: BoxFit.cover,
                headers: const {'Accept-Encoding': 'identity'},
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xEE090C17),
                    const Color(0xCC090C17),
                    const Color(0x33090C17),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(layout.isTv ? 24 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Destaque de ${spec.title}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                letterSpacing: 1,
                                color: colorScheme.secondary,
                              ),
                        ),
                        SizedBox(height: layout.isTv ? 8 : 6),
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize: layout.isTv ? 34 : 22,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        SizedBox(height: layout.isTv ? 8 : 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HeroChip(label: spec.countLabel(totalItems)),
                            _HeroChip(label: spec.catalogLabel),
                            const _HeroChip(label: 'Temporadas e episódios'),
                          ],
                        ),
                        SizedBox(height: layout.isTv ? 14 : 10),
                        FilledButton.icon(
                          onPressed: () => context.push(
                            SeriesDetailsScreen.buildLocation(item.id),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Abrir detalhe'),
                        ),
                      ],
                    ),
                  ),
                  if (layout.isTv) ...[
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 140,
                      child: BrandedArtwork(
                        imageUrl: item.coverUrl,
                        icon: spec.icon,
                        placeholderLabel: 'Capa indisponível',
                        borderRadius: 16,
                        chrome: BrandedArtworkChrome.subtle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SeriesCatalogHeader extends StatelessWidget {
  const _SeriesCatalogHeader({
    required this.layout,
    required this.totalItems,
    required this.spec,
  });

  final DeviceLayout layout;
  final int totalItems;
  final OnDemandLibrarySpec spec;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(layout.isTv ? 18 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 20 : 16),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: layout.isTv ? 44 : 36,
            height: layout.isTv ? 44 : 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.primary.withValues(alpha: 0.16),
            ),
            child: Icon(
              Icons.grid_view_rounded,
              color: colorScheme.primary,
              size: layout.isTv ? 24 : 20,
            ),
          ),
          SizedBox(width: layout.isTv ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${spec.catalogLabel} • $totalItems',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: layout.isTv ? 21 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: layout.isTv ? 4 : 2),
                Text(
                  'Fluxo direto para explorar posters, temporadas e episódios sem o peso do hub antigo.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.74),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesMobileLibraryHeader extends StatelessWidget {
  const _SeriesMobileLibraryHeader({
    required this.spec,
    required this.totalItems,
    required this.categoryStrip,
    this.currentCategoryLabel,
  });

  final OnDemandLibrarySpec spec;
  final int totalItems;
  final Widget categoryStrip;
  final String? currentCategoryLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.primary.withValues(alpha: 0.14),
                ),
                child: Icon(spec.icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
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
                      currentCategoryLabel == null
                          ? spec.countLabel(totalItems)
                          : '${spec.countLabel(totalItems)} • $currentCategoryLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.74),
                      ),
                    ),
                  ],
                ),
              ),
              if (spec.badge != null)
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
          ),
          const SizedBox(height: 12),
          categoryStrip,
        ],
      ),
    );
  }
}

class _SeriesCategoryStrip extends StatelessWidget {
  const _SeriesCategoryStrip({
    required this.spec,
    required this.currentCategoryId,
    required this.categories,
  });

  final OnDemandLibrarySpec spec;
  final String currentCategoryId;
  final List<SeriesCategory> categories;

  @override
  Widget build(BuildContext context) {
    final items = <({String id, String label})>[
      (
        id: 'all',
        label: spec.isFilteredVariant ? 'Tudo em ${spec.title}' : 'Todas',
      ),
      ...categories.map((category) => (id: category.id, label: category.name)),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = items[index];
          return _CategoryChipButton(
            label: entry.label,
            selected: currentCategoryId == entry.id,
            onPressed: () {
              if (currentCategoryId == entry.id) {
                return;
              }

              context.pushReplacement(
                SeriesItemsScreen.buildLocation(entry.id, library: spec.kind),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryChipButton extends StatelessWidget {
  const _CategoryChipButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusable(
      onPressed: onPressed,
      builder: (context, focused) {
        final active = selected || focused;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: active
                ? colorScheme.primary.withValues(alpha: 0.16)
                : colorScheme.surface.withValues(alpha: 0.56),
            border: Border.all(
              color: active
                  ? colorScheme.primary.withValues(alpha: 0.9)
                  : colorScheme.outline.withValues(alpha: 0.24),
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}

class _SeriesPosterCard extends StatelessWidget {
  const _SeriesPosterCard({
    required this.layout,
    required this.item,
    required this.onPressed,
    this.badge,
    this.autofocus = false,
  });

  final DeviceLayout layout;
  final SeriesItem item;
  final VoidCallback onPressed;
  final String? badge;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusable(
      autofocus: autofocus,
      onPressed: onPressed,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.all(layout.isTv ? 8 : 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.isTv ? 20 : 18),
            color: focused
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: focused
                  ? colorScheme.primary.withValues(alpha: 0.34)
                  : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(layout.isTv ? 16 : 18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    BrandedArtwork(
                      imageUrl: item.coverUrl,
                      aspectRatio: 2 / 3,
                      borderRadius: layout.isTv ? 16 : 18,
                      placeholderLabel: 'Capa indisponível',
                      icon: Icons.tv_rounded,
                      chrome: BrandedArtworkChrome.subtle,
                    ),
                    _PosterBadge(label: badge ?? 'SÉRIE'),
                  ],
                ),
              ),
              SizedBox(height: layout.isTv ? 10 : 8),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                  fontSize: layout.isTv ? 17 : 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.plot?.trim().isNotEmpty == true
                    ? item.plot!
                    : 'Série para maratonar',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                  height: 1.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PosterBadge extends StatelessWidget {
  const _PosterBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.black.withValues(alpha: 0.62),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _SeriesLibraryEmptyState extends StatelessWidget {
  const _SeriesLibraryEmptyState({required this.spec});

  final OnDemandLibrarySpec spec;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(spec.icon, size: 38),
              const SizedBox(height: 12),
              Text(
                'Nenhum item encontrado em ${spec.title}.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                spec.isFilteredVariant
                    ? 'O catálogo carregou, mas esta biblioteca filtrada não encontrou correspondências com as categorias disponíveis.'
                    : 'O catálogo carregou sem séries disponíveis nesta coleção.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.74),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
