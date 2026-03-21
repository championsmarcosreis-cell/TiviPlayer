import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/player/domain/entities/playback_context.dart';
import '../../../../features/player/presentation/screens/player_placeholder_screen.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/content_list_tile.dart';
import '../providers/live_providers.dart';

class LiveStreamsScreen extends ConsumerWidget {
  const LiveStreamsScreen({super.key, required this.categoryId});

  static const routePath = '/live/category/:categoryId';

  static String buildLocation(String categoryId) =>
      '/live/category/$categoryId';

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveCategoryId = categoryId == 'all' ? null : categoryId;
    final streams = ref.watch(liveStreamsProvider(effectiveCategoryId));

    return AppScaffold(
      title: 'Canais Live',
      subtitle: effectiveCategoryId == null
          ? 'Lista completa'
          : 'Categoria $effectiveCategoryId',
      showBack: true,
      child: AsyncStateBuilder(
        value: streams,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem canais',
        emptyMessage: 'A API não retornou canais para esse filtro.',
        dataBuilder: (items) {
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final subtitleParts = [
                if (item.categoryId != null) 'Cat. ${item.categoryId}',
                if (item.epgChannelId != null) 'EPG ${item.epgChannelId}',
                if (item.hasArchive) 'Replay',
              ];

              return ContentListTile(
                autofocus: index == 0,
                title: item.name,
                subtitle: subtitleParts.isEmpty
                    ? 'Canal Live'
                    : subtitleParts.join(' • '),
                icon: Icons.live_tv_rounded,
                onPressed: () => context.push(
                  PlayerPlaceholderScreen.routePath,
                  extra: PlaybackContext(
                    contentType: 'live',
                    itemId: item.id,
                    title: item.name,
                    notes: 'A URL final do stream e o playback entram no PR2.',
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
