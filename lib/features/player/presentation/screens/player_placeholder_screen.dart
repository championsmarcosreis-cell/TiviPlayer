import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../domain/entities/playback_context.dart';

class PlayerPlaceholderScreen extends StatelessWidget {
  const PlayerPlaceholderScreen({super.key, required this.playbackContext});

  static const routePath = '/player';

  final PlaybackContext? playbackContext;

  @override
  Widget build(BuildContext context) {
    final item = playbackContext;

    return AppScaffold(
      title: item?.title ?? 'Player',
      subtitle: 'Base preparada para PR2',
      showBack: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Player ainda não foi concluído',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Esta PR deixa a navegação, o contrato de playback e o '
                    'ponto de entrada preparados. A resolução de URL de mídia, '
                    'controles de reprodução e tuning do `video_player` entram no PR2.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (item != null) ...[
                    const SizedBox(height: 24),
                    Text('Tipo: ${item.contentType}'),
                    const SizedBox(height: 8),
                    Text('ID: ${item.itemId}'),
                    if (item.notes != null) ...[
                      const SizedBox(height: 8),
                      Text(item.notes!),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
