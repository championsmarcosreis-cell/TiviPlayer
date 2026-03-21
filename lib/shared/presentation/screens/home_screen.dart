import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../features/live/presentation/screens/live_categories_screen.dart';
import '../../../features/series/presentation/screens/series_categories_screen.dart';
import '../../../features/vod/presentation/screens/vod_categories_screen.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/section_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final cards = [
      _HomeEntry(
        title: 'Live',
        description: 'Categorias e canais ao vivo por grupo.',
        icon: Icons.live_tv_rounded,
        onTap: () => context.go(LiveCategoriesScreen.routePath),
      ),
      _HomeEntry(
        title: 'Filmes',
        description: 'Catálogo VOD com listagem leve e detalhes básicos.',
        icon: Icons.movie_creation_outlined,
        onTap: () => context.go(VodCategoriesScreen.routePath),
      ),
      _HomeEntry(
        title: 'Séries',
        description: 'Categorias, listagens e metadados por série.',
        icon: Icons.tv_outlined,
        onTap: () => context.go(SeriesCategoriesScreen.routePath),
      ),
    ];

    return AppScaffold(
      title: 'TiviPlayer',
      subtitle:
          '${session.credentials.username} conectado em ${session.displayServer}',
      actions: [
        FilledButton.tonalIcon(
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sair'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 3
              : constraints.maxWidth >= 720
              ? 2
              : 1;
          final spacing = 18.0;
          final totalSpacing = spacing * (columns - 1);
          final width = (constraints.maxWidth - totalSpacing) / columns;

          return SingleChildScrollView(
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var index = 0; index < cards.length; index++)
                  SizedBox(
                    width: width,
                    child: SectionCard(
                      autofocus: index == 0,
                      title: cards[index].title,
                      description: cards[index].description,
                      icon: cards[index].icon,
                      onPressed: cards[index].onTap,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeEntry {
  const _HomeEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
}
