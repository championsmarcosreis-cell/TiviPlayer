import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/layout/device_layout.dart';
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
          : 'Seleção disponível',
      showBack: true,
      child: AsyncStateBuilder(
        value: series,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem séries disponíveis',
        emptyMessage: 'Nenhuma série foi encontrada para o filtro selecionado.',
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

                  return ContentListTile(
                    autofocus: index == 0,
                    title: item.name,
                    subtitle: item.plot?.trim().isNotEmpty == true
                        ? item.plot
                        : 'Série disponível para assistir',
                    icon: Icons.tv_outlined,
                    imageUrl: item.coverUrl,
                    thumbnailLabel: 'Capa indisponível',
                    onPressed: () => context.push(
                      SeriesDetailsScreen.buildLocation(item.id),
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
