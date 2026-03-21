import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/screens/home_screen.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/section_card.dart';
import '../providers/series_providers.dart';
import 'series_items_screen.dart';

class SeriesCategoriesScreen extends ConsumerWidget {
  const SeriesCategoriesScreen({super.key});

  static const routePath = '/series';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(seriesCategoriesProvider);

    return AppScaffold(
      title: 'Séries',
      subtitle: 'Escolha uma coleção para abrir temporadas e episódios.',
      showBack: true,
      onBack: () => context.go(HomeScreen.routePath),
      child: AsyncStateBuilder(
        value: categories,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem coleções disponíveis',
        emptyMessage:
            'Nenhuma categoria de séries foi encontrada para este acesso.',
        dataBuilder: (items) {
          final entries = [
            const _CategoryItem(
              id: 'all',
              title: 'Todas',
              description: 'Abrir catálogo completo',
            ),
            ...items.map(
              (item) => _CategoryItem(
                id: item.id,
                title: item.name,
                description: 'Abrir coleção',
              ),
            ),
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 3
                  : constraints.maxWidth >= 720
                  ? 2
                  : 1;
              final spacing = 16.0;
              final width =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;

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
                          icon: Icons.folder_special_outlined,
                          onPressed: () => context.push(
                            SeriesItemsScreen.buildLocation(entries[index].id),
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
