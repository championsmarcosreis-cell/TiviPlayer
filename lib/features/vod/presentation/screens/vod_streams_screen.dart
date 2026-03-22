import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/testing/app_test_keys.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/branded_artwork.dart';
import '../../../../shared/widgets/content_list_tile.dart';
import '../../domain/entities/vod_stream.dart';
import '../providers/vod_providers.dart';
import 'vod_details_screen.dart';

class VodStreamsScreen extends ConsumerWidget {
  const VodStreamsScreen({super.key, required this.categoryId});

  static const routePath = '/vod/category/:categoryId';

  static String buildLocation(String categoryId) => '/vod/category/$categoryId';

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveCategoryId = categoryId == 'all' ? null : categoryId;
    final streams = ref.watch(vodStreamsProvider(effectiveCategoryId));

    return AppScaffold(
      title: 'Filmes',
      subtitle: effectiveCategoryId == null
          ? 'Catálogo completo'
          : 'Seleção disponível',
      showBack: true,
      child: AsyncStateBuilder(
        value: streams,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem títulos disponíveis',
        emptyMessage: 'Nenhum filme foi encontrado para o filtro selecionado.',
        dataBuilder: (items) {
          final featured = _resolveFeatured(items);

          return LayoutBuilder(
            builder: (context, constraints) {
              final layout = DeviceLayout.of(context, constraints: constraints);

              return ListView.separated(
                padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
                cacheExtent: layout.isTv ? 2200 : 1200,
                itemCount: items.length + 2,
                separatorBuilder: (context, index) =>
                    SizedBox(height: layout.cardSpacing),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _VodHeroShelf(
                      layout: layout,
                      item: featured,
                      totalItems: items.length,
                    );
                  }

                  if (index == 1) {
                    return _CatalogHeader(
                      layout: layout,
                      totalItems: items.length,
                    );
                  }

                  final item = items[index - 2];
                  final metadata = <String>[
                    'Filme',
                    if (item.rating?.trim().isNotEmpty == true)
                      'Nota ${item.rating}',
                  ];

                  return ContentListTile(
                    interactiveKey: AppTestKeys.vodItem(item.id),
                    autofocus: index == 2,
                    testId: AppTestKeys.vodItemId(item.id),
                    overline: 'Catalogo VOD',
                    title: item.name,
                    subtitle: 'Abra para ver detalhes e reproduzir.',
                    metadata: metadata,
                    badge: item.rating?.trim().isNotEmpty == true
                        ? '★ ${item.rating}'
                        : null,
                    icon: Icons.movie_creation_outlined,
                    imageUrl: item.coverUrl,
                    thumbnailLabel: 'Poster indisponível',
                    thumbnailWidth: layout.isTv ? 96 : 74,
                    onPressed: () =>
                        context.push(VodDetailsScreen.buildLocation(item.id)),
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

VodStream _resolveFeatured(List<VodStream> items) {
  return items.firstWhere(
    (item) => BrandedArtwork.normalizeArtworkUrl(item.coverUrl) != null,
    orElse: () => items.first,
  );
}

class _VodHeroShelf extends StatelessWidget {
  const _VodHeroShelf({
    required this.layout,
    required this.item,
    required this.totalItems,
  });

  final DeviceLayout layout;
  final VodStream item;
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
        aspectRatio: layout.isTv ? 16 / 4.6 : 16 / 10.2,
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
                    const Color(0xEE04080F),
                    const Color(0xCC04080F),
                    const Color(0x3304080F),
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
                          'Destaque do catálogo',
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
                              label: '$totalItems títulos',
                              layout: layout,
                            ),
                            if (layout.isTv)
                              _HeroChip(
                                label: 'Streaming sob demanda',
                                layout: layout,
                              ),
                            if (item.rating?.trim().isNotEmpty == true)
                              _HeroChip(
                                label: 'Nota ${item.rating}',
                                layout: layout,
                              ),
                          ],
                        ),
                        SizedBox(height: layout.isTv ? 14 : 10),
                        FilledButton.icon(
                          onPressed: () => context.push(
                            VodDetailsScreen.buildLocation(item.id),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Abrir destaque'),
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
                        icon: Icons.movie_creation_outlined,
                        placeholderLabel: 'Poster indisponível',
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

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({required this.layout, required this.totalItems});

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
              'Todos os títulos • $totalItems disponíveis',
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
