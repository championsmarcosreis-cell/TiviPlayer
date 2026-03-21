import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/screens/home_screen.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/section_card.dart';
import '../providers/live_providers.dart';
import 'live_streams_screen.dart';

class LiveCategoriesScreen extends StatelessWidget {
  const LiveCategoriesScreen({super.key});

  static const routePath = '/live';

  @override
  Widget build(BuildContext context) {
    return const _LiveCategoriesView();
  }
}

class _LiveCategoriesView extends ConsumerWidget {
  const _LiveCategoriesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(liveCategoriesProvider);

    return AppScaffold(
      title: 'Ao vivo',
      subtitle: 'Escolha uma categoria para abrir os canais disponíveis.',
      showBack: true,
      onBack: () => context.go(HomeScreen.routePath),
      child: AsyncStateBuilder(
        value: categories,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem categorias disponíveis',
        emptyMessage:
            'Nenhuma categoria de canais foi encontrada para este acesso.',
        dataBuilder: (items) {
          final entries = [
            const _CategoryItem(
              id: 'all',
              title: 'Todos',
              description: 'Abrir grade completa',
            ),
            ...items.map(
              (item) => _CategoryItem(
                id: item.id,
                title: item.name,
                description: 'Abrir categoria',
              ),
            ),
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final layout = DeviceLayout.of(context, constraints: constraints);
              final spacing = layout.cardSpacing;
              final columns = layout.columnsForWidth(
                constraints.maxWidth,
                minTileWidth: layout.isTv ? 330 : 280,
                maxColumns: layout.isTv ? 3 : 2,
              );
              final width = layout.itemWidth(
                constraints.maxWidth,
                columns: columns,
                spacing: spacing,
              );

              return SingleChildScrollView(
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (var index = 0; index < entries.length; index++)
                      SizedBox(
                        width: width,
                        child: SectionCard(
                          autofocus: index == 0,
                          title: entries[index].title,
                          description: entries[index].description,
                          icon: Icons.folder_open_rounded,
                          onPressed: () => context.push(
                            LiveStreamsScreen.buildLocation(entries[index].id),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}
