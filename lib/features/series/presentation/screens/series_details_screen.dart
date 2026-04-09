import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/tv/tv_focusable.dart';
import '../../../../features/favorites/domain/entities/favorite_item.dart';
import '../../../../features/favorites/presentation/controllers/favorites_controller.dart';
import '../../../../features/player/domain/entities/playback_context.dart';
import '../../../../features/player/presentation/controllers/playback_history_controller.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../../../features/player/presentation/support/player_screen_arguments.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/presentation/support/on_demand_library.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/branded_artwork.dart';
import '../../../../shared/widgets/mobile_primary_dock.dart';
import '../../../../shared/widgets/on_demand_detail_panels.dart';
import '../../../../shared/widgets/on_demand_related_poster_card.dart';
import '../../domain/entities/series_episode.dart';
import '../../domain/entities/series_info.dart';
import '../../domain/entities/series_item.dart';
import '../providers/series_providers.dart';

class SeriesDetailsScreen extends ConsumerStatefulWidget {
  const SeriesDetailsScreen({super.key, required this.seriesId});

  static const routePath = '/series/details/:seriesId';

  static String buildLocation(String seriesId) => '/series/details/$seriesId';

  final String seriesId;

  @override
  ConsumerState<SeriesDetailsScreen> createState() =>
      _SeriesDetailsScreenState();
}

class _SeriesDetailsScreenState extends ConsumerState<SeriesDetailsScreen> {
  int? _selectedSeason;

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(seriesInfoProvider(widget.seriesId));
    final favorites = ref.watch(favoritesControllerProvider);
    final relatedSeries = ref.watch(seriesItemsProvider(null));
    ref.watch(playbackHistoryControllerProvider);
    final playbackHistoryController = ref.read(
      playbackHistoryControllerProvider.notifier,
    );

    return AppScaffold(
      title: 'Séries',
      subtitle: 'Detalhes da coleção',
      showBack: false,
      showBrand: false,
      showHeader: false,
      showTvSidebar: false,
      mobileBottomBar: const MobilePrimaryDock(),
      child: AsyncStateBuilder(
        value: info,
        dataBuilder: (item) {
          final isFavorite = favorites.any(
            (entry) =>
                entry.contentType == 'series' && entry.contentId == item.id,
          );
          final resumeEpisode = _resolveResumeEpisode(
            episodes: item.episodes,
            playbackHistoryController: playbackHistoryController,
          );
          final initialEpisode = _resolveInitialEpisode(item.episodes);
          final primaryEpisode = resumeEpisode ?? initialEpisode;
          final shouldResumePrimaryEpisode = resumeEpisode != null;
          final seasons = _groupEpisodesBySeason(item.episodes);

          return LayoutBuilder(
            builder: (context, outerConstraints) {
              final layout = DeviceLayout.of(
                context,
                constraints: outerConstraints,
              );
              final preferredSeason =
                  _selectedSeason ?? primaryEpisode?.seasonNumber;
              final selectedSeason =
                  seasons.any((entry) => entry.key == preferredSeason)
                  ? preferredSeason
                  : seasons.isEmpty
                  ? null
                  : seasons.first.key;

              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!layout.isTv) ...[
                      _SeriesInlineHeader(
                        onBack: () {
                          if (context.canPop()) {
                            context.pop();
                          }
                        },
                      ),
                      SizedBox(height: layout.sectionSpacing + 6),
                    ],
                    _SeriesEditorialHero(
                      item: item,
                      layout: layout,
                      isFavorite: isFavorite,
                      heroTags: _buildSeriesHeroTags(item),
                      playActionLabel: item.episodes.isEmpty
                          ? 'Sem episódios'
                          : shouldResumePrimaryEpisode
                          ? 'Retomar episódio'
                          : 'Assistir primeiro episódio',
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                      onPlayPrimaryEpisode: item.episodes.isEmpty
                          ? null
                          : () {
                              final episode = primaryEpisode;
                              if (episode == null) {
                                return;
                              }
                              _openEpisode(
                                context,
                                item,
                                episode,
                                playbackHistoryController,
                              );
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
                    SizedBox(height: layout.isTv ? 26 : 22),
                    if (layout.isTv)
                      _SeriesTvBody(
                        item: item,
                        layout: layout,
                        primaryEpisode: primaryEpisode,
                        shouldResumePrimaryEpisode: shouldResumePrimaryEpisode,
                        seasons: seasons,
                        selectedSeason: selectedSeason,
                        onSelectedSeason: (season) {
                          if (_selectedSeason == season) {
                            return;
                          }
                          setState(() {
                            _selectedSeason = season;
                          });
                        },
                        playbackHistoryController: playbackHistoryController,
                        relatedSeries: relatedSeries,
                      )
                    else
                      _SeriesMobileBody(
                        item: item,
                        layout: layout,
                        primaryEpisode: primaryEpisode,
                        shouldResumePrimaryEpisode: shouldResumePrimaryEpisode,
                        seasons: seasons,
                        selectedSeason: selectedSeason,
                        onSelectedSeason: (season) {
                          if (_selectedSeason == season) {
                            return;
                          }
                          setState(() {
                            _selectedSeason = season;
                          });
                        },
                        playbackHistoryController: playbackHistoryController,
                        relatedSeries: relatedSeries,
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

  return _orderEpisodes(episodes).first;
}

SeriesEpisode? _resolveResumeEpisode({
  required List<SeriesEpisode> episodes,
  required PlaybackHistoryController playbackHistoryController,
}) {
  if (episodes.isEmpty) {
    return null;
  }

  final historyEntry = playbackHistoryController.findMostRecentEntry(
    contentType: PlaybackContentType.seriesEpisode,
    itemIds: episodes.map((episode) => episode.id),
  );
  if (historyEntry == null ||
      playbackHistoryController.resolveResumePosition(
            PlaybackContentType.seriesEpisode,
            historyEntry.itemId,
          ) ==
          null) {
    return null;
  }

  for (final episode in episodes) {
    if (episode.id == historyEntry.itemId) {
      return episode;
    }
  }
  return null;
}

List<SeriesEpisode> _orderEpisodes(List<SeriesEpisode> episodes) {
  return [...episodes]..sort((a, b) {
    final seasonCompare = a.seasonNumber.compareTo(b.seasonNumber);
    if (seasonCompare != 0) {
      return seasonCompare;
    }

    final aEpisode = a.episodeNumber ?? 0;
    final bEpisode = b.episodeNumber ?? 0;
    return aEpisode.compareTo(bEpisode);
  });
}

void _openEpisode(
  BuildContext context,
  SeriesInfo item,
  SeriesEpisode episode,
  PlaybackHistoryController playbackHistoryController,
) {
  final orderedEpisodes = _orderEpisodes(item.episodes);
  final currentIndex = orderedEpisodes.indexWhere(
    (candidate) => candidate.id == episode.id,
  );

  if (currentIndex >= 0) {
    final navigation = PlayerOnDemandNavigation(
      items: [
        for (final candidate in orderedEpisodes)
          PlayerOnDemandNavigationItem(
            contentType: PlaybackContentType.seriesEpisode,
            itemId: candidate.id,
            title: '${item.name} • ${candidate.title}',
            containerExtension: candidate.containerExtension,
            artworkUrl: item.coverUrl,
            backdropUrl: item.backdropUrl,
            seriesId: item.id,
            resumePosition: playbackHistoryController.resolveResumePosition(
              PlaybackContentType.seriesEpisode,
              candidate.id,
            ),
          ),
      ],
      currentIndex: currentIndex,
    );

    context.push(
      PlayerScreen.routePath,
      extra: PlayerScreenArguments.onDemand(navigation),
    );
    return;
  }

  context.push(
    PlayerScreen.routePath,
    extra: PlaybackContext(
      contentType: PlaybackContentType.seriesEpisode,
      itemId: episode.id,
      title: '${item.name} • ${episode.title}',
      containerExtension: episode.containerExtension,
      artworkUrl: item.coverUrl,
      backdropUrl: item.backdropUrl,
      seriesId: item.id,
      resumePosition: playbackHistoryController.resolveResumePosition(
        PlaybackContentType.seriesEpisode,
        episode.id,
      ),
      capabilities: const PlaybackSessionCapabilities.onDemand(),
    ),
  );
}

class _SeriesEditorialHero extends StatelessWidget {
  const _SeriesEditorialHero({
    required this.item,
    required this.layout,
    required this.isFavorite,
    required this.heroTags,
    required this.playActionLabel,
    required this.onBack,
    required this.onPlayPrimaryEpisode,
    required this.onToggleFavorite,
  });

  final SeriesInfo item;
  final DeviceLayout layout;
  final bool isFavorite;
  final List<({String label, IconData icon})> heroTags;
  final String playActionLabel;
  final VoidCallback onBack;
  final VoidCallback? onPlayPrimaryEpisode;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final posterWidth = switch (layout.deviceClass) {
      DeviceClass.tvLarge => 248.0,
      DeviceClass.tvCompact => 224.0,
      DeviceClass.tablet => 220.0,
      DeviceClass.mobileLandscape => 186.0,
      DeviceClass.mobilePortrait => 168.0,
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 36 : 28),
        gradient: const LinearGradient(
          colors: [Color(0x22182A25), Color(0x100B1412), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: layout.isTv ? -40 : -24,
            top: layout.isTv ? -18 : -10,
            child: _HeroGlow(
              size: layout.isTv ? 320 : 220,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.11),
            ),
          ),
          Positioned(
            right: layout.isTv ? 90 : -12,
            bottom: layout.isTv ? -24 : 24,
            child: _HeroGlow(
              size: layout.isTv ? 260 : 180,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              layout.isTv ? 28 : 0,
              layout.isTv ? 24 : 0,
              layout.isTv ? 28 : 0,
              layout.isTv ? 26 : 0,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = layout.isTv || constraints.maxWidth >= 760;
                final poster = DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(layout.isTv ? 26 : 22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.34),
                        blurRadius: layout.isTv ? 28 : 18,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: posterWidth,
                    child: BrandedArtwork(
                      imageUrl: item.coverUrl,
                      aspectRatio: 2 / 3,
                      borderRadius: layout.isTv ? 24 : 20,
                      placeholderLabel: 'Capa indisponível',
                      icon: Icons.tv_outlined,
                      chrome: BrandedArtworkChrome.subtle,
                    ),
                  ),
                );

                final content = _SeriesHeroContent(
                  item: item,
                  layout: layout,
                  isFavorite: isFavorite,
                  heroTags: heroTags,
                  playActionLabel: playActionLabel,
                  onPlayPrimaryEpisode: onPlayPrimaryEpisode,
                  onToggleFavorite: onToggleFavorite,
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
                    SizedBox(width: layout.isTv ? 28 : 20),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: content,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (layout.isTv)
            Positioned(
              top: 0,
              left: 0,
              child: _SeriesHeroBackButton(onPressed: onBack),
            ),
        ],
      ),
    );
  }
}

class _SeriesHeroContent extends StatelessWidget {
  const _SeriesHeroContent({
    required this.item,
    required this.layout,
    required this.isFavorite,
    required this.heroTags,
    required this.playActionLabel,
    required this.onPlayPrimaryEpisode,
    required this.onToggleFavorite,
  });

  final SeriesInfo item;
  final DeviceLayout layout;
  final bool isFavorite;
  final List<({String label, IconData icon})> heroTags;
  final String playActionLabel;
  final VoidCallback? onPlayPrimaryEpisode;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final synopsis = _seriesSynopsis(item);
    final primaryStyle =
        FilledButton.styleFrom(
          minimumSize: Size(0, layout.isTv ? 62 : 52),
          padding: EdgeInsets.symmetric(
            horizontal: layout.isTv ? 22 : 18,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const Color(0xFFFFF3E7);
            }
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.86);
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const Color(0xFF161005);
            }
            return colorScheme.onPrimary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: colorScheme.secondary, width: 2.6);
            }
            return BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.78),
            );
          }),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused) ? 10 : 0,
          ),
        );
    final secondaryStyle =
        OutlinedButton.styleFrom(
          minimumSize: Size(0, layout.isTv ? 58 : 50),
          padding: EdgeInsets.symmetric(
            horizontal: layout.isTv ? 20 : 16,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
          foregroundColor: colorScheme.onSurface,
          backgroundColor: Colors.white.withValues(alpha: 0.03),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.52,
              );
            }
            return Colors.white.withValues(alpha: 0.03);
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: colorScheme.primary, width: 2);
            }
            return BorderSide(color: Colors.white.withValues(alpha: 0.22));
          }),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SÉRIE',
          style: textTheme.labelLarge?.copyWith(
            letterSpacing: 0.96,
            color: colorScheme.secondary.withValues(alpha: 0.96),
            fontWeight: FontWeight.w700,
            fontSize: layout.isTv ? 12.5 : null,
          ),
        ),
        SizedBox(height: layout.isTv ? 8 : 6),
        Text(
          item.name,
          maxLines: layout.isTv ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: textTheme.headlineLarge?.copyWith(
            fontSize: layout.isTv ? 39 : 31,
            fontWeight: FontWeight.w700,
            height: 1.02,
          ),
        ),
        if (heroTags.isNotEmpty) ...[
          SizedBox(height: layout.isTv ? 14 : 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final tag in heroTags)
                OnDemandDetailTag(label: tag.label, icon: tag.icon),
            ],
          ),
        ],
        SizedBox(height: layout.isTv ? 18 : 14),
        Text(
          synopsis,
          maxLines: layout.isTv ? 4 : 7,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyLarge?.copyWith(
            fontSize: layout.isTv ? 15.5 : 14.8,
            height: 1.55,
            color: colorScheme.onSurface.withValues(alpha: 0.9),
          ),
        ),
        SizedBox(height: layout.isTv ? 20 : 16),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              autofocus: layout.isTv && onPlayPrimaryEpisode != null,
              onPressed: onPlayPrimaryEpisode,
              style: primaryStyle,
              icon: Icon(Icons.play_arrow_rounded, size: layout.isTv ? 28 : 22),
              label: Text(
                playActionLabel,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: layout.isTv ? 19 : 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onToggleFavorite,
              style: secondaryStyle,
              icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              label: Text(isFavorite ? 'Nos favoritos' : 'Adicionar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SeriesTvBody extends StatelessWidget {
  const _SeriesTvBody({
    required this.item,
    required this.layout,
    required this.primaryEpisode,
    required this.shouldResumePrimaryEpisode,
    required this.seasons,
    required this.selectedSeason,
    required this.onSelectedSeason,
    required this.playbackHistoryController,
    required this.relatedSeries,
  });

  final SeriesInfo item;
  final DeviceLayout layout;
  final SeriesEpisode? primaryEpisode;
  final bool shouldResumePrimaryEpisode;
  final List<MapEntry<int, List<SeriesEpisode>>> seasons;
  final int? selectedSeason;
  final ValueChanged<int> onSelectedSeason;
  final PlaybackHistoryController playbackHistoryController;
  final AsyncValue<List<SeriesItem>> relatedSeries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SeriesTvEpisodesSection(
          item: item,
          layout: layout,
          primaryEpisode: primaryEpisode,
          shouldResumePrimaryEpisode: shouldResumePrimaryEpisode,
          seasons: seasons,
          selectedSeason: selectedSeason,
          onSelectedSeason: onSelectedSeason,
          playbackHistoryController: playbackHistoryController,
        ),
        SizedBox(height: layout.sectionSpacing + 8),
        _RelatedSeriesSection(
          currentSeriesId: item.id,
          relatedSeries: relatedSeries,
          layout: layout,
          title: 'Relacionados',
        ),
      ],
    );
  }
}

class _SeriesMobileBody extends StatelessWidget {
  const _SeriesMobileBody({
    required this.item,
    required this.layout,
    required this.primaryEpisode,
    required this.shouldResumePrimaryEpisode,
    required this.seasons,
    required this.selectedSeason,
    required this.onSelectedSeason,
    required this.playbackHistoryController,
    required this.relatedSeries,
  });

  final SeriesInfo item;
  final DeviceLayout layout;
  final SeriesEpisode? primaryEpisode;
  final bool shouldResumePrimaryEpisode;
  final List<MapEntry<int, List<SeriesEpisode>>> seasons;
  final int? selectedSeason;
  final ValueChanged<int> onSelectedSeason;
  final PlaybackHistoryController playbackHistoryController;
  final AsyncValue<List<SeriesItem>> relatedSeries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SeriesMobileEpisodesSection(
          item: item,
          layout: layout,
          primaryEpisode: primaryEpisode,
          shouldResumePrimaryEpisode: shouldResumePrimaryEpisode,
          seasons: seasons,
          selectedSeason: selectedSeason,
          onSelectedSeason: onSelectedSeason,
          playbackHistoryController: playbackHistoryController,
        ),
        SizedBox(height: layout.sectionSpacing + 8),
        _RelatedSeriesSection(
          currentSeriesId: item.id,
          relatedSeries: relatedSeries,
          layout: layout,
          title: 'Relacionados',
        ),
      ],
    );
  }
}

class _SeriesTvEpisodesSection extends StatelessWidget {
  const _SeriesTvEpisodesSection({
    required this.item,
    required this.layout,
    required this.primaryEpisode,
    required this.shouldResumePrimaryEpisode,
    required this.seasons,
    required this.selectedSeason,
    required this.onSelectedSeason,
    required this.playbackHistoryController,
  });

  final SeriesInfo item;
  final DeviceLayout layout;
  final SeriesEpisode? primaryEpisode;
  final bool shouldResumePrimaryEpisode;
  final List<MapEntry<int, List<SeriesEpisode>>> seasons;
  final int? selectedSeason;
  final ValueChanged<int> onSelectedSeason;
  final PlaybackHistoryController playbackHistoryController;

  @override
  Widget build(BuildContext context) {
    final selectedEntry = selectedSeason == null
        ? null
        : seasons.where((season) => season.key == selectedSeason).firstOrNull;
    final featuredEpisode = _resolveSeasonFeaturedEpisode(
      selectedEntry,
      primaryEpisode,
    );
    final shouldResumeFeaturedEpisode =
        shouldResumePrimaryEpisode && featuredEpisode?.id == primaryEpisode?.id;

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: colorScheme.outline.withValues(alpha: 0.14), height: 1),
        SizedBox(height: layout.sectionSpacing + 6),
        _SeriesTvEpisodesHeader(
          layout: layout,
          seasonEntry: selectedEntry,
          featuredEpisode: featuredEpisode,
          shouldResumeFeaturedEpisode: shouldResumeFeaturedEpisode,
        ),
        SizedBox(height: layout.sectionSpacing + 6),
        if (seasons.isEmpty)
          Text(
            'Sem temporadas disponíveis no catálogo.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final episodesPanel = _SeriesEpisodesPanel(
                item: item,
                layout: layout,
                seasonEntry: selectedEntry,
                featuredEpisode: featuredEpisode,
                shouldResumeFeaturedEpisode: shouldResumeFeaturedEpisode,
                playbackHistoryController: playbackHistoryController,
              );

              if (constraints.maxWidth < 980) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SeriesTvSeasonMenu(
                      layout: layout,
                      seasons: seasons,
                      selectedSeason: selectedSeason,
                      onSelectedSeason: onSelectedSeason,
                    ),
                    SizedBox(height: layout.sectionSpacing + 6),
                    episodesPanel,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: constraints.maxWidth >= 1220 ? 264 : 236,
                    child: _SeriesTvSeasonMenu(
                      layout: layout,
                      seasons: seasons,
                      selectedSeason: selectedSeason,
                      onSelectedSeason: onSelectedSeason,
                    ),
                  ),
                  SizedBox(width: layout.cardSpacing + 8),
                  Expanded(child: episodesPanel),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _SeriesTvEpisodesHeader extends StatelessWidget {
  const _SeriesTvEpisodesHeader({
    required this.layout,
    required this.seasonEntry,
    required this.featuredEpisode,
    required this.shouldResumeFeaturedEpisode,
  });

  final DeviceLayout layout;
  final MapEntry<int, List<SeriesEpisode>>? seasonEntry;
  final SeriesEpisode? featuredEpisode;
  final bool shouldResumeFeaturedEpisode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedSeason = seasonEntry;
    final plot = featuredEpisode == null
        ? null
        : _episodePlot(featuredEpisode!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TEMPORADAS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            letterSpacing: 0.9,
            color: colorScheme.secondary.withValues(alpha: 0.92),
            fontWeight: FontWeight.w700,
            fontSize: layout.isTv ? 12.5 : null,
          ),
        ),
        SizedBox(height: layout.isTv ? 10 : 8),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              selectedSeason == null
                  ? 'Episódios indisponíveis'
                  : 'Temporada ${selectedSeason.key}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: layout.isTv ? 27 : 24,
                fontWeight: FontWeight.w700,
                height: 1.04,
              ),
            ),
            if (selectedSeason != null)
              Text(
                '${selectedSeason.value.length} episódios',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w700,
                  fontSize: layout.isTv ? 14.5 : null,
                ),
              ),
            if (featuredEpisode != null)
              Text(
                shouldResumeFeaturedEpisode
                    ? 'Retomar em ${_episodeLabel(featuredEpisode!)}'
                    : 'Entrada sugerida: ${_episodeLabel(featuredEpisode!)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
        if (plot != null) ...[
          SizedBox(height: layout.isTv ? 10 : 8),
          Text(
            plot,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: colorScheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
        ],
      ],
    );
  }
}

class _SeriesMobileEpisodesSection extends StatelessWidget {
  const _SeriesMobileEpisodesSection({
    required this.item,
    required this.layout,
    required this.primaryEpisode,
    required this.shouldResumePrimaryEpisode,
    required this.seasons,
    required this.selectedSeason,
    required this.onSelectedSeason,
    required this.playbackHistoryController,
  });

  final SeriesInfo item;
  final DeviceLayout layout;
  final SeriesEpisode? primaryEpisode;
  final bool shouldResumePrimaryEpisode;
  final List<MapEntry<int, List<SeriesEpisode>>> seasons;
  final int? selectedSeason;
  final ValueChanged<int> onSelectedSeason;
  final PlaybackHistoryController playbackHistoryController;

  @override
  Widget build(BuildContext context) {
    final selectedEntry = selectedSeason == null
        ? null
        : seasons.where((season) => season.key == selectedSeason).firstOrNull;
    final featuredEpisode = _resolveSeasonFeaturedEpisode(
      selectedEntry,
      primaryEpisode,
    );
    final shouldResumeFeaturedEpisode =
        shouldResumePrimaryEpisode && featuredEpisode?.id == primaryEpisode?.id;

    return OnDemandDetailSection(
      layout: layout,
      eyebrow: 'TEMPORADAS',
      title: 'Temporadas e episódios',
      subtitle: seasons.isEmpty
          ? 'O catálogo atual não retornou temporadas para esta série.'
          : selectedEntry == null
          ? 'Selecione uma temporada para navegar.'
          : '${selectedEntry.value.length} episódios na temporada ${selectedEntry.key}.',
      child: seasons.isEmpty
          ? Text(
              'Sem temporadas disponíveis no catálogo.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SeriesMobileSeasonDropdown(
                  layout: layout,
                  seasons: seasons,
                  selectedSeason: selectedSeason!,
                  onSelectedSeason: onSelectedSeason,
                ),
                SizedBox(height: layout.sectionSpacing + 2),
                _SeriesEpisodesPanel(
                  item: item,
                  layout: layout,
                  seasonEntry: selectedEntry,
                  featuredEpisode: featuredEpisode,
                  shouldResumeFeaturedEpisode: shouldResumeFeaturedEpisode,
                  playbackHistoryController: playbackHistoryController,
                ),
              ],
            ),
    );
  }
}

class _SeriesTvSeasonMenu extends StatefulWidget {
  const _SeriesTvSeasonMenu({
    required this.layout,
    required this.seasons,
    required this.selectedSeason,
    required this.onSelectedSeason,
  });

  final DeviceLayout layout;
  final List<MapEntry<int, List<SeriesEpisode>>> seasons;
  final int? selectedSeason;
  final ValueChanged<int> onSelectedSeason;

  @override
  State<_SeriesTvSeasonMenu> createState() => _SeriesTvSeasonMenuState();
}

class _SeriesTvSeasonMenuState extends State<_SeriesTvSeasonMenu> {
  final FocusNode _toggleFocusNode = FocusNode(
    debugLabel: 'seriesSeasonToggle',
  );
  final ScrollController _listController = ScrollController();
  final Map<int, FocusNode> _seasonFocusNodes = <int, FocusNode>{};
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _SeriesTvSeasonMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    final validKeys = widget.seasons.map((entry) => entry.key).toSet();
    final staleKeys = _seasonFocusNodes.keys
        .where((key) => !validKeys.contains(key))
        .toList();
    for (final key in staleKeys) {
      _seasonFocusNodes.remove(key)?.dispose();
    }
  }

  @override
  void dispose() {
    _toggleFocusNode.dispose();
    _listController.dispose();
    for (final focusNode in _seasonFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  FocusNode _focusNodeForSeason(int seasonNumber) {
    return _seasonFocusNodes.putIfAbsent(
      seasonNumber,
      () => FocusNode(debugLabel: 'seriesSeason.$seasonNumber'),
    );
  }

  void _toggleExpanded() {
    final nextValue = !_expanded;
    setState(() {
      _expanded = nextValue;
    });

    if (nextValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final targetSeason =
            widget.selectedSeason ?? widget.seasons.firstOrNull?.key;
        if (targetSeason == null) {
          return;
        }
        _focusNodeForSeason(targetSeason).requestFocus();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _toggleFocusNode.requestFocus();
        }
      });
    }
  }

  void _selectSeason(int seasonNumber) {
    widget.onSelectedSeason(seasonNumber);
    if (_expanded) {
      setState(() {
        _expanded = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _toggleFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedSeasonEntry = widget.selectedSeason == null
        ? null
        : widget.seasons
              .where((season) => season.key == widget.selectedSeason)
              .firstOrNull;
    final selectedLabel = selectedSeasonEntry == null
        ? 'Escolher temporada'
        : 'Temporada ${selectedSeasonEntry.key}';
    final selectedSubtitle = selectedSeasonEntry == null
        ? 'Sem temporada ativa'
        : '${selectedSeasonEntry.value.length} episódios';
    final showCompactActions = widget.seasons.length > 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Text(
            'ESCOLHA A TEMPORADA',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 0.88,
              color: colorScheme.onSurface.withValues(alpha: 0.58),
              fontWeight: FontWeight.w700,
              fontSize: widget.layout.isTv ? 12 : null,
            ),
          ),
        ),
        SizedBox(height: widget.layout.sectionSpacing - 4),
        _SeriesTvSeasonToggleButton(
          focusNode: _toggleFocusNode,
          label: selectedLabel,
          subtitle: selectedSubtitle,
          expanded: _expanded,
          onPressed: _toggleExpanded,
        ),
        if (showCompactActions) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SeriesTvJumpButton(
                label: 'Primeira',
                onPressed: () => _selectSeason(widget.seasons.first.key),
              ),
              _SeriesTvJumpButton(
                label: 'Última',
                onPressed: () => _selectSeason(widget.seasons.last.key),
              ),
            ],
          ),
        ],
        if (_expanded) ...[
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: widget.seasons.length > 5
                  ? 360
                  : widget.seasons.length * 68,
            ),
            child: Scrollbar(
              controller: _listController,
              thumbVisibility: true,
              child: ListView.separated(
                controller: _listController,
                shrinkWrap: true,
                itemCount: widget.seasons.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final season = widget.seasons[index];
                  return OnDemandTvRailButton(
                    focusNode: _focusNodeForSeason(season.key),
                    label: 'Temporada ${season.key}',
                    subtitle: '${season.value.length} episódios',
                    selected: season.key == widget.selectedSeason,
                    onPressed: () => _selectSeason(season.key),
                    onFocused: () => widget.onSelectedSeason(season.key),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SeriesTvSeasonToggleButton extends StatelessWidget {
  const _SeriesTvSeasonToggleButton({
    required this.focusNode,
    required this.label,
    required this.subtitle,
    required this.expanded,
    required this.onPressed,
  });

  final FocusNode focusNode;
  final String label;
  final String subtitle;
  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusable(
      focusNode: focusNode,
      onPressed: onPressed,
      builder: (context, focused) {
        final active = focused || expanded;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
          decoration: BoxDecoration(
            color: focused
                ? colorScheme.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: active
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.14),
                width: active ? 3 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.64),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: active
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.5),
                size: 26,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SeriesTvJumpButton extends StatelessWidget {
  const _SeriesTvJumpButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusable(
      onPressed: onPressed,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: focused
                ? colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: focused
                  ? colorScheme.primary.withValues(alpha: 0.48)
                  : colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: focused
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
        );
      },
    );
  }
}

class _SeriesMobileSeasonDropdown extends StatelessWidget {
  const _SeriesMobileSeasonDropdown({
    required this.layout,
    required this.seasons,
    required this.selectedSeason,
    required this.onSelectedSeason,
  });

  final DeviceLayout layout;
  final List<MapEntry<int, List<SeriesEpisode>>> seasons;
  final int selectedSeason;
  final ValueChanged<int> onSelectedSeason;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: layout.isTv ? 18 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(layout.isTv ? 22 : 18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.16)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedSeason,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(18),
          dropdownColor: colorScheme.surfaceContainerHigh,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          items: [
            for (final season in seasons)
              DropdownMenuItem<int>(
                value: season.key,
                child: Text(
                  'Temporada ${season.key} • ${season.value.length} eps',
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              onSelectedSeason(value);
            }
          },
        ),
      ),
    );
  }
}

class _SeriesEpisodesPanel extends StatelessWidget {
  const _SeriesEpisodesPanel({
    required this.item,
    required this.layout,
    required this.seasonEntry,
    required this.featuredEpisode,
    required this.shouldResumeFeaturedEpisode,
    required this.playbackHistoryController,
  });

  final SeriesInfo item;
  final DeviceLayout layout;
  final MapEntry<int, List<SeriesEpisode>>? seasonEntry;
  final SeriesEpisode? featuredEpisode;
  final bool shouldResumeFeaturedEpisode;
  final PlaybackHistoryController playbackHistoryController;

  @override
  Widget build(BuildContext context) {
    final selectedSeason = seasonEntry;
    if (selectedSeason == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (layout.isTv && featuredEpisode != null)
          SizedBox(height: layout.sectionSpacing - 4),
        for (var index = 0; index < selectedSeason.value.length; index++)
          _SeriesEpisodeRow(
            layout: layout,
            episode: selectedSeason.value[index],
            autofocus: index == 0 && !layout.isTv,
            emphasized: selectedSeason.value[index].id == featuredEpisode?.id,
            emphasisLabel: selectedSeason.value[index].id == featuredEpisode?.id
                ? shouldResumeFeaturedEpisode
                      ? 'RETOMAR'
                      : 'ENTRADA'
                : null,
            showDivider: index != selectedSeason.value.length - 1,
            onPressed: () => _openEpisode(
              context,
              item,
              selectedSeason.value[index],
              playbackHistoryController,
            ),
          ),
      ],
    );
  }
}

class _SeriesEpisodeRow extends StatelessWidget {
  const _SeriesEpisodeRow({
    required this.layout,
    required this.episode,
    required this.onPressed,
    this.autofocus = false,
    this.emphasized = false,
    this.emphasisLabel,
    this.showDivider = true,
  });

  final DeviceLayout layout;
  final SeriesEpisode episode;
  final VoidCallback onPressed;
  final bool autofocus;
  final bool emphasized;
  final String? emphasisLabel;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final plot = _episodePlot(episode);

    return TvFocusable(
      autofocus: autofocus,
      onPressed: onPressed,
      builder: (context, focused) {
        final highlighted = focused || emphasized;

        if (layout.isTv) {
          final metadata = [
            _episodeLabel(episode).toUpperCase(),
            if (episode.duration?.trim().isNotEmpty == true)
              episode.duration!.trim(),
            if (emphasisLabel?.trim().isNotEmpty == true) emphasisLabel!,
          ];

          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.fromLTRB(0, 14, 4, 14),
                decoration: BoxDecoration(
                  color: focused
                      ? colorScheme.primary.withValues(alpha: 0.06)
                      : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: highlighted
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: highlighted ? 3 : 0,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _episodeBadge(episode),
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: highlighted
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.82,
                                      ),
                                height: 1,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              for (
                                var index = 0;
                                index < metadata.length;
                                index++
                              )
                                Text(
                                  metadata[index],
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        letterSpacing: 0.64,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                        color: metadata[index] == emphasisLabel
                                            ? colorScheme.primary
                                            : colorScheme.onSurface.withValues(
                                                alpha: 0.58,
                                              ),
                                      ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            episode.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  height: 1.12,
                                ),
                          ),
                          if (plot != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              plot,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 13.5,
                                    height: 1.5,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.76,
                                    ),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 24,
                        color: focused
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (showDivider)
                Padding(
                  padding: const EdgeInsets.only(left: 88),
                  child: Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
            ],
          );
        }

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: EdgeInsets.symmetric(
                horizontal: layout.isTv ? 14 : 10,
                vertical: layout.isTv ? 14 : 12,
              ),
              decoration: BoxDecoration(
                color: focused
                    ? colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.28,
                      )
                    : emphasized
                    ? colorScheme.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(layout.isTv ? 20 : 16),
                border: focused
                    ? Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.42),
                        width: 1.2,
                      )
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: layout.isTv ? 62 : 56,
                    padding: EdgeInsets.symmetric(
                      horizontal: layout.isTv ? 10 : 8,
                      vertical: layout.isTv ? 8 : 7,
                    ),
                    decoration: BoxDecoration(
                      color: highlighted
                          ? colorScheme.primary.withValues(alpha: 0.12)
                          : colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.18,
                            ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _episodeBadge(episode),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: layout.isTv ? 17 : null,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'EP',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                letterSpacing: 0.64,
                                fontWeight: FontWeight.w700,
                                fontSize: layout.isTv ? 10 : null,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.62,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: layout.isTv ? 14 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _episodeLabel(episode).toUpperCase(),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    letterSpacing: 0.76,
                                    fontWeight: FontWeight.w700,
                                    fontSize: layout.isTv ? 11.5 : null,
                                    color: colorScheme.secondary.withValues(
                                      alpha: 0.88,
                                    ),
                                  ),
                            ),
                            if (emphasisLabel?.trim().isNotEmpty == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  emphasisLabel!,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                        fontSize: layout.isTv ? 10 : null,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: layout.isTv ? 6 : 5),
                        Text(
                          episode.title,
                          maxLines: layout.isTv ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: layout.isTv ? 19 : 17,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                        ),
                        if (episode.duration?.trim().isNotEmpty == true) ...[
                          SizedBox(height: layout.isTv ? 6 : 5),
                          Text(
                            episode.duration!.trim(),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.68,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  fontSize: layout.isTv ? 12.5 : null,
                                ),
                          ),
                        ],
                        if (plot != null) ...[
                          SizedBox(height: layout.isTv ? 8 : 7),
                          Text(
                            plot,
                            maxLines: layout.isTv ? 3 : 4,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: layout.isTv ? 13.5 : null,
                                  height: 1.45,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.78,
                                  ),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: layout.isTv ? 12 : 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.play_circle_outline_rounded,
                      size: layout.isTv ? 28 : 24,
                      color: focused
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.46),
                    ),
                  ),
                ],
              ),
            ),
            if (showDivider)
              Padding(
                padding: EdgeInsets.only(
                  left: layout.isTv ? 76 : 68,
                  right: layout.isTv ? 8 : 6,
                ),
                child: Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HeroGlow extends StatelessWidget {
  const _HeroGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

class _SeriesInlineHeader extends StatelessWidget {
  const _SeriesInlineHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Text(
          'Detalhe',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SeriesHeroBackButton extends StatelessWidget {
  const _SeriesHeroBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 74,
      height: 74,
      child: TvFocusable(
        onPressed: onPressed,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: focused
                  ? const Color(0xFFFFF3E7)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: focused
                    ? colorScheme.secondary
                    : Colors.white.withValues(alpha: 0.16),
                width: focused ? 2.6 : 1,
              ),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 34,
              color: focused ? const Color(0xFF161005) : colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }
}

class _RelatedSeriesSection extends StatelessWidget {
  const _RelatedSeriesSection({
    required this.currentSeriesId,
    required this.relatedSeries,
    required this.layout,
    required this.title,
  });

  final String currentSeriesId;
  final AsyncValue<List<SeriesItem>> relatedSeries;
  final DeviceLayout layout;
  final String title;

  @override
  Widget build(BuildContext context) {
    return relatedSeries.when(
      data: (items) {
        final related = items
            .where((entry) => entry.id != currentSeriesId)
            .take(layout.isTv ? 16 : 10)
            .toList();
        final relatedKinds = related
            .map((entry) => OnDemandLibraryKind.tryParse(entry.libraryKind))
            .whereType<OnDemandLibraryKind>()
            .toSet();
        final showKindBadge = relatedKinds.length > 1;

        if (related.isEmpty) {
          return const SizedBox.shrink();
        }

        return OnDemandDetailSection(
          layout: layout,
          title: title,
          subtitle: 'Prateleira enxuta com foco em poster e nome.',
          child: SizedBox(
            height: layout.isTv ? 354 : 286,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: related.length,
              separatorBuilder: (context, index) =>
                  SizedBox(width: layout.cardSpacing),
              itemBuilder: (context, index) {
                final series = related[index];
                return SizedBox(
                  width: layout.isTv ? 200 : 150,
                  child: _RelatedSeriesCard(
                    item: series,
                    layout: layout,
                    showKindBadge: showKindBadge,
                  ),
                );
              },
            ),
          ),
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
    required this.showKindBadge,
  });

  final SeriesItem item;
  final DeviceLayout layout;
  final bool showKindBadge;

  @override
  Widget build(BuildContext context) {
    final libraryKind = OnDemandLibraryKind.tryParse(item.libraryKind);
    final badge = showKindBadge
        ? switch (libraryKind) {
            OnDemandLibraryKind.anime => 'ANIME',
            OnDemandLibraryKind.kids => 'KIDS',
            OnDemandLibraryKind.movies => 'FILME',
            _ => null,
          }
        : null;

    return OnDemandRelatedPosterCard(
      layout: layout,
      title: item.name,
      imageUrl: item.coverUrl,
      icon: Icons.tv_outlined,
      placeholderLabel: 'Capa indisponível',
      badge: badge,
      onPressed: () => context.push(SeriesDetailsScreen.buildLocation(item.id)),
    );
  }
}

List<MapEntry<int, List<SeriesEpisode>>> _groupEpisodesBySeason(
  List<SeriesEpisode> episodes,
) {
  final grouped = <int, List<SeriesEpisode>>{};
  for (final episode in episodes) {
    grouped.putIfAbsent(episode.seasonNumber, () => []);
    grouped[episode.seasonNumber]!.add(episode);
  }
  for (final seasonEpisodes in grouped.values) {
    seasonEpisodes.sort((a, b) {
      final episodeCompare = (a.episodeNumber ?? 0).compareTo(
        b.episodeNumber ?? 0,
      );
      if (episodeCompare != 0) {
        return episodeCompare;
      }
      return a.title.compareTo(b.title);
    });
  }
  final ordered = grouped.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return ordered;
}

SeriesEpisode? _resolveSeasonFeaturedEpisode(
  MapEntry<int, List<SeriesEpisode>>? seasonEntry,
  SeriesEpisode? primaryEpisode,
) {
  if (seasonEntry == null || seasonEntry.value.isEmpty) {
    return null;
  }

  final selectedEpisodes = seasonEntry.value;
  if (primaryEpisode != null &&
      primaryEpisode.seasonNumber == seasonEntry.key) {
    for (final episode in selectedEpisodes) {
      if (episode.id == primaryEpisode.id) {
        return episode;
      }
    }
  }

  return selectedEpisodes.first;
}

String _episodeBadge(SeriesEpisode episode) {
  final episodeNumber = episode.episodeNumber;
  if (episodeNumber == null || episodeNumber <= 0) {
    return 'SP';
  }
  return episodeNumber.toString().padLeft(2, '0');
}

String _episodeLabel(SeriesEpisode episode) {
  final episodeNumber = episode.episodeNumber;
  if (episodeNumber == null || episodeNumber <= 0) {
    return 'Especial';
  }
  return 'Episódio $episodeNumber';
}

String? _episodePlot(SeriesEpisode episode) {
  final plot = episode.plot?.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (plot == null || plot.isEmpty) {
    return null;
  }
  return plot;
}

List<({String label, IconData icon})> _buildSeriesHeroTags(SeriesInfo item) {
  return [
    (label: '${item.seasonCount} temporadas', icon: Icons.layers_rounded),
    (label: '${item.episodeCount} episódios', icon: Icons.movie_filter_rounded),
    if (item.genre?.trim().isNotEmpty == true)
      (label: item.genre!.trim(), icon: Icons.local_movies_rounded),
  ];
}

String _seriesSynopsis(SeriesInfo item) {
  return item.plot?.trim().isNotEmpty == true
      ? item.plot!.trim()
      : 'Esta coleção ainda não possui uma sinopse detalhada no servidor XTream.';
}
