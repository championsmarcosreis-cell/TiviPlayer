import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/player/domain/entities/playback_context.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
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
      title: 'Ao vivo',
      subtitle: effectiveCategoryId == null
          ? 'Todos os canais'
          : 'Grade selecionada',
      showBack: true,
      child: AsyncStateBuilder(
        value: streams,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem canais disponíveis',
        emptyMessage: 'Nenhum canal foi encontrado para o filtro selecionado.',
        dataBuilder: (items) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final layout = DeviceLayout.of(context, constraints: constraints);

              return ListView.separated(
                padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: layout.cardSpacing),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final subtitle = item.hasArchive
                      ? 'Canal com replay disponível'
                      : 'Canal disponível para assistir';

                  return ContentListTile(
                    autofocus: index == 0,
                    title: item.name,
                    subtitle: subtitle,
                    icon: Icons.live_tv_rounded,
                    imageUrl: item.iconUrl,
                    thumbnailAspectRatio: 1,
                    thumbnailWidth: 64,
                    thumbnailFit: BoxFit.contain,
                    imagePadding: const EdgeInsets.all(14),
                    thumbnailLabel: 'Canal',
                    onPressed: () => context.push(
                      PlayerScreen.routePath,
                      extra: PlaybackContext(
                        contentType: PlaybackContentType.live,
                        itemId: item.id,
                        title: item.name,
                        containerExtension: item.containerExtension,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
