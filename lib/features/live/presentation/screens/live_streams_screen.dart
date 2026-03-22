import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/live/domain/entities/live_stream.dart';
import '../../../../features/player/domain/entities/playback_context.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/branded_artwork.dart';
import '../../../../shared/widgets/content_list_tile.dart';
import '../providers/live_providers.dart';

class LiveStreamsScreen extends ConsumerWidget {
  const LiveStreamsScreen({super.key, required this.categoryId});

  static const routePath = '/live/category/:categoryId';

  static String buildLocation(String categoryId) =>
      '/live/category/$categoryId';

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveCategoryId = categoryId == 'all' ? null : categoryId;
    final streams = ref.watch(liveStreamsProvider(effectiveCategoryId));

    return AppScaffold(
      title: 'Ao vivo',
      subtitle: effectiveCategoryId == null
          ? 'Todos os canais'
          : 'Grade selecionada',
      showBack: true,
      child: AsyncStateBuilder(
        value: streams,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem canais disponíveis',
        emptyMessage: 'Nenhum canal foi encontrado para o filtro selecionado.',
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
                    return _LiveHeroShelf(
                      layout: layout,
                      item: featured,
                      totalItems: items.length,
                      onPlay: () => _openLivePlayer(context, featured),
                    );
                  }

                  if (index == 1) {
                    return _LiveCatalogHeader(
                      layout: layout,
                      totalItems: items.length,
                    );
                  }

                  final item = items[index - 2];
                  final subtitle = item.hasArchive
                      ? 'Canal com replay disponível'
                      : 'Canal disponível para assistir';
                  final metadata = <String>[
                    'Ao vivo',
                    if (item.hasArchive) 'Replay',
                    if (item.isAdult) '18+' else 'Livre',
                    if (item.epgChannelId?.trim().isNotEmpty == true) 'EPG',
                    if (item.containerExtension?.trim().isNotEmpty == true)
                      item.containerExtension!.trim().toUpperCase(),
                  ];

                  return ContentListTile(
                    autofocus: index == 2,
                    overline: 'Canal ao vivo',
                    title: item.name,
                    subtitle: subtitle,
                    metadata: metadata,
                    badge: item.hasArchive ? 'REPLAY' : 'LIVE',
                    icon: Icons.live_tv_rounded,
                    imageUrl: item.iconUrl,
                    thumbnailAspectRatio: 1,
                    thumbnailWidth: layout.isTv ? 82 : 64,
                    thumbnailFit: BoxFit.contain,
                    imagePadding: EdgeInsets.all(layout.isTv ? 12 : 14),
                    thumbnailLabel: 'Canal',
                    onPressed: () => _openLivePlayer(context, item),
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

LiveStream _resolveFeatured(List<LiveStream> items) {
  return items.firstWhere(
    (item) => BrandedArtwork.normalizeArtworkUrl(item.iconUrl) != null,
    orElse: () => items.first,
  );
}

void _openLivePlayer(BuildContext context, LiveStream item) {
  context.push(
    PlayerScreen.routePath,
    extra: PlaybackContext(
      contentType: PlaybackContentType.live,
      itemId: item.id,
      title: item.name,
      containerExtension: item.containerExtension,
    ),
  );
}

class _LiveHeroShelf extends StatelessWidget {
  const _LiveHeroShelf({
    required this.layout,
    required this.item,
    required this.totalItems,
    required this.onPlay,
  });

  final DeviceLayout layout;
  final LiveStream item;
  final int totalItems;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = BrandedArtwork.normalizeArtworkUrl(item.iconUrl);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 28 : 22),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.45)),
      ),
      child: AspectRatio(
        aspectRatio: layout.isTv ? 16 / 4.4 : 16 / 8.4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF081224),
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.82),
                    const Color(0xFF0E1A2F),
                  ],
                ),
              ),
            ),
            if (image != null)
              Opacity(
                opacity: 0.18,
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
                    const Color(0xEE050B16),
                    const Color(0xC4050B16),
                    const Color(0x33050B16),
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
                          'Canal em destaque',
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
                                fontSize: layout.isTv ? 34 : 24,
                                height: 1.02,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        SizedBox(height: layout.isTv ? 8 : 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _LiveHeroChip(
                              label: '$totalItems canais',
                              layout: layout,
                            ),
                            _LiveHeroChip(
                              label: 'Grade Xtream',
                              layout: layout,
                            ),
                            if (item.hasArchive)
                              _LiveHeroChip(
                                label: 'Com replay',
                                layout: layout,
                              ),
                          ],
                        ),
                        SizedBox(height: layout.isTv ? 14 : 10),
                        FilledButton.icon(
                          onPressed: onPlay,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Assistir agora'),
                        ),
                      ],
                    ),
                  ),
                  if (layout.isTv) ...[
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 132,
                      child: BrandedArtwork(
                        imageUrl: item.iconUrl,
                        aspectRatio: 1,
                        fit: BoxFit.contain,
                        imagePadding: const EdgeInsets.all(14),
                        icon: Icons.live_tv_rounded,
                        placeholderLabel: 'Canal',
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

class _LiveHeroChip extends StatelessWidget {
  const _LiveHeroChip({required this.label, required this.layout});

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

class _LiveCatalogHeader extends StatelessWidget {
  const _LiveCatalogHeader({required this.layout, required this.totalItems});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Canais disponíveis • $totalItems',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: layout.isTv ? 24 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: layout.isTv ? 4 : 2),
                Text(
                  'Navegue e abra o player ao vivo com foco otimizado para TV.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.76),
                    fontSize: layout.isTv ? 13 : 12,
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
