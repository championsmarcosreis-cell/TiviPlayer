import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/display_formatters.dart';
import '../../../../features/favorites/domain/entities/favorite_item.dart';
import '../../../../features/favorites/presentation/controllers/favorites_controller.dart';
import '../../../../features/player/domain/entities/playback_context.dart';
import '../../../../features/player/presentation/controllers/playback_history_controller.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../domain/entities/vod_info.dart';
import '../../domain/entities/vod_stream.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/presentation/support/on_demand_library.dart';
import '../../../../shared/testing/app_test_keys.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/branded_artwork.dart';
import '../../../../shared/widgets/mobile_primary_dock.dart';
import '../../../../shared/widgets/on_demand_related_poster_card.dart';
import '../providers/vod_providers.dart';

class VodDetailsScreen extends ConsumerWidget {
  const VodDetailsScreen({super.key, required this.vodId});

  static const routePath = '/vod/details/:vodId';

  static String buildLocation(String vodId) => '/vod/details/$vodId';

  final String vodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(vodInfoProvider(vodId));
    final favorites = ref.watch(favoritesControllerProvider);
    final relatedStreams = ref.watch(vodStreamsProvider(null));
    final playbackHistoryController = ref.read(
      playbackHistoryControllerProvider.notifier,
    );

    return AppScaffold(
      title: 'Filmes',
      subtitle: 'Detalhe do titulo',
      showBack: true,
      showBrand: false,
      mobileBottomBar: const MobilePrimaryDock(),
      child: AsyncStateBuilder(
        value: info,
        dataBuilder: (item) {
          final isFavorite = favorites.any(
            (entry) => entry.contentType == 'vod' && entry.contentId == item.id,
          );
          final releaseDate = DisplayFormatters.humanizeDate(item.releaseDate);
          final metadata = [
            if (releaseDate != null && releaseDate.isNotEmpty) releaseDate,
            if (item.genre?.trim().isNotEmpty == true) item.genre!.trim(),
            if (item.duration?.trim().isNotEmpty == true) item.duration!.trim(),
            if (item.rating?.trim().isNotEmpty == true) 'Nota ${item.rating}',
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
                    _VodCinematicHero(
                      item: item,
                      metadata: metadata,
                      isFavorite: isFavorite,
                      layout: layout,
                      onPlay: () => context.push(
                        PlayerScreen.routePath,
                        extra: PlaybackContext(
                          contentType: PlaybackContentType.vod,
                          itemId: item.id,
                          title: item.name,
                          containerExtension: item.containerExtension,
                          artworkUrl: item.coverUrl,
                          backdropUrl: item.backdropUrl,
                          resumePosition: playbackHistoryController
                              .resolveResumePosition(
                                PlaybackContentType.vod,
                                item.id,
                              ),
                          capabilities:
                              const PlaybackSessionCapabilities.onDemand(),
                        ),
                      ),
                      onToggleFavorite: () => ref
                          .read(favoritesControllerProvider.notifier)
                          .toggle(
                            FavoriteItem(
                              contentType: 'vod',
                              contentId: item.id,
                              title: item.name,
                            ),
                          ),
                    ),
                    SizedBox(height: layout.sectionSpacing + 10),
                    _InfoSections(item: item, layout: layout),
                    SizedBox(height: layout.sectionSpacing + 6),
                    _RelatedVodSection(
                      currentVodId: item.id,
                      relatedStreams: relatedStreams,
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

class _VodCinematicHero extends StatelessWidget {
  const _VodCinematicHero({
    required this.item,
    required this.metadata,
    required this.isFavorite,
    required this.layout,
    required this.onPlay,
    required this.onToggleFavorite,
  });

  final VodInfo item;
  final List<String> metadata;
  final bool isFavorite;
  final DeviceLayout layout;
  final VoidCallback onPlay;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backdrop = BrandedArtwork.normalizeArtworkUrl(item.backdropUrl) ??
        BrandedArtwork.normalizeArtworkUrl(item.coverUrl);

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
          Positioned(
            left: -120,
            top: -40,
            child: Container(
              width: layout.isTv ? 520 : 300,
              height: layout.isTv ? 380 : 220,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
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
                    placeholderLabel: 'Poster indisponivel',
                    icon: Icons.movie_creation_outlined,
                    borderRadius: layout.isTv ? 22 : 18,
                  ),
                );

                final content = _HeroTextContent(
                  item: item,
                  metadata: metadata,
                  isFavorite: isFavorite,
                  layout: layout,
                  onPlay: onPlay,
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

class _HeroTextContent extends StatelessWidget {
  const _HeroTextContent({
    required this.item,
    required this.metadata,
    required this.isFavorite,
    required this.layout,
    required this.onPlay,
    required this.onToggleFavorite,
  });

  final VodInfo item;
  final List<String> metadata;
  final bool isFavorite;
  final DeviceLayout layout;
  final VoidCallback onPlay;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tvPlayStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, layout.isTv ? 66 : 54)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
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
          return BorderSide(color: colorScheme.secondary, width: 3);
        }
        return BorderSide(color: colorScheme.primary.withValues(alpha: 0.92));
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.focused) ? 12 : 2;
      }),
      shadowColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.focused)
            ? colorScheme.secondary.withValues(alpha: 0.42)
            : Colors.black.withValues(alpha: 0.35);
      }),
    );
    final tvSecondaryStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, layout.isTv ? 62 : 50)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (!layout.isTv) {
          return null;
        }
        if (states.contains(WidgetState.focused)) {
          return Colors.white.withValues(alpha: 0.16);
        }
        return Colors.black.withValues(alpha: 0.16);
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return BorderSide(color: colorScheme.secondary, width: 2.2);
        }
        return BorderSide(color: Colors.white.withValues(alpha: 0.35));
      }),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'FILME',
          style: textTheme.labelLarge?.copyWith(
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
          style: textTheme.headlineLarge?.copyWith(
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
        if (item.plot?.trim().isNotEmpty == true)
          Text(
            item.plot!,
            maxLines: layout.isTv ? 3 : 5,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge?.copyWith(
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
              key: AppTestKeys.vodPlayButton,
              autofocus: true,
              onPressed: onPlay,
              style: layout.isTv
                  ? tvPlayStyle
                  : FilledButton.styleFrom(
                      minimumSize: Size(0, layout.isTv ? 66 : 54),
                    ),
              icon: Icon(Icons.play_arrow_rounded, size: layout.isTv ? 34 : 24),
              label: Text(
                'Assistir',
                style: textTheme.titleMedium?.copyWith(
                  fontSize: layout.isTv ? 24 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onToggleFavorite,
              style: layout.isTv
                  ? tvSecondaryStyle
                  : OutlinedButton.styleFrom(
                      minimumSize: Size(0, layout.isTv ? 62 : 50),
                    ),
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

class _InfoSections extends StatelessWidget {
  const _InfoSections({required this.item, required this.layout});

  final VodInfo item;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final sections = <({String title, String value})>[
      if (item.plot?.trim().isNotEmpty == true)
        (title: 'Sinopse completa', value: item.plot!.trim()),
      if (item.cast?.trim().isNotEmpty == true)
        (title: 'Elenco', value: item.cast!.trim()),
      if (item.director?.trim().isNotEmpty == true)
        (title: 'Direção', value: item.director!.trim()),
    ];

    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          _InfoSectionCard(
            title: section.title,
            content: section.value,
            layout: layout,
          ),
          SizedBox(height: layout.cardSpacing),
        ],
      ],
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  const _InfoSectionCard({
    required this.title,
    required this.content,
    required this.layout,
  });

  final String title;
  final String content;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.isTv ? 20 : 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 22 : 17),
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            colorScheme.surface.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: layout.isTv ? 24 : 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: layout.isTv ? 10 : 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: layout.isTv ? 17 : 14.5,
              height: 1.45,
              color: colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedVodSection extends StatelessWidget {
  const _RelatedVodSection({
    required this.currentVodId,
    required this.relatedStreams,
    required this.layout,
  });

  final String currentVodId;
  final AsyncValue<List<VodStream>> relatedStreams;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    return relatedStreams.when(
      data: (items) {
        final related = items
            .where((entry) => entry.id != currentVodId)
            .take(layout.isTv ? 18 : 12)
            .toList();

        if (related.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filmes relacionados',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: layout.isTv ? 30 : 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: layout.isTv ? 4 : 2),
            Text(
              'Continue descobrindo no mesmo catalogo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            SizedBox(height: layout.cardSpacing),
            SizedBox(
              height: layout.isTv ? 344 : 276,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (context, index) =>
                    SizedBox(width: layout.cardSpacing),
                itemBuilder: (context, index) {
                  final movie = related[index];
                  return SizedBox(
                    width: layout.isTv ? 206 : 156,
                    child: _RelatedVodCard(
                      item: movie,
                      layout: layout,
                      autofocus: !layout.isTv && index == 0,
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

class _RelatedVodCard extends StatelessWidget {
  const _RelatedVodCard({
    required this.item,
    required this.layout,
    this.autofocus = false,
  });

  final VodStream item;
  final DeviceLayout layout;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final rating = item.rating?.trim();
    final primaryGenre = splitLibraryGenres(item.genre).firstOrNull;
    final libraryKind = OnDemandLibraryKind.tryParse(item.libraryKind);
    final badge = rating?.isNotEmpty == true
        ? '★ $rating'
        : switch (libraryKind) {
            OnDemandLibraryKind.kids => 'KIDS',
            _ => 'FILME',
          };
    final subtitle =
        primaryGenre ??
        (rating?.isNotEmpty == true
            ? 'Nota $rating'
            : libraryKind == OnDemandLibraryKind.kids
            ? 'Seleção kids'
            : 'Filme em catálogo');

    return OnDemandRelatedPosterCard(
      layout: layout,
      autofocus: autofocus,
      title: item.name,
      imageUrl: item.coverUrl,
      icon: Icons.movie_creation_outlined,
      placeholderLabel: 'Poster indisponível',
      badge: badge,
      subtitle: subtitle,
      onPressed: () => context.push(VodDetailsScreen.buildLocation(item.id)),
    );
  }
}
