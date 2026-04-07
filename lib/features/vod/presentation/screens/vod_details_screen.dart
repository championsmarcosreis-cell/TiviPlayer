import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/display_formatters.dart';
import '../../../../core/tv/tv_focusable.dart';
import '../../../../features/favorites/domain/entities/favorite_item.dart';
import '../../../../features/favorites/presentation/controllers/favorites_controller.dart';
import '../../../../features/player/domain/entities/playback_context.dart';
import '../../../../features/player/presentation/controllers/playback_history_controller.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/presentation/support/on_demand_library.dart';
import '../../../../shared/testing/app_test_keys.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/branded_artwork.dart';
import '../../../../shared/widgets/mobile_primary_dock.dart';
import '../../../../shared/widgets/on_demand_detail_panels.dart';
import '../../../../shared/widgets/on_demand_related_poster_card.dart';
import '../../domain/entities/vod_info.dart';
import '../../domain/entities/vod_stream.dart';
import '../providers/vod_providers.dart';

class VodDetailsScreen extends ConsumerStatefulWidget {
  const VodDetailsScreen({super.key, required this.vodId});

  static const routePath = '/vod/details/:vodId';

  static String buildLocation(String vodId) => '/vod/details/$vodId';

  final String vodId;

  @override
  ConsumerState<VodDetailsScreen> createState() => _VodDetailsScreenState();
}

class _VodDetailsScreenState extends ConsumerState<VodDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final info = ref.watch(vodInfoProvider(widget.vodId));
    final favorites = ref.watch(favoritesControllerProvider);
    final relatedStreams = ref.watch(vodStreamsProvider(null));
    final playbackHistoryController = ref.read(
      playbackHistoryControllerProvider.notifier,
    );

    return AppScaffold(
      title: 'Filmes',
      subtitle: 'Detalhe do título',
      showBack: false,
      showBrand: false,
      showHeader: false,
      showTvSidebar: false,
      mobileBottomBar: const MobilePrimaryDock(),
      child: AsyncStateBuilder(
        value: info,
        dataBuilder: (item) {
          final isFavorite = favorites.any(
            (entry) => entry.contentType == 'vod' && entry.contentId == item.id,
          );

          return LayoutBuilder(
            builder: (context, outerConstraints) {
              final layout = DeviceLayout.of(
                context,
                constraints: outerConstraints,
              );
              final heroTags = _buildVodHeroTags(item);
              final facts = _buildVodFacts(item);
              final credits = _buildVodCredits(item);

              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!layout.isTv) ...[
                      _VodInlineHeader(
                        onBack: () {
                          if (context.canPop()) {
                            context.pop();
                          }
                        },
                      ),
                      SizedBox(height: layout.sectionSpacing + 6),
                    ],
                    _VodEditorialHero(
                      item: item,
                      layout: layout,
                      isFavorite: isFavorite,
                      heroTags: heroTags,
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
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
                    SizedBox(height: layout.isTv ? 26 : 22),
                    if (layout.isTv)
                      _VodTvBody(
                        item: item,
                        layout: layout,
                        facts: facts,
                        credits: credits,
                        relatedStreams: relatedStreams,
                      )
                    else
                      _VodMobileBody(
                        item: item,
                        layout: layout,
                        facts: facts,
                        credits: credits,
                        relatedStreams: relatedStreams,
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

class _VodEditorialHero extends StatelessWidget {
  const _VodEditorialHero({
    required this.item,
    required this.layout,
    required this.isFavorite,
    required this.heroTags,
    required this.onBack,
    required this.onPlay,
    required this.onToggleFavorite,
  });

  final VodInfo item;
  final DeviceLayout layout;
  final bool isFavorite;
  final List<({String label, IconData icon})> heroTags;
  final VoidCallback onBack;
  final VoidCallback onPlay;
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
          colors: [Color(0x221A2432), Color(0x100D141D), Colors.transparent],
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
              ).colorScheme.primary.withValues(alpha: 0.12),
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
                      placeholderLabel: 'Poster indisponível',
                      icon: Icons.movie_creation_outlined,
                      chrome: BrandedArtworkChrome.subtle,
                    ),
                  ),
                );

                final content = _VodHeroContent(
                  item: item,
                  layout: layout,
                  isFavorite: isFavorite,
                  heroTags: heroTags,
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
              child: _VodHeroBackButton(onPressed: onBack),
            ),
        ],
      ),
    );
  }
}

class _VodHeroContent extends StatelessWidget {
  const _VodHeroContent({
    required this.item,
    required this.layout,
    required this.isFavorite,
    required this.heroTags,
    required this.onPlay,
    required this.onToggleFavorite,
  });

  final VodInfo item;
  final DeviceLayout layout;
  final bool isFavorite;
  final List<({String label, IconData icon})> heroTags;
  final VoidCallback onPlay;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final synopsis = _vodSynopsis(item);
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
          'FILME',
          style: textTheme.labelLarge?.copyWith(
            letterSpacing: 1.32,
            color: colorScheme.secondary.withValues(alpha: 0.96),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: layout.isTv ? 8 : 6),
        Text(
          item.name,
          maxLines: layout.isTv ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: textTheme.headlineLarge?.copyWith(
            fontSize: layout.isTv ? 46 : 31,
            fontWeight: FontWeight.w800,
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
            fontSize: layout.isTv ? 17 : 14.8,
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
              key: AppTestKeys.vodPlayButton,
              autofocus: layout.isTv,
              onPressed: onPlay,
              style: primaryStyle,
              icon: Icon(Icons.play_arrow_rounded, size: layout.isTv ? 32 : 22),
              label: Text(
                'Assistir',
                style: textTheme.titleMedium?.copyWith(
                  fontSize: layout.isTv ? 22 : 17,
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

class _VodTvBody extends StatelessWidget {
  const _VodTvBody({
    required this.item,
    required this.layout,
    required this.facts,
    required this.credits,
    required this.relatedStreams,
  });

  final VodInfo item;
  final DeviceLayout layout;
  final List<OnDemandDetailFactData> facts;
  final List<({String title, String text})> credits;
  final AsyncValue<List<VodStream>> relatedStreams;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final splitColumns =
                credits.isNotEmpty && constraints.maxWidth >= 980;

            if (!splitColumns) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VodFactsSection(layout: layout, facts: facts),
                  if (credits.isNotEmpty) ...[
                    SizedBox(height: layout.sectionSpacing + 6),
                    _VodCreditsSection(layout: layout, credits: credits),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 11,
                  child: _VodFactsSection(layout: layout, facts: facts),
                ),
                SizedBox(width: layout.cardSpacing + 8),
                Expanded(
                  flex: 10,
                  child: _VodCreditsSection(layout: layout, credits: credits),
                ),
              ],
            );
          },
        ),
        SizedBox(height: layout.sectionSpacing + 8),
        _RelatedVodSection(
          currentVodId: item.id,
          relatedStreams: relatedStreams,
          layout: layout,
          title: 'Relacionados',
        ),
      ],
    );
  }
}

class _VodMobileBody extends StatelessWidget {
  const _VodMobileBody({
    required this.item,
    required this.layout,
    required this.facts,
    required this.credits,
    required this.relatedStreams,
  });

  final VodInfo item;
  final DeviceLayout layout;
  final List<OnDemandDetailFactData> facts;
  final List<({String title, String text})> credits;
  final AsyncValue<List<VodStream>> relatedStreams;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VodFactsSection(layout: layout, facts: facts),
        if (credits.isNotEmpty) ...[
          SizedBox(height: layout.sectionSpacing + 4),
          _VodCreditsSection(layout: layout, credits: credits),
        ],
        SizedBox(height: layout.sectionSpacing + 8),
        _RelatedVodSection(
          currentVodId: item.id,
          relatedStreams: relatedStreams,
          layout: layout,
          title: 'Relacionados',
        ),
      ],
    );
  }
}

class _VodFactsSection extends StatelessWidget {
  const _VodFactsSection({required this.layout, required this.facts});

  final DeviceLayout layout;
  final List<OnDemandDetailFactData> facts;

  @override
  Widget build(BuildContext context) {
    return OnDemandDetailSection(
      layout: layout,
      eyebrow: 'FICHA',
      title: 'Detalhes do título',
      subtitle: 'Metadados integrados à página, sem cartões extras.',
      child: facts.isEmpty
          ? Text(
              'O servidor não enviou informações técnicas adicionais para este filme.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.72),
                height: 1.5,
              ),
            )
          : OnDemandDetailFactsList(layout: layout, facts: facts),
    );
  }
}

class _VodCreditsSection extends StatelessWidget {
  const _VodCreditsSection({required this.layout, required this.credits});

  final DeviceLayout layout;
  final List<({String title, String text})> credits;

  @override
  Widget build(BuildContext context) {
    return OnDemandDetailSection(
      layout: layout,
      eyebrow: 'CRÉDITOS',
      title: 'Equipe e elenco',
      subtitle: 'Dados textuais recebidos do catálogo atual.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < credits.length; index++) ...[
            _OpenTextBlock(
              layout: layout,
              title: credits[index].title,
              text: credits[index].text,
            ),
            if (index != credits.length - 1)
              SizedBox(height: layout.sectionSpacing),
          ],
        ],
      ),
    );
  }
}

class _OpenTextBlock extends StatelessWidget {
  const _OpenTextBlock({
    required this.layout,
    required this.title,
    required this.text,
  });

  final DeviceLayout layout;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(bottom: layout.isTv ? 16 : 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.16),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 1.04,
              color: colorScheme.secondary.withValues(alpha: 0.94),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: layout.isTv ? 8 : 7),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: layout.isTv ? 16.5 : 14.5,
              height: 1.55,
              color: colorScheme.onSurface.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
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

class _VodInlineHeader extends StatelessWidget {
  const _VodInlineHeader({required this.onBack});

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

class _VodHeroBackButton extends StatelessWidget {
  const _VodHeroBackButton({required this.onPressed});

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

class _RelatedVodSection extends StatelessWidget {
  const _RelatedVodSection({
    required this.currentVodId,
    required this.relatedStreams,
    required this.layout,
    required this.title,
  });

  final String currentVodId;
  final AsyncValue<List<VodStream>> relatedStreams;
  final DeviceLayout layout;
  final String title;

  @override
  Widget build(BuildContext context) {
    return relatedStreams.when(
      data: (items) {
        final related = items
            .where((entry) => entry.id != currentVodId)
            .take(layout.isTv ? 18 : 12)
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
                final movie = related[index];
                return SizedBox(
                  width: layout.isTv ? 200 : 150,
                  child: _RelatedVodCard(
                    item: movie,
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

class _RelatedVodCard extends StatelessWidget {
  const _RelatedVodCard({
    required this.item,
    required this.layout,
    required this.showKindBadge,
  });

  final VodStream item;
  final DeviceLayout layout;
  final bool showKindBadge;

  @override
  Widget build(BuildContext context) {
    final libraryKind = OnDemandLibraryKind.tryParse(item.libraryKind);
    final badge = showKindBadge
        ? switch (libraryKind) {
            OnDemandLibraryKind.kids => 'KIDS',
            OnDemandLibraryKind.anime => 'ANIME',
            OnDemandLibraryKind.series => 'SÉRIE',
            _ => null,
          }
        : null;

    return OnDemandRelatedPosterCard(
      layout: layout,
      title: item.name,
      imageUrl: item.coverUrl,
      icon: Icons.movie_creation_outlined,
      placeholderLabel: 'Poster indisponível',
      badge: badge,
      onPressed: () => context.push(VodDetailsScreen.buildLocation(item.id)),
    );
  }
}

List<OnDemandDetailFactData> _buildVodFacts(VodInfo item) {
  return [
    if (item.releaseDate?.trim().isNotEmpty == true)
      OnDemandDetailFactData(
        label: 'Lançamento',
        value:
            DisplayFormatters.humanizeDate(item.releaseDate) ??
            item.releaseDate!.trim(),
        icon: Icons.event_available_rounded,
      ),
    if (item.duration?.trim().isNotEmpty == true)
      OnDemandDetailFactData(
        label: 'Duração',
        value: item.duration!.trim(),
        icon: Icons.schedule_rounded,
      ),
    if (item.rating?.trim().isNotEmpty == true)
      OnDemandDetailFactData(
        label: 'Nota',
        value: item.rating!.trim(),
        icon: Icons.stars_rounded,
      ),
    if (item.genre?.trim().isNotEmpty == true)
      OnDemandDetailFactData(
        label: 'Gênero',
        value: item.genre!.trim(),
        icon: Icons.theaters_rounded,
      ),
  ];
}

List<({String title, String text})> _buildVodCredits(VodInfo item) {
  return [
    if (item.director?.trim().isNotEmpty == true)
      (title: 'Direção', text: item.director!.trim()),
    if (item.cast?.trim().isNotEmpty == true)
      (title: 'Elenco', text: item.cast!.trim()),
  ];
}

List<({String label, IconData icon})> _buildVodHeroTags(VodInfo item) {
  return [
    if (item.releaseDate?.trim().isNotEmpty == true)
      (
        label:
            DisplayFormatters.humanizeDate(item.releaseDate) ??
            item.releaseDate!.trim(),
        icon: Icons.calendar_today_rounded,
      ),
    if (item.duration?.trim().isNotEmpty == true)
      (label: item.duration!.trim(), icon: Icons.schedule_rounded),
    if (item.rating?.trim().isNotEmpty == true)
      (label: 'Nota ${item.rating!.trim()}', icon: Icons.stars_rounded),
    if (item.genre?.trim().isNotEmpty == true)
      (label: item.genre!.trim(), icon: Icons.local_movies_rounded),
  ];
}

String _vodSynopsis(VodInfo item) {
  return item.plot?.trim().isNotEmpty == true
      ? item.plot!.trim()
      : 'Este título ainda não recebeu uma sinopse detalhada do servidor XTream.';
}
