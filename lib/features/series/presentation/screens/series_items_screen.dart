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
import '../../../../shared/widgets/tv_library_shell.dart';
import '../../domain/entities/series_category.dart';
import '../../domain/entities/series_item.dart';
import '../providers/series_providers.dart';
import 'series_details_screen.dart';

class SeriesItemsScreen extends ConsumerStatefulWidget {
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
  ConsumerState<SeriesItemsScreen> createState() => _SeriesItemsScreenState();
}

class _SeriesItemsScreenState extends ConsumerState<SeriesItemsScreen> {
  String? _selectedGenre;

  @override
  void didUpdateWidget(covariant SeriesItemsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId ||
        oldWidget.library != widget.library) {
      _selectedGenre = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenLayout = DeviceLayout.of(context);
    final spec = OnDemandLibrarySpec.resolve(widget.library);
    final effectiveCategoryId = screenLayout.isTv
        ? (widget.categoryId == 'all' ? null : widget.categoryId)
        : null;
    final itemsAsync = ref.watch(seriesItemsProvider(effectiveCategoryId));
    final categoriesAsync = ref.watch(seriesCategoriesProvider);

    return AppScaffold(
      title: spec.title,
      subtitle: screenLayout.isTv ? spec.subtitle : null,
      showBack: true,
      showBrand: false,
      decoratedHeader: !screenLayout.isTv,
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
            widget.library,
          );
          final filteredCategoryIds = filteredCategories
              .map((category) => category.id)
              .toSet();
          final visibleItems = _filterSeriesItems(
            items: items,
            library: widget.library,
            categoryIds: filteredCategoryIds,
          );

          if (visibleItems.isEmpty) {
            return _SeriesLibraryEmptyState(spec: spec);
          }

          final catalogGenres = _collectSeriesGenres(visibleItems);
          final genreLabels = catalogGenres
              .map((genre) => genre.label)
              .toList(growable: false);
          final effectiveSelectedGenre =
              _selectedGenre != null && genreLabels.contains(_selectedGenre)
              ? _selectedGenre
              : null;
          final genreFilteredItems = _filterSeriesItemsByGenre(
            items: visibleItems,
            selectedGenre: effectiveSelectedGenre,
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final layout = DeviceLayout.of(context, constraints: constraints);
              if (layout.isTv) {
                final filters = <TvLibraryFilterOption>[
                  TvLibraryFilterOption(
                    id: 'all',
                    label: 'Todos',
                    count: visibleItems.length,
                    subtitle: 'Catálogo completo',
                    icon: Icons.grid_view_rounded,
                  ),
                  ...catalogGenres.map(
                    (genre) => TvLibraryFilterOption(
                      id: genre.label,
                      label: genre.label,
                      count: genre.count,
                      subtitle: 'Gênero',
                      icon: Icons.local_offer_outlined,
                    ),
                  ),
                ];

                final posterItems = genreFilteredItems
                    .map(
                      (item) => TvLibraryPosterCardData(
                        id: item.id,
                        title: item.name,
                        subtitle:
                            splitLibraryGenres(item.genre).firstOrNull ??
                            (item.plot?.trim().isNotEmpty == true
                                ? item.plot!
                                : 'Série para maratonar'),
                        imageUrl: item.coverUrl,
                        icon: Icons.tv_rounded,
                        onPressed: () => context.push(
                          SeriesDetailsScreen.buildLocation(item.id),
                        ),
                      ),
                    )
                    .toList(growable: false);

                return TvLibraryShell(
                  layout: layout,
                  spec: spec,
                  description:
                      'Seletor direto no topo para escolher o recorte antes da grade.',
                  filters: filters,
                  selectedFilterId: effectiveSelectedGenre ?? 'all',
                  onFilterSelected: (filterId) {
                    final genre = filterId == 'all' ? null : filterId;
                    if (_selectedGenre == genre) {
                      return;
                    }
                    setState(() => _selectedGenre = genre);
                  },
                  items: posterItems,
                  emptyTitle: 'Nenhuma série encontrada neste recorte.',
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _SeriesMobileCatalogLead(
                      spec: spec,
                      showCategoriesAction: genreLabels.isNotEmpty,
                      currentCategoryLabel: _selectedGenre,
                      onOpenCategories: () => _showSeriesCategorySheet(
                        context,
                        selectedGenre: _selectedGenre,
                        genres: genreLabels,
                        onSelected: (genre) {
                          if (_selectedGenre == genre) {
                            return;
                          }
                          setState(() => _selectedGenre = genre);
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: layout.pageBottomPadding,
                    ),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = genreFilteredItems[index];
                        return _SeriesPosterCard(
                          layout: layout,
                          item: item,
                          badge: spec.badge,
                          autofocus: false,
                          onPressed: () => context.push(
                            SeriesDetailsScreen.buildLocation(item.id),
                          ),
                        );
                      }, childCount: genreFilteredItems.length),
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
            },
          );
        },
      ),
    );
  }
}

typedef _SeriesGenreCount = ({int count, String label});

List<_SeriesGenreCount> _collectSeriesGenres(List<SeriesItem> items) {
  final counts = <String, int>{};
  final labels = <String, String>{};

  for (final item in items) {
    for (final genre in splitLibraryGenres(item.genre)) {
      final key = normalizeLibraryText(genre);
      if (key.isEmpty) {
        continue;
      }
      labels.putIfAbsent(key, () => genre);
      counts.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
  }

  final sortedEntries = counts.entries.toList()
    ..sort((left, right) {
      final countCompare = right.value.compareTo(left.value);
      if (countCompare != 0) {
        return countCompare;
      }
      return labels[left.key]!.compareTo(labels[right.key]!);
    });

  return sortedEntries
      .map((entry) => (label: labels[entry.key]!, count: entry.value))
      .toList(growable: false);
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

List<SeriesItem> _filterSeriesItemsByGenre({
  required List<SeriesItem> items,
  required String? selectedGenre,
}) {
  if (selectedGenre == null || selectedGenre.trim().isEmpty) {
    return items;
  }

  return items
      .where((item) => matchesLibraryGenre(item.genre, selectedGenre))
      .toList(growable: false);
}

class _SeriesMobileCatalogLead extends StatelessWidget {
  const _SeriesMobileCatalogLead({
    required this.spec,
    required this.showCategoriesAction,
    required this.onOpenCategories,
    this.currentCategoryLabel,
  });

  final OnDemandLibrarySpec spec;
  final bool showCategoriesAction;
  final String? currentCategoryLabel;
  final VoidCallback onOpenCategories;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                if (currentCategoryLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    currentCategoryLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showCategoriesAction) ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onOpenCategories,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                backgroundColor: colorScheme.surface.withValues(alpha: 0.32),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.24),
                ),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              label: const Text('Categorias'),
            ),
          ],
        ],
      ),
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
    final primaryGenre = splitLibraryGenres(item.genre).firstOrNull;

    return TvFocusable(
      autofocus: autofocus,
      onPressed: onPressed,
      builder: (context, focused) {
        if (!layout.isTv) {
          return AnimatedScale(
            scale: focused ? 1.02 : 1,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: focused
                      ? colorScheme.primary.withValues(alpha: 0.34)
                      : colorScheme.outline.withValues(alpha: 0.06),
                  width: focused ? 1.4 : 1,
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
                      imageUrl: item.coverUrl,
                      aspectRatio: 2 / 3,
                      borderRadius: 16,
                      placeholderLabel: 'Capa indisponível',
                      icon: Icons.tv_rounded,
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
                    _PosterBadge(label: badge ?? 'SÉRIE'),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.08,
                                ),
                          ),
                          if (primaryGenre != null ||
                              item.plot?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              primaryGenre ?? item.plot!,
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
          );
        }

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
                primaryGenre ??
                    (item.plot?.trim().isNotEmpty == true
                        ? item.plot!
                        : 'Série para maratonar'),
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

Future<void> _showSeriesCategorySheet(
  BuildContext context, {
  required String? selectedGenre,
  required List<String> genres,
  required ValueChanged<String?> onSelected,
}) {
  final entries = <({String? value, String label})>[
    (value: null, label: 'Todos'),
    ...genres.map((genre) => (value: genre, label: genre)),
  ];

  final colorScheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: colorScheme.surface,
    builder: (sheetContext) {
      return SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.82,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            itemCount: entries.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Categorias',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }

              final entry = entries[index - 1];
              final selected = selectedGenre == entry.value;
              return TvFocusable(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onSelected(entry.value);
                },
                builder: (context, focused) {
                  final active = selected || focused;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: active
                          ? colorScheme.primary.withValues(alpha: 0.14)
                          : colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.32,
                            ),
                      border: Border.all(
                        color: active
                            ? colorScheme.primary.withValues(alpha: 0.42)
                            : colorScheme.outline.withValues(alpha: 0.14),
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        entry.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: selected
                          ? Icon(
                              Icons.check_rounded,
                              color: colorScheme.primary,
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    },
  );
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
