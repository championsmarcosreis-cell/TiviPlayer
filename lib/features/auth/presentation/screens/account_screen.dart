import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/display_formatters.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../controllers/auth_controller.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static const routePath = '/account';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    if (session == null) {
      return AppScaffold(
        title: 'Minha assinatura',
        subtitle: 'Informações do acesso sincronizadas com sua conta.',
        showBack: true,
        onBack: () => context.go('/home'),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final expiresAt = DisplayFormatters.humanizeDate(session.expirationDate);
    final serviceTime = DisplayFormatters.humanizeDate(session.serverTimeNow);
    final accountDetails = <_AccountDetail>[
      _AccountDetail(
        label: 'Status',
        value: DisplayFormatters.humanizeAccountStatus(session.accountStatus),
        icon: Icons.verified_rounded,
      ),
      if (expiresAt != null)
        _AccountDetail(
          label: 'Vencimento',
          value: expiresAt,
          icon: Icons.event_available_rounded,
        ),
      if (session.isTrial != null)
        _AccountDetail(
          label: 'Plano',
          value: session.isTrial! ? 'Período de teste' : 'Assinatura ativa',
          icon: Icons.workspace_premium_rounded,
        ),
      if (session.activeConnections != null)
        _AccountDetail(
          label: 'Conexões ativas',
          value: '${session.activeConnections}',
          icon: Icons.connected_tv_rounded,
        ),
      if (session.maxConnections != null)
        _AccountDetail(
          label: 'Máximo simultâneo',
          value: '${session.maxConnections}',
          icon: Icons.groups_rounded,
        ),
      if (session.serverTimezone != null)
        _AccountDetail(
          label: 'Fuso horário',
          value: session.serverTimezone!,
          icon: Icons.schedule_rounded,
        ),
      if (serviceTime != null)
        _AccountDetail(
          label: 'Horário do serviço',
          value: serviceTime,
          icon: Icons.access_time_filled_rounded,
        ),
    ];

    return AppScaffold(
      title: 'Minha assinatura',
      subtitle: 'Informações do acesso sincronizadas com sua conta.',
      showBack: true,
      onBack: () => context.go('/home'),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 760;
                    final showConnectionsHighlight =
                        session.activeConnections != null &&
                        session.maxConnections != null;

                    final summary = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.credentials.username,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            Chip(
                              avatar: const Icon(
                                Icons.verified_rounded,
                                size: 18,
                              ),
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
                            if (session.isTrial == true)
                              const Chip(
                                avatar: Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 18,
                                ),
                                label: Text('Trial'),
                              ),
                          ],
                        ),
                        if (session.message != null &&
                            session.message!.trim().isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            session.message!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ],
                    );

                    if (!isWide || !showConnectionsHighlight) {
                      return summary;
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: summary),
                        const SizedBox(width: 24),
                        _ConnectionsHighlight(
                          activeConnections: session.activeConnections,
                          maxConnections: session.maxConnections,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (accountDetails.isNotEmpty) ...[
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1100
                      ? 3
                      : constraints.maxWidth >= 720
                      ? 2
                      : 1;
                  final spacing = 16.0;
                  final totalSpacing = spacing * (columns - 1);
                  final width = (constraints.maxWidth - totalSpacing) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final detail in accountDetails)
                        SizedBox(
                          width: width,
                          child: _DetailCard(detail: detail),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConnectionsHighlight extends StatelessWidget {
  const _ConnectionsHighlight({
    required this.activeConnections,
    required this.maxConnections,
  });

  final int? activeConnections;
  final int? maxConnections;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uso simultâneo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            '${activeConnections ?? 0}/${maxConnections ?? 0}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Conexões ativas no momento',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.detail});

  final _AccountDetail detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: colorScheme.primary.withValues(alpha: 0.14),
              ),
              child: Icon(detail.icon, color: colorScheme.primary),
            ),
            const SizedBox(height: 18),
            Text(detail.label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(detail.value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _AccountDetail {
  const _AccountDetail({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}
