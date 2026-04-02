import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_credentials.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_session.dart';
import 'package:tiviplayer/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tiviplayer/features/live/domain/entities/live_category.dart';
import 'package:tiviplayer/features/live/domain/entities/live_epg_entry.dart';
import 'package:tiviplayer/features/live/domain/entities/live_stream.dart';
import 'package:tiviplayer/features/live/presentation/providers/live_providers.dart';
import 'package:tiviplayer/features/live/presentation/screens/live_categories_screen.dart';
import 'package:tiviplayer/shared/presentation/layout/interface_mode_scope.dart';

void main() {
  testWidgets(
    'mobile abre guia live com linha do tempo e cards reagindo ao horario',
    (tester) async {
      final now = DateTime.now();
      final nextSlotLabel = _resolveNextMobileSlotLabel(now);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSessionProvider.overrideWithValue(_session),
            liveCategoriesProvider.overrideWith(
              (ref) async => const [
                LiveCategory(id: 'sports', name: 'Esportes'),
                LiveCategory(id: 'news', name: 'Jornalismo'),
              ],
            ),
            liveStreamsProvider.overrideWith((ref, categoryId) async {
              return const [
                LiveStream(
                  id: 'stream-1',
                  name: 'Canal Centro',
                  categoryId: 'sports',
                  hasArchive: true,
                  isAdult: false,
                  epgChannelId: 'epg-1',
                  iconUrl: 'https://example.com/logo.png',
                ),
                LiveStream(
                  id: 'stream-2',
                  name: 'Canal Sul',
                  categoryId: 'news',
                  hasArchive: false,
                  isAdult: false,
                ),
              ];
            }),
            liveShortEpgProvider.overrideWith((ref, streamId) async {
              if (streamId != 'stream-1') {
                return const <LiveEpgEntry>[];
              }
              return [
                LiveEpgEntry(
                  title: 'Jornal da Noite',
                  startAt: now.subtract(const Duration(minutes: 10)),
                  endAt: now.add(const Duration(minutes: 1)),
                ),
                LiveEpgEntry(
                  title: 'Esporte Total',
                  startAt: now.add(const Duration(minutes: 1)),
                  endAt: now.add(const Duration(minutes: 80)),
                ),
              ];
            }),
          ],
          child: const InterfaceModeScope(
            mode: InterfaceMode.mobile,
            child: MaterialApp(home: LiveCategoriesScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Buscar canal...'), findsOneWidget);
      expect(find.text('Agora'), findsOneWidget);
      expect(find.text(nextSlotLabel), findsOneWidget);
      expect(find.text('Filtros do guia'), findsOneWidget);
      expect(find.text('Canais no guia'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Esportes'), findsOneWidget);
      expect(find.text('Canal Centro'), findsWidgets);
      expect(find.text('Grade mobile com o contexto do agora'), findsNothing);
      expect(find.text('Jornal da Noite'), findsOneWidget);
      expect(find.textContaining('Esporte Total'), findsOneWidget);

      await tester.tap(find.text(nextSlotLabel));
      await tester.pumpAndSettle();

      expect(
        find.text('Os cards mostram o que acontece em $nextSlotLabel.'),
        findsOneWidget,
      );
      expect(find.text('Jornal da Noite'), findsNothing);
      expect(find.text('Esporte Total'), findsOneWidget);
    },
  );
}

const _session = XtreamSession(
  credentials: XtreamCredentials(
    baseUrl: 'http://provider.example:8080',
    username: 'marcos',
    password: 'secret',
  ),
  accountStatus: 'Active',
  serverUrl: 'http://provider.example:8080',
);

String _resolveNextMobileSlotLabel(DateTime now) {
  var candidate = _resolveGuideWindowStart(now);
  do {
    candidate = candidate.add(const Duration(minutes: 30));
  } while (!candidate.isAfter(now));
  return _formatClock(candidate);
}

DateTime _resolveGuideWindowStart(DateTime now) {
  final roundedMinute = now.minute < 30 ? 0 : 30;
  final anchor = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    roundedMinute,
  );
  return anchor.subtract(const Duration(minutes: 30));
}

String _formatClock(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
