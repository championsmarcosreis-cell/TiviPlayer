import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/display_formatters.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
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
        onBack: () {
          if (context.canPop()) {
            context.pop();
            return;
          }
          context.go('/home');
        },
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
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go('/home');
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = DeviceLayout.of(context, constraints: constraints);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(layout.cardPadding),
                    child: LayoutBuilder(
                      builder: (context, heroConstraints) {
                        final isWide =
                            layout.isTv || heroConstraints.maxWidth >= 760;
                        final showConnectionsHighlight =
                            session.activeConnections != null &&
                            session.maxConnections != null;

                        final summary = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.credentials.username,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontSize: layout.isTv ? 38 : 32),
                            ),
                            SizedBox(height: layout.sectionSpacing),
                            Wrap(
                              spacing: layout.isTv ? 12 : 10,
                              runSpacing: layout.isTv ? 12 : 10,
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
                              SizedBox(height: layout.sectionSpacing),
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
                            SizedBox(width: layout.cardSpacing),
                            _ConnectionsHighlight(
                              activeConnections: session.activeConnections,
                              maxConnections: session.maxConnections,
                              layout: layout,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                if (accountDetails.isNotEmpty) ...[
                  SizedBox(height: layout.sectionSpacing + 8),
                  LayoutBuilder(
                    builder: (context, gridConstraints) {
                      final spacing = layout.cardSpacing;
                      final columns = layout.columnsForWidth(
                        gridConstraints.maxWidth,
                        minTileWidth: layout.isTv ? 320 : 270,
                        maxColumns: layout.isTv ? 3 : 2,
                      );
                      final width = layout.itemWidth(
                        gridConstraints.maxWidth,
                        columns: columns,
                        spacing: spacing,
                      );

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final detail in accountDetails)
                            SizedBox(
                              width: width,
                              child: _DetailCard(
                                detail: detail,
                                layout: layout,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConnectionsHighlight extends StatelessWidget {
  const _ConnectionsHighlight({
    required this.activeConnections,
    required this.maxConnections,
    required this.layout,
  });

  final int? activeConnections;
  final int? maxConnections;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: layout.isTv ? 250 : 220,
      padding: EdgeInsets.all(layout.isTv ? 22 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isTv ? 26 : 24),
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
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: layout.isTv ? 40 : 32,
            ),
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
  const _DetailCard({required this.detail, required this.layout});

  final _AccountDetail detail;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(layout.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: layout.isTv ? 56 : 48,
              height: layout.isTv ? 56 : 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(layout.isTv ? 18 : 16),
                color: colorScheme.primary.withValues(alpha: 0.14),
              ),
              child: Icon(
                detail.icon,
                color: colorScheme.primary,
                size: layout.isTv ? 30 : 24,
              ),
            ),
            SizedBox(height: layout.sectionSpacing + 2),
            Text(detail.label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              detail.value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: layout.isTv ? 28 : 22),
            ),
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
