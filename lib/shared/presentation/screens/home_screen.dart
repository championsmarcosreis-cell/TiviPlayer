import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/display_formatters.dart';
import '../../../features/auth/domain/entities/xtream_session.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../features/auth/presentation/screens/account_screen.dart';
import '../../../features/live/presentation/screens/live_categories_screen.dart';
import '../../../features/series/presentation/screens/series_categories_screen.dart';
import '../../../features/vod/presentation/screens/vod_categories_screen.dart';
import '../../testing/app_test_keys.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/section_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    if (session == null) {
      return const AppScaffold(
        title: 'Sua central',
        subtitle: 'Catálogo pronto para continuar assistindo.',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final expiresAt = DisplayFormatters.humanizeDate(session.expirationDate);
    final cards = [
      _HomeEntry(
        title: 'Ao vivo',
        description: 'Canais organizados para navegar rápido na TV.',
        icon: Icons.live_tv_rounded,
        interactiveKey: AppTestKeys.homeLiveCard,
        testId: AppTestKeys.homeLiveCardId,
        onTap: () => context.go(LiveCategoriesScreen.routePath),
      ),
      _HomeEntry(
        title: 'Filmes',
        description:
            'Posters, detalhes e acesso rápido ao catálogo sob demanda.',
        icon: Icons.movie_creation_outlined,
        interactiveKey: AppTestKeys.homeMoviesCard,
        testId: AppTestKeys.homeMoviesCardId,
        onTap: () => context.go(VodCategoriesScreen.routePath),
      ),
      _HomeEntry(
        title: 'Séries',
        description:
            'Coleções por categoria com capas e episódios disponíveis.',
        icon: Icons.tv_outlined,
        interactiveKey: AppTestKeys.homeSeriesCard,
        testId: AppTestKeys.homeSeriesCardId,
        onTap: () => context.go(SeriesCategoriesScreen.routePath),
      ),
      _HomeEntry(
        title: 'Minha assinatura',
        description: _buildAccountCardDescription(session, expiresAt),
        icon: Icons.verified_user_rounded,
        onTap: () => context.go(AccountScreen.routePath),
      ),
    ];

    return AppScaffold(
      title: 'Sua central',
      subtitle: 'Catálogo pronto para continuar assistindo.',
      actions: [
        FilledButton.tonalIcon(
          key: AppTestKeys.homeLogoutButton,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHero(session: session, expiresAt: expiresAt),
                const SizedBox(height: 24),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (var index = 0; index < cards.length; index++)
                      SizedBox(
                        width: width,
                        child: SectionCard(
                          interactiveKey: cards[index].interactiveKey,
                          autofocus: index == 0,
                          testId: cards[index].testId,
                          title: cards[index].title,
                          description: cards[index].description,
                          icon: cards[index].icon,
                          onPressed: cards[index].onTap,
                        ),
                      ),
                  ],
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
    this.interactiveKey,
    this.testId,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Key? interactiveKey;
  final String? testId;
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.session, required this.expiresAt});

  final XtreamSession session;
  final String? expiresAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final summary = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo, ${session.credentials.username}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Navegue por canais, filmes e séries com uma interface otimizada para TV e celular.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.verified_rounded, size: 18),
                      label: Text(
                        DisplayFormatters.humanizeAccountStatus(
                          session.accountStatus,
                        ),
                      ),
                    ),
                    if (expiresAt != null)
                      Chip(
                        avatar: const Icon(
                          Icons.event_available_rounded,
                          size: 18,
                        ),
                        label: Text('Vence em $expiresAt'),
                      ),
                    if (session.activeConnections != null &&
                        session.maxConnections != null)
                      Chip(
                        avatar: const Icon(
                          Icons.connected_tv_rounded,
                          size: 18,
                        ),
                        label: Text(
                          '${session.activeConnections}/${session.maxConnections} conexões',
                        ),
                      ),
                    if (session.isTrial == true)
                      const Chip(
                        avatar: Icon(Icons.workspace_premium_rounded, size: 18),
                        label: Text('Trial'),
                      ),
                  ],
                ),
              ],
            );

            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(width: 190),
                  const SizedBox(height: 24),
                  summary,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const BrandLogo(width: 220),
                const SizedBox(width: 28),
                Expanded(child: summary),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _buildAccountCardDescription(XtreamSession session, String? expiresAt) {
  final parts = [
    DisplayFormatters.humanizeAccountStatus(session.accountStatus),
    if (expiresAt != null) 'Vence em $expiresAt',
  ];

  if (parts.isEmpty) {
    return 'Consulte os dados do acesso neste aparelho.';
  }

  return parts.join(' • ');
}
