import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_credentials.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_session.dart';
import 'package:tiviplayer/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tiviplayer/features/live/domain/entities/live_epg_entry.dart';
import 'package:tiviplayer/features/live/domain/entities/live_stream.dart';
import 'package:tiviplayer/features/live/presentation/providers/live_providers.dart';
import 'package:tiviplayer/features/series/domain/entities/series_item.dart';
import 'package:tiviplayer/features/series/presentation/providers/series_providers.dart';
import 'package:tiviplayer/features/vod/domain/entities/vod_category.dart';
import 'package:tiviplayer/features/vod/domain/entities/vod_stream.dart';
import 'package:tiviplayer/features/vod/presentation/providers/vod_providers.dart';
import 'package:tiviplayer/shared/presentation/layout/interface_mode_scope.dart';
import 'package:tiviplayer/shared/presentation/screens/home_screen.dart';

const _session = XtreamSession(
  credentials: XtreamCredentials(
    baseUrl: 'http://provider.example:8080',
    username: 'marcos',
    password: 'secret',
  ),
  accountStatus: 'Active',
  serverUrl: 'http://provider.example:8080',
  expirationDate: '1798761600',
  activeConnections: 1,
  maxConnections: 3,
);

void main() {
  testWidgets('home mostra status da assinatura sem expor URL técnica', (
    tester,
  ) async {
    await _pumpHomeScreen(tester);

    await tester.pumpAndSettle();

    expect(find.text('Minha assinatura'), findsOneWidget);
    expect(find.textContaining('Ativa'), findsWidgets);
    expect(find.textContaining('provider.example'), findsNothing);
    expect(find.textContaining('8080'), findsNothing);
    expect(find.textContaining('http://'), findsNothing);
  });

  testWidgets('home tv mostra programa atual e faixa horaria nos destaques', (
    tester,
  ) async {
    final now = DateTime.now();
    final current = LiveEpgEntry(
      title: 'Jornal da Manha',
      startAt: now.subtract(const Duration(minutes: 12)),
      endAt: now.add(const Duration(minutes: 18)),
    );
    final next = LiveEpgEntry(
      title: 'Giro do Esporte',
      startAt: now.add(const Duration(minutes: 18)),
      endAt: now.add(const Duration(minutes: 58)),
    );

    await _pumpHomeScreen(
      tester,
      interfaceMode: InterfaceMode.tv,
      streams: _sampleStreams(),
      epgByStreamId: {
        'stream-1': [current, next],
      },
    );

    await tester.pumpAndSettle();

    expect(find.text('Destaques de agora'), findsOneWidget);
    expect(find.text('Jornal da Manha'), findsOneWidget);
    expect(
      find.text(_formatRange(current.startAt, current.endAt)),
      findsOneWidget,
    );
    expect(
      find.text('Depois ${_formatClock(next.startAt)} • Giro do Esporte'),
      findsNothing,
    );
  });

  testWidgets('home tv usa fallback limpo quando o canal nao tem EPG', (
    tester,
  ) async {
    await _pumpHomeScreen(
      tester,
      interfaceMode: InterfaceMode.tv,
      streams: [_sampleStreams().last],
    );

    await tester.pumpAndSettle();

    expect(find.text('No ar agora'), findsOneWidget);
    expect(find.text('Entre no canal para assistir agora'), findsOneWidget);
    expect(find.text('Canal Sul'), findsOneWidget);
  });
}

Future<void> _pumpHomeScreen(
  WidgetTester tester, {
  InterfaceMode interfaceMode = InterfaceMode.mobile,
  List<LiveStream> streams = const <LiveStream>[],
  Map<String, List<LiveEpgEntry>> epgByStreamId =
      const <String, List<LiveEpgEntry>>{},
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = interfaceMode == InterfaceMode.tv
      ? const Size(1920, 1080)
      : const Size(1280, 720);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentSessionProvider.overrideWith((ref) => _session),
        liveStreamsProvider.overrideWith((ref, categoryId) async => streams),
        liveShortEpgProvider.overrideWith((ref, streamId) async {
          return epgByStreamId[streamId] ?? const <LiveEpgEntry>[];
        }),
        vodCategoriesProvider.overrideWith(
          (ref) async => const <VodCategory>[],
        ),
        vodStreamsProvider.overrideWith((ref, categoryId) async {
          return const <VodStream>[];
        }),
        seriesItemsProvider.overrideWith((ref, categoryId) async {
          return const <SeriesItem>[];
        }),
      ],
      child: InterfaceModeScope(
        mode: interfaceMode,
        child: const MaterialApp(home: HomeScreen()),
      ),
    ),
  );
}

List<LiveStream> _sampleStreams() {
  return const [
    LiveStream(
      id: 'stream-1',
      name: 'Canal Centro',
      hasArchive: true,
      isAdult: false,
      epgChannelId: 'epg-1',
      iconUrl: 'https://example.com/logo.png',
    ),
    LiveStream(
      id: 'stream-2',
      name: 'Canal Sul',
      hasArchive: false,
      isAdult: false,
    ),
  ];
}

String _formatRange(DateTime startAt, DateTime endAt) {
  return '${_formatClock(startAt)} - ${_formatClock(endAt)}';
}

String _formatClock(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
