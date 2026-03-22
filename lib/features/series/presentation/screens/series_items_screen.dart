import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/tv/tv_focusable.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/branded_artwork.dart';
import '../../../../shared/widgets/content_list_tile.dart';
import '../../domain/entities/series_item.dart';
import '../providers/series_providers.dart';
import 'series_details_screen.dart';

class SeriesItemsScreen extends ConsumerWidget {
  const SeriesItemsScreen({super.key, required this.categoryId});

  static const routePath = '/series/category/:categoryId';

  static String buildLocation(String categoryId) =>
      '/series/category/$categoryId';

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveCategoryId = categoryId == 'all' ? null : categoryId;
    final series = ref.watch(seriesItemsProvider(effectiveCategoryId));

    return AppScaffold(
      title: 'Séries',
      subtitle: effectiveCategoryId == null
          ? 'Catálogo completo'
          : 'Seleção disponível',
      showBack: true,
      child: AsyncStateBuilder(
        value: series,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem séries disponíveis',
        emptyMessage: 'Nenhuma série foi encontrada para o filtro selecionado.',
        dataBuilder: (items) {
          final featured = _resolveFeatured(items);

          return LayoutBuilder(
            builder: (context, constraints) {
              final layout = DeviceLayout.of(context, constraints: constraints);
              if (layout.isTv) {
                final spacing = layout.cardSpacing;
                final columns = layout.columnsForWidth(
                  constraints.maxWidth,
                  minTileWidth: 290,
                  maxColumns: 4,
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
                        totalItems: items.length,
                      ),
                      SizedBox(height: layout.cardSpacing),
                      _SeriesCatalogHeader(
                        layout: layout,
                        totalItems: items.length,
                      ),
                      SizedBox(height: layout.cardSpacing),
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (var index = 0; index < items.length; index++)
                            SizedBox(
                              width: itemWidth,
                              child: _SeriesTvPosterCard(
                                layout: layout,
                                item: items[index],
                                autofocus: index == 0,
                                onPressed: () => context.push(
                                  SeriesDetailsScreen.buildLocation(
                                    items[index].id,
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

              return ListView.separated(
                padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
                itemCount: items.length + 2,
                separatorBuilder: (context, index) =>
                    SizedBox(height: layout.cardSpacing),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _SeriesHeroShelf(
                      layout: layout,
                      item: featured,
                      totalItems: items.length,
                    );
                  }

                  if (index == 1) {
                    return _SeriesCatalogHeader(
                      layout: layout,
                      totalItems: items.length,
                    );
                  }

                  final item = items[index - 2];

                  return ContentListTile(
                    autofocus: index == 2,
                    overline: 'Catálogo de séries',
                    title: item.name,
                    subtitle: item.plot?.trim().isNotEmpty == true
                        ? item.plot
                        : 'Série disponível para assistir',
                    icon: Icons.tv_outlined,
                    imageUrl: item.coverUrl,
                    thumbnailLabel: 'Capa indisponível',
                    badge: 'SÉRIE',
                    onPressed: () => context.push(
                      SeriesDetailsScreen.buildLocation(item.id),
                    ),
                  );
                },
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

class _SeriesHeroShelf extends StatelessWidget {
  const _SeriesHeroShelf({
    required this.layout,
    required this.item,
    required this.totalItems,
  });

  final DeviceLayout layout;
  final SeriesItem item;
  final int totalItems;

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
        aspectRatio: layout.isTv ? 16 / 4.7 : 16 / 10.2,
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
                          'Série em destaque',
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
                            _HeroChip(
                              label: '$totalItems séries',
                              layout: layout,
                            ),
                            _HeroChip(
                              label: 'Temporadas e episódios',
                              layout: layout,
                            ),
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
                        icon: Icons.tv_outlined,
                        placeholderLabel: 'Capa indisponível',
                        borderRadius: 16,
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
  const _HeroChip({required this.label, required this.layout});

  final String label;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.isTv ? 11 : 9,
        vertical: layout.isTv ? 6 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: layout.isTv ? 12.5 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SeriesCatalogHeader extends StatelessWidget {
  const _SeriesCatalogHeader({required this.layout, required this.totalItems});

  final DeviceLayout layout;
  final int totalItems;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(layout.isTv ? 18 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 20 : 16),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Container(
            width: layout.isTv ? 44 : 36,
            height: layout.isTv ? 44 : 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: Icon(
              Icons.grid_view_rounded,
              color: colorScheme.primary,
              size: layout.isTv ? 24 : 20,
            ),
          ),
          SizedBox(width: layout.isTv ? 12 : 10),
          Expanded(
            child: Text(
              'Todas as séries • $totalItems disponíveis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: layout.isTv ? 24 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesTvPosterCard extends StatelessWidget {
  const _SeriesTvPosterCard({
    required this.layout,
    required this.item,
    required this.onPressed,
    this.autofocus = false,
  });

  final DeviceLayout layout;
  final SeriesItem item;
  final VoidCallback onPressed;
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: focused
                  ? [
                      colorScheme.primary.withValues(alpha: 0.24),
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
                  : colorScheme.outline.withValues(alpha: 0.45),
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
              BrandedArtwork(
                imageUrl: item.coverUrl,
                aspectRatio: 2 / 3,
                borderRadius: 16,
                placeholderLabel: 'Capa indisponível',
                icon: Icons.tv_outlined,
              ),
              const SizedBox(height: 10),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.plot?.trim().isNotEmpty == true
                    ? item.plot!
                    : 'Série disponível para assistir',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.76),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
