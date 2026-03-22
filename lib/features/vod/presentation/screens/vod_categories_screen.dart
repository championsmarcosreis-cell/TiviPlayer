import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/tv/tv_focusable.dart';
import '../../../../shared/presentation/screens/home_screen.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/testing/app_test_keys.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/async_state_builder.dart';
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
      subtitle: 'Escolha uma coleção para abrir o catálogo sob demanda.',
      showBack: true,
      showBrand: false,
      onBack: () => context.go(HomeScreen.routePath),
      child: AsyncStateBuilder(
        value: categories,
        isEmpty: (items) => items.isEmpty,
        emptyTitle: 'Sem coleções disponíveis',
        emptyMessage:
            'Nenhuma categoria de filmes foi encontrada para este acesso.',
        dataBuilder: (items) {
          final entries = [
            const _CategoryItem(
              id: 'all',
              title: 'Todos',
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
              final layout = DeviceLayout.of(context, constraints: constraints);
              final spacing = layout.cardSpacing;
              final columns = layout.columnsForWidth(
                constraints.maxWidth,
                minTileWidth: layout.isTv ? 238 : 280,
                maxColumns: layout.isTv ? 5 : 2,
              );
              final width = layout.itemWidth(
                constraints.maxWidth,
                columns: columns,
                spacing: spacing,
              );

              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: layout.pageBottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategorySectionHeader(
                      layout: layout,
                      title: 'Coleções',
                      subtitle: '${entries.length} categorias disponíveis',
                    ),
                    SizedBox(height: layout.cardSpacing),
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (var index = 0; index < entries.length; index++)
                          SizedBox(
                            width: width,
                            child: _CategoryTile(
                              layout: layout,
                              title: entries[index].title,
                              description: entries[index].description,
                              icon: Icons.video_library_outlined,
                              badge: entries[index].id == 'all'
                                  ? 'COMPLETO'
                                  : null,
                              interactiveKey: entries[index].id == 'all'
                                  ? AppTestKeys.vodCategoryAll
                                  : null,
                              autofocus: index == 0,
                              testId: entries[index].id == 'all'
                                  ? AppTestKeys.vodCategoryAllId
                                  : null,
                              onPressed: () => context.push(
                                VodStreamsScreen.buildLocation(
                                  entries[index].id,
                                ),
                              ),
                            ),
                          ),
                      ],
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

class _CategorySectionHeader extends StatelessWidget {
  const _CategorySectionHeader({
    required this.layout,
    required this.title,
    required this.subtitle,
  });

  final DeviceLayout layout;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: layout.isTv ? 30 : 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: layout.isTv ? 4 : 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.layout,
    required this.title,
    required this.description,
    required this.icon,
    required this.onPressed,
    this.badge,
    this.autofocus = false,
    this.interactiveKey,
    this.testId,
  });

  final DeviceLayout layout;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onPressed;
  final String? badge;
  final bool autofocus;
  final Key? interactiveKey;
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusable(
      autofocus: autofocus,
      interactiveKey: interactiveKey,
      testId: testId,
      onPressed: onPressed,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.all(layout.isTv ? 14 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.isTv ? 22 : 18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: focused
                  ? [
                      colorScheme.primary.withValues(alpha: 0.24),
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.92,
                      ),
                    ]
                  : [
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.78,
                      ),
                      colorScheme.surface.withValues(alpha: 0.92),
                    ],
            ),
            border: Border.all(
              color: focused
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.52),
              width: focused ? 2 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: layout.isTv ? 128 : 146),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: layout.isTv ? 42 : 42,
                      height: layout.isTv ? 42 : 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.secondary.withValues(alpha: 0.18),
                      ),
                      child: Icon(icon, color: colorScheme.secondary),
                    ),
                    const Spacer(),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: colorScheme.primary.withValues(alpha: 0.16),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.42),
                          ),
                        ),
                        child: Text(
                          badge!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                letterSpacing: 0.7,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: layout.isTv ? 12 : 14),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: layout.isTv ? 22 : 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: layout.isTv ? 6 : 8),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
