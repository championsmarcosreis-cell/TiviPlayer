import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/player/domain/entities/playback_context.dart';
import '../../../../features/player/presentation/screens/player_placeholder_screen.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../providers/series_providers.dart';

class SeriesDetailsScreen extends ConsumerWidget {
  const SeriesDetailsScreen({super.key, required this.seriesId});

  static const routePath = '/series/details/:seriesId';

  static String buildLocation(String seriesId) => '/series/details/$seriesId';

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(seriesInfoProvider(seriesId));

    return AppScaffold(
      title: 'Detalhes da Série',
      subtitle: 'Resposta de get_series_info',
      showBack: true,
      child: AsyncStateBuilder(
        value: info,
        dataBuilder: (item) {
          return SingleChildScrollView(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
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
                        Chip(label: Text('${item.seasonCount} temporadas')),
                        Chip(label: Text('${item.episodeCount} episódios')),
                        if (item.genre != null) Chip(label: Text(item.genre!)),
                      ],
                    ),
                    if (item.plot != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        item.plot!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    if (item.cast != null) ...[
                      const SizedBox(height: 20),
                      Text('Elenco: ${item.cast}'),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(
                        PlayerPlaceholderScreen.routePath,
                        extra: PlaybackContext(
                          contentType: 'series',
                          itemId: item.id,
                          title: item.name,
                          notes:
                              'A montagem de temporadas/episódios reproduzíveis entra no PR2.',
                        ),
                      ),
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: const Text('Abrir base do player'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
