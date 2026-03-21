import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/content_list_tile.dart';
import '../providers/series_providers.dart';
import 'series_details_screen.dart';

class SeriesItemsScreen extends ConsumerWidget {
  const SeriesItemsScreen({super.key, required this.categoryId});

  static const routePath = '/series/category/:categoryId';

  static String buildLocation(String categoryId) =>
      '/series/category/$categoryId';

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveCategoryId = categoryId == 'all' ? null : categoryId;
    final series = ref.watch(seriesItemsProvider(effectiveCategoryId));

    return AppScaffold(
      title: 'Séries',
      subtitle: effectiveCategoryId == null
          ? 'Catálogo completo'
          : 'Categoria $effectiveCategoryId',
      showBack: true,
      child: AsyncStateBuilder(
        value: series,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem séries',
        emptyMessage: 'A API não retornou séries para esse filtro.',
        dataBuilder: (items) {
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final subtitleParts = [
                if (item.categoryId != null) 'Cat. ${item.categoryId}',
                if (item.plot != null && item.plot!.isNotEmpty)
                  'Resumo disponível',
              ];

              return ContentListTile(
                autofocus: index == 0,
                title: item.name,
                subtitle: subtitleParts.isEmpty
                    ? 'Série'
                    : subtitleParts.join(' • '),
                icon: Icons.tv_outlined,
                onPressed: () =>
                    context.push(SeriesDetailsScreen.buildLocation(item.id)),
              );
            },
          );
        },
      ),
    );
  }
}
