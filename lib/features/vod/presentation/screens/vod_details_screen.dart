import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/player/domain/entities/playback_context.dart';
import '../../../../features/player/presentation/screens/player_placeholder_screen.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../providers/vod_providers.dart';

class VodDetailsScreen extends ConsumerWidget {
  const VodDetailsScreen({super.key, required this.vodId});

  static const routePath = '/vod/details/:vodId';

  static String buildLocation(String vodId) => '/vod/details/$vodId';

  final String vodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(vodInfoProvider(vodId));

    return AppScaffold(
      title: 'Detalhes do Filme',
      subtitle: 'Resposta de get_vod_info',
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
                        if (item.genre != null) Chip(label: Text(item.genre!)),
                        if (item.duration != null)
                          Chip(label: Text(item.duration!)),
                        if (item.rating != null)
                          Chip(label: Text('Nota ${item.rating}')),
                        if (item.releaseDate != null)
                          Chip(label: Text(item.releaseDate!)),
                      ],
                    ),
                    if (item.plot != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        item.plot!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (item.cast != null) Text('Elenco: ${item.cast}'),
                    if (item.director != null) ...[
                      const SizedBox(height: 8),
                      Text('Direção: ${item.director}'),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(
                        PlayerPlaceholderScreen.routePath,
                        extra: PlaybackContext(
                          contentType: 'vod',
                          itemId: item.id,
                          title: item.name,
                          notes:
                              'A resolução do arquivo VOD e controles completos entram no PR2.',
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
