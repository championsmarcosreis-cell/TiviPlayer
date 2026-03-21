import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/display_formatters.dart';
import '../../../../features/favorites/domain/entities/favorite_item.dart';
import '../../../../features/favorites/presentation/controllers/favorites_controller.dart';
import '../../../../features/player/domain/entities/playback_context.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
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

          return SingleChildScrollView(
            child: Card(
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
                        placeholderLabel: 'Poster indisponível',
                        icon: Icons.movie_creation_outlined,
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
                            if (item.genre != null)
                              Chip(label: Text(item.genre!)),
                            if (item.duration != null)
                              Chip(label: Text(item.duration!)),
                            if (item.rating != null)
                              Chip(label: Text('Nota ${item.rating}')),
                            if (releaseDate != null)
                              Chip(label: Text(releaseDate)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.tonalIcon(
                              key: AppTestKeys.vodPlayButton,
                              autofocus: true,
                              onPressed: () => context.push(
                                PlayerScreen.routePath,
                                extra: PlaybackContext(
                                  contentType: PlaybackContentType.vod,
                                  itemId: item.id,
                                  title: item.name,
                                  containerExtension: item.containerExtension,
                                ),
                              ),
                              icon: const Icon(
                                Icons.play_circle_outline_rounded,
                              ),
                              label: const Text('Reproduzir'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => ref
                                  .read(favoritesControllerProvider.notifier)
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
                          ],
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
                        if (item.director != null &&
                            item.director!.trim().isNotEmpty) ...[
                          const SizedBox(height: 18),
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
          );
        },
      ),
    );
  }
}
