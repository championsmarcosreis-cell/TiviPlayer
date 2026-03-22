import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/tv/tv_focusable.dart';
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
import '../../domain/entities/series_info.dart';
import '../../domain/entities/series_item.dart';
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
    final relatedSeries = ref.watch(seriesItemsProvider(null));

    return AppScaffold(
      title: 'Séries',
      subtitle: 'Detalhes da coleção',
      showBack: true,
      showBrand: false,
      child: AsyncStateBuilder(
        value: info,
        dataBuilder: (item) {
          final isFavorite = favorites.any(
            (entry) =>
                entry.contentType == 'series' && entry.contentId == item.id,
          );
          final metadata = <String>[
            '${item.seasonCount} temporadas',
            '${item.episodeCount} episódios',
            if (item.genre?.trim().isNotEmpty == true) item.genre!.trim(),
          ];

          return LayoutBuilder(
            builder: (context, outerConstraints) {
              final layout = DeviceLayout.of(
                context,
                constraints: outerConstraints,
              );

              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SeriesCinematicHero(
                      item: item,
                      metadata: metadata,
                      isFavorite: isFavorite,
                      layout: layout,
                      onPlayFirstEpisode: () {
                        final episode = _resolveInitialEpisode(item.episodes);
                        if (episode == null) {
                          return;
                        }
                        _openEpisode(context, item, episode);
                      },
                      onToggleFavorite: () => ref
                          .read(favoritesControllerProvider.notifier)
                          .toggle(
                            FavoriteItem(
                              contentType: 'series',
                              contentId: item.id,
                              title: item.name,
                            ),
                          ),
                    ),
                    SizedBox(height: layout.sectionSpacing + 8),
                    _EpisodesBySeasonSection(item: item, layout: layout),
                    SizedBox(height: layout.sectionSpacing + 8),
                    _RelatedSeriesSection(
                      currentSeriesId: item.id,
                      relatedSeries: relatedSeries,
                      layout: layout,
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

SeriesEpisode? _resolveInitialEpisode(List<SeriesEpisode> episodes) {
  if (episodes.isEmpty) {
    return null;
  }

  final ordered = [...episodes]
    ..sort((a, b) {
      final seasonCompare = a.seasonNumber.compareTo(b.seasonNumber);
      if (seasonCompare != 0) {
        return seasonCompare;
      }

      final aEpisode = a.episodeNumber ?? 0;
      final bEpisode = b.episodeNumber ?? 0;
      return aEpisode.compareTo(bEpisode);
    });

  return ordered.first;
}

void _openEpisode(
  BuildContext context,
  SeriesInfo item,
  SeriesEpisode episode,
) {
  context.push(
    PlayerScreen.routePath,
    extra: PlaybackContext(
      contentType: PlaybackContentType.seriesEpisode,
      itemId: episode.id,
      title: '${item.name} • ${episode.title}',
      containerExtension: episode.containerExtension,
      artworkUrl: item.coverUrl,
    ),
  );
}

class _SeriesCinematicHero extends StatelessWidget {
  const _SeriesCinematicHero({
    required this.item,
    required this.metadata,
    required this.isFavorite,
    required this.layout,
    required this.onPlayFirstEpisode,
    required this.onToggleFavorite,
  });

  final SeriesInfo item;
  final List<String> metadata;
  final bool isFavorite;
  final DeviceLayout layout;
  final VoidCallback onPlayFirstEpisode;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backdrop = BrandedArtwork.normalizeArtworkUrl(item.coverUrl);
    final hasEpisodes = item.episodes.isNotEmpty;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 32 : 24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: layout.isTv ? 16 / 8.8 : 16 / 13.5,
            child: backdrop == null
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.surfaceContainerHighest,
                          colorScheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  )
                : Image.network(
                    backdrop,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    headers: const {'Accept-Encoding': 'identity'},
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xF8080D15),
                    const Color(0xD8080D15),
                    const Color(0x26080D15),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(layout.isTv ? 22 : 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = layout.isTv || constraints.maxWidth >= 860;
                final posterWidth = switch (layout.deviceClass) {
                  DeviceClass.tvLarge => 210.0,
                  DeviceClass.tvCompact => 190.0,
                  _ => layout.detailPosterWidth,
                };
                final poster = Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(layout.isTv ? 24 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.46),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  width: posterWidth,
                  child: BrandedArtwork(
                    imageUrl: item.coverUrl,
                    aspectRatio: 2 / 3,
                    placeholderLabel: 'Capa indisponível',
                    icon: Icons.tv_outlined,
                    borderRadius: layout.isTv ? 22 : 18,
                  ),
                );

                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'SÉRIE',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.3,
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: layout.isTv ? 6 : 6),
                    Text(
                      item.name,
                      maxLines: layout.isTv ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: layout.isTv ? 40 : 30,
                            height: 1.02,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (metadata.isNotEmpty) ...[
                      SizedBox(height: layout.isTv ? 10 : 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final value in metadata)
                            _MetadataChip(label: value, layout: layout),
                        ],
                      ),
                    ],
                    SizedBox(height: layout.isTv ? 14 : 12),
                    if (item.plot != null && item.plot!.trim().isNotEmpty)
                      Text(
                        item.plot!,
                        maxLines: layout.isTv ? 3 : 5,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: layout.isTv ? 16.5 : 14.2,
                          color: Colors.white.withValues(alpha: 0.92),
                          height: 1.35,
                        ),
                      ),
                    SizedBox(height: layout.isTv ? 14 : 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          autofocus: true,
                          onPressed: hasEpisodes ? onPlayFirstEpisode : null,
                          style: FilledButton.styleFrom(
                            minimumSize: Size(0, layout.isTv ? 66 : 54),
                          ),
                          icon: Icon(
                            Icons.play_arrow_rounded,
                            size: layout.isTv ? 34 : 24,
                          ),
                          label: Text(
                            hasEpisodes
                                ? 'Assistir episódio 1'
                                : 'Sem episódios',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: layout.isTv ? 24 : 18,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onToggleFavorite,
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(0, layout.isTv ? 62 : 50),
                          ),
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                          ),
                          label: Text(
                            isFavorite ? 'Nos favoritos' : 'Adicionar',
                          ),
                        ),
                      ],
                    ),
                  ],
                );

                if (!isWide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(alignment: Alignment.topLeft, child: poster),
                      SizedBox(height: layout.sectionSpacing + 8),
                      content,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    poster,
                    SizedBox(width: layout.cardSpacing + 6),
                    Expanded(child: content),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.label, required this.layout});

  final String label;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.isTv ? 11 : 9,
        vertical: layout.isTv ? 7 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.5),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
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

class _EpisodesBySeasonSection extends StatelessWidget {
  const _EpisodesBySeasonSection({required this.item, required this.layout});

  final SeriesInfo item;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final episodesBySeason = <int, List<SeriesEpisode>>{};
    for (final episode in item.episodes) {
      episodesBySeason.putIfAbsent(episode.seasonNumber, () => []);
      episodesBySeason[episode.seasonNumber]!.add(episode);
    }

    final orderedSeasons = episodesBySeason.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.isTv ? 20 : 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 22 : 17),
        gradient: LinearGradient(
          colors: [
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Episódios',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: layout.isTv ? 24 : 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: layout.isTv ? 6 : 4),
          Text(
            item.episodes.isEmpty
                ? 'Nenhum episódio disponível neste acesso.'
                : '${item.episodeCount} episódios em ${item.seasonCount} temporadas',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.74),
            ),
          ),
          if (item.episodes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'A coleção foi carregada, mas não há episódios reproduzíveis.',
              ),
            ),
          for (final seasonEntry in orderedSeasons) ...[
            SizedBox(height: layout.sectionSpacing),
            Text(
              'Temporada ${seasonEntry.key}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: layout.isTv ? 22 : 17,
              ),
            ),
            SizedBox(height: layout.cardSpacing - 2),
            for (var index = 0; index < seasonEntry.value.length; index++) ...[
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
                        seasonEntry == orderedSeasons.first && index == 0,
                    overline: 'Temporada ${seasonEntry.key}',
                    title: episode.title,
                    subtitle: subtitleParts.isEmpty
                        ? null
                        : subtitleParts.join(' • '),
                    icon: Icons.play_circle_outline_rounded,
                    badge: 'EP',
                    onPressed: () => _openEpisode(context, item, episode),
                  ),
                ];
              }(),
              if (index != seasonEntry.value.length - 1)
                SizedBox(height: layout.cardSpacing),
            ],
          ],
        ],
      ),
    );
  }
}

class _RelatedSeriesSection extends StatelessWidget {
  const _RelatedSeriesSection({
    required this.currentSeriesId,
    required this.relatedSeries,
    required this.layout,
  });

  final String currentSeriesId;
  final AsyncValue<List<SeriesItem>> relatedSeries;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    return relatedSeries.when(
      data: (items) {
        final related = items
            .where((entry) => entry.id != currentSeriesId)
            .take(layout.isTv ? 16 : 10)
            .toList();

        if (related.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Séries relacionadas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: layout.isTv ? 30 : 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: layout.isTv ? 4 : 2),
            Text(
              'Descoberta rápida no mesmo catálogo Xtream.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            SizedBox(height: layout.cardSpacing),
            SizedBox(
              height: layout.isTv ? 350 : 286,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (context, index) =>
                    SizedBox(width: layout.cardSpacing),
                itemBuilder: (context, index) {
                  final series = related[index];
                  return SizedBox(
                    width: layout.isTv ? 210 : 160,
                    child: _RelatedSeriesCard(
                      item: series,
                      layout: layout,
                      autofocus: index == 0,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _RelatedSeriesCard extends StatelessWidget {
  const _RelatedSeriesCard({
    required this.item,
    required this.layout,
    this.autofocus = false,
  });

  final SeriesItem item;
  final DeviceLayout layout;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusable(
      autofocus: autofocus,
      onPressed: () => context.push(SeriesDetailsScreen.buildLocation(item.id)),
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
                  fontSize: layout.isTv ? 16 : 15,
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
