import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/favorites/domain/entities/favorite_item.dart';
import '../../../../features/favorites/presentation/controllers/favorites_controller.dart';
import '../../../../features/player/domain/entities/playback_context.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
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

          return SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 880;
                        final poster = SizedBox(
                          width: isWide ? 280 : 220,
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
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Text('${item.seasonCount} temporadas'),
                                ),
                                Chip(
                                  label: Text('${item.episodeCount} episódios'),
                                ),
                                if (item.genre != null)
                                  Chip(label: Text(item.genre!)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: () => ref
                                  .read(favoritesControllerProvider.notifier)
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
                            if (item.plot != null &&
                                item.plot!.trim().isNotEmpty) ...[
                              const SizedBox(height: 28),
                              Text(
                                'Sinopse',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.plot!,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                            if (item.cast != null &&
                                item.cast!.trim().isNotEmpty) ...[
                              const SizedBox(height: 22),
                              Text(
                                'Elenco',
                                style: Theme.of(context).textTheme.titleMedium,
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
                              const SizedBox(height: 24),
                              details,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            poster,
                            const SizedBox(width: 28),
                            Expanded(child: details),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Episódios',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        if (item.episodes.isEmpty)
                          const Text(
                            'Nenhum episódio reproduzível foi encontrado neste acesso.',
                          ),
                        for (final seasonEntry in episodesBySeason.entries) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Temporada ${seasonEntry.key}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
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
                                if (episode.duration != null) episode.duration!,
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
                                      title: '${item.name} • ${episode.title}',
                                      containerExtension:
                                          episode.containerExtension,
                                    ),
                                  ),
                                ),
                              ];
                            }(),
                            if (index != seasonEntry.value.length - 1)
                              const SizedBox(height: 12),
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
      ),
    );
  }
}
