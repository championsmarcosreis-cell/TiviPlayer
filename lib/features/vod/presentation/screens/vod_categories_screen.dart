import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/screens/home_screen.dart';
import '../../../../shared/testing/app_test_keys.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
import '../../../../shared/widgets/section_card.dart';
import '../providers/vod_providers.dart';
import 'vod_streams_screen.dart';

class VodCategoriesScreen extends ConsumerWidget {
  const VodCategoriesScreen({super.key});

  static const routePath = '/vod';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(vodCategoriesProvider);

    return AppScaffold(
      title: 'Filmes',
      subtitle: 'Categorias VOD da API Xtream',
      showBack: true,
      onBack: () => context.go(HomeScreen.routePath),
      child: AsyncStateBuilder(
        value: categories,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem categorias VOD',
        emptyMessage: 'A API não retornou categorias de filmes.',
        dataBuilder: (items) {
          final entries = [
            _CategoryItem(id: 'all', title: 'Todos', description: 'Sem filtro'),
            ...items.map(
              (item) => _CategoryItem(
                id: item.id,
                title: item.name,
                description: 'Categoria ${item.id}',
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
                          interactiveKey: entries[index].id == 'all'
                              ? AppTestKeys.vodCategoryAll
                              : null,
                          autofocus: index == 0,
                          testId: entries[index].id == 'all'
                              ? AppTestKeys.vodCategoryAllId
                              : null,
                          title: entries[index].title,
                          description: entries[index].description,
                          icon: Icons.video_library_outlined,
                          onPressed: () => context.push(
                            VodStreamsScreen.buildLocation(entries[index].id),
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
