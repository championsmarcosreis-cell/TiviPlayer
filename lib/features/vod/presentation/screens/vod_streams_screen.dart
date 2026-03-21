import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/content_list_tile.dart';
import '../providers/vod_providers.dart';
import 'vod_details_screen.dart';

class VodStreamsScreen extends ConsumerWidget {
  const VodStreamsScreen({super.key, required this.categoryId});

  static const routePath = '/vod/category/:categoryId';

  static String buildLocation(String categoryId) => '/vod/category/$categoryId';

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveCategoryId = categoryId == 'all' ? null : categoryId;
    final streams = ref.watch(vodStreamsProvider(effectiveCategoryId));

    return AppScaffold(
      title: 'Filmes',
      subtitle: effectiveCategoryId == null
          ? 'Catálogo completo'
          : 'Categoria $effectiveCategoryId',
      showBack: true,
      child: AsyncStateBuilder(
        value: streams,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem filmes',
        emptyMessage: 'A API não retornou itens VOD para esse filtro.',
        dataBuilder: (items) {
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final subtitleParts = [
                if (item.rating != null) 'Nota ${item.rating}',
                if (item.containerExtension != null) item.containerExtension!,
                if (item.categoryId != null) 'Cat. ${item.categoryId}',
              ];

              return ContentListTile(
                autofocus: index == 0,
                title: item.name,
                subtitle: subtitleParts.isEmpty
                    ? 'Filme VOD'
                    : subtitleParts.join(' • '),
                icon: Icons.movie_creation_outlined,
                onPressed: () =>
                    context.push(VodDetailsScreen.buildLocation(item.id)),
              );
            },
          );
        },
      ),
    );
  }
}
