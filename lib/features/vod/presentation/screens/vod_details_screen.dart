import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/display_formatters.dart';
import '../../../../features/favorites/domain/entities/favorite_item.dart';
import '../../../../features/favorites/presentation/controllers/favorites_controller.dart';
import '../../../../features/player/domain/entities/playback_context.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/testing/app_test_keys.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/branded_artwork.dart';
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

    return AppScaffold(
      title: 'Filmes',
      subtitle: 'Detalhes do título',
      showBack: true,
      child: AsyncStateBuilder(
        value: info,
        dataBuilder: (item) {
          final isFavorite = favorites.any(
            (entry) => entry.contentType == 'vod' && entry.contentId == item.id,
          );
          final releaseDate = DisplayFormatters.humanizeDate(item.releaseDate);

          return LayoutBuilder(
            builder: (context, outerConstraints) {
              final layout = DeviceLayout.of(
                context,
                constraints: outerConstraints,
              );

              final metadata = <Widget>[
                if (item.genre?.trim().isNotEmpty == true)
                  _DetailInfoPill(
                    icon: Icons.local_movies_outlined,
                    label: item.genre!,
                    layout: layout,
                  ),
                if (item.duration?.trim().isNotEmpty == true)
                  _DetailInfoPill(
                    icon: Icons.schedule_rounded,
                    label: item.duration!,
                    layout: layout,
                  ),
                if (item.rating?.trim().isNotEmpty == true)
                  _DetailInfoPill(
                    icon: Icons.star_rounded,
                    label: 'Nota ${item.rating}',
                    layout: layout,
                  ),
                if (releaseDate != null)
                  _DetailInfoPill(
                    icon: Icons.event_available_rounded,
                    label: releaseDate,
                    layout: layout,
                  ),
              ];

              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
                child: Card(
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
                            placeholderLabel: 'Poster indisponível',
                            icon: Icons.movie_creation_outlined,
                          ),
                        );

                        final details = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontSize: layout.isTv ? 40 : 32),
                            ),
                            if (metadata.isNotEmpty) ...[
                              SizedBox(height: layout.sectionSpacing + 2),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: metadata,
                              ),
                            ],
                            SizedBox(height: layout.sectionSpacing + 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: layout.isMobilePortrait
                                      ? double.infinity
                                      : null,
                                  child: FilledButton.tonalIcon(
                                    key: AppTestKeys.vodPlayButton,
                                    autofocus: true,
                                    onPressed: () => context.push(
                                      PlayerScreen.routePath,
                                      extra: PlaybackContext(
                                        contentType: PlaybackContentType.vod,
                                        itemId: item.id,
                                        title: item.name,
                                        containerExtension:
                                            item.containerExtension,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.play_circle_outline_rounded,
                                    ),
                                    label: const Text('Reproduzir'),
                                  ),
                                ),
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
                                            contentType: 'vod',
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
                              ],
                            ),
                            if (item.plot != null &&
                                item.plot!.trim().isNotEmpty) ...[
                              SizedBox(height: layout.sectionSpacing + 10),
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
                              SizedBox(height: layout.sectionSpacing + 4),
                              Text(
                                'Elenco',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(item.cast!),
                            ],
                            if (item.director != null &&
                                item.director!.trim().isNotEmpty) ...[
                              SizedBox(height: layout.sectionSpacing + 2),
                              Text(
                                'Direção',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(item.director!),
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
              );
            },
          );
        },
      ),
    );
  }
}

class _DetailInfoPill extends StatelessWidget {
  const _DetailInfoPill({
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
