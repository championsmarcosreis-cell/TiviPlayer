import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/favorites/domain/entities/favorite_item.dart';
import '../../../../features/favorites/presentation/controllers/favorites_controller.dart';
import '../../../../features/player/domain/entities/playback_context.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/branded_artwork.dart';
import '../../../../shared/widgets/content_list_tile.dart';
import '../../domain/entities/series_episode.dart';
import '../providers/series_providers.dart';

class SeriesDetailsScreen extends ConsumerWidget {
  const SeriesDetailsScreen({super.key, required this.seriesId});

  static const routePath = '/series/details/:seriesId';

  static String buildLocation(String seriesId) => '/series/details/$seriesId';

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(seriesInfoProvider(seriesId));
    final favorites = ref.watch(favoritesControllerProvider);

    return AppScaffold(
      title: 'Séries',
      subtitle: 'Detalhes da coleção',
      showBack: true,
      child: AsyncStateBuilder(
        value: info,
        dataBuilder: (item) {
          final isFavorite = favorites.any(
            (entry) =>
                entry.contentType == 'series' && entry.contentId == item.id,
          );
          final episodesBySeason = <int, List<SeriesEpisode>>{};
          for (final episode in item.episodes) {
            episodesBySeason.putIfAbsent(episode.seasonNumber, () => []);
            episodesBySeason[episode.seasonNumber]!.add(episode);
          }

          return LayoutBuilder(
            builder: (context, outerConstraints) {
              final layout = DeviceLayout.of(
                context,
                constraints: outerConstraints,
              );

              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(layout.cardPadding),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide =
                                layout.isTv || constraints.maxWidth >= 860;
                            final poster = SizedBox(
                              width: layout.detailPosterWidth,
                              child: BrandedArtwork(
                                imageUrl: item.coverUrl,
                                aspectRatio: 2 / 3,
                                placeholderLabel: 'Capa indisponível',
                                icon: Icons.tv_outlined,
                              ),
                            );

                            final details = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontSize: layout.isTv ? 40 : 32,
                                      ),
                                ),
                                SizedBox(height: layout.sectionSpacing + 2),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _SeriesInfoPill(
                                      icon: Icons.video_collection_outlined,
                                      label: '${item.seasonCount} temporadas',
                                      layout: layout,
                                    ),
                                    _SeriesInfoPill(
                                      icon: Icons.playlist_play_rounded,
                                      label: '${item.episodeCount} episódios',
                                      layout: layout,
                                    ),
                                    if (item.genre?.trim().isNotEmpty == true)
                                      _SeriesInfoPill(
                                        icon: Icons.category_outlined,
                                        label: item.genre!,
                                        layout: layout,
                                      ),
                                  ],
                                ),
                                SizedBox(height: layout.sectionSpacing + 6),
                                SizedBox(
                                  width: layout.isMobilePortrait
                                      ? double.infinity
                                      : null,
                                  child: OutlinedButton.icon(
                                    onPressed: () => ref
                                        .read(
                                          favoritesControllerProvider.notifier,
                                        )
                                        .toggle(
                                          FavoriteItem(
                                            contentType: 'series',
                                            contentId: item.id,
                                            title: item.name,
                                          ),
                                        ),
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                    ),
                                    label: Text(
                                      isFavorite
                                          ? 'Remover dos favoritos'
                                          : 'Favoritar',
                                    ),
                                  ),
                                ),
                                if (item.plot != null &&
                                    item.plot!.trim().isNotEmpty) ...[
                                  SizedBox(height: layout.sectionSpacing + 8),
                                  Text(
                                    'Sinopse',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item.plot!,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ],
                                if (item.cast != null &&
                                    item.cast!.trim().isNotEmpty) ...[
                                  SizedBox(height: layout.sectionSpacing + 4),
                                  Text(
                                    'Elenco',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(item.cast!),
                                ],
                              ],
                            );

                            if (!isWide) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(child: poster),
                                  SizedBox(height: layout.sectionSpacing + 8),
                                  details,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                poster,
                                SizedBox(width: layout.cardSpacing + 10),
                                Expanded(child: details),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: layout.sectionSpacing + 8),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(layout.cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Episódios',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: layout.sectionSpacing),
                            if (item.episodes.isEmpty)
                              const Text(
                                'Nenhum episódio reproduzível foi encontrado neste acesso.',
                              ),
                            for (final seasonEntry
                                in episodesBySeason.entries) ...[
                              SizedBox(height: layout.sectionSpacing),
                              Text(
                                'Temporada ${seasonEntry.key}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: layout.cardSpacing - 2),
                              for (
                                var index = 0;
                                index < seasonEntry.value.length;
                                index++
                              ) ...[
                                ...() {
                                  final episode = seasonEntry.value[index];
                                  final subtitleParts = [
                                    if (episode.episodeNumber != null)
                                      'Ep. ${episode.episodeNumber}',
                                    if (episode.duration != null)
                                      episode.duration!,
                                  ];

                                  return [
                                    ContentListTile(
                                      autofocus:
                                          seasonEntry.key ==
                                              episodesBySeason.keys.first &&
                                          index == 0,
                                      title: episode.title,
                                      subtitle: subtitleParts.isEmpty
                                          ? null
                                          : subtitleParts.join(' • '),
                                      icon: Icons.play_circle_outline_rounded,
                                      onPressed: () => context.push(
                                        PlayerScreen.routePath,
                                        extra: PlaybackContext(
                                          contentType:
                                              PlaybackContentType.seriesEpisode,
                                          itemId: episode.id,
                                          title:
                                              '${item.name} • ${episode.title}',
                                          containerExtension:
                                              episode.containerExtension,
                                        ),
                                      ),
                                    ),
                                  ];
                                }(),
                                if (index != seasonEntry.value.length - 1)
                                  SizedBox(height: layout.cardSpacing),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SeriesInfoPill extends StatelessWidget {
  const _SeriesInfoPill({
    required this.icon,
    required this.label,
    required this.layout,
  });

  final IconData icon;
  final String label;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(maxWidth: layout.isTv ? 320 : 260),
      padding: EdgeInsets.symmetric(
        horizontal: layout.isTv ? 14 : 12,
        vertical: layout.isTv ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(layout.isTv ? 18 : 16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: layout.isTv ? 20 : 18, color: colorScheme.secondary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
