import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_credentials.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_session.dart';
import 'package:tiviplayer/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tiviplayer/features/live/domain/entities/live_epg_entry.dart';
import 'package:tiviplayer/features/live/domain/entities/live_stream.dart';
import 'package:tiviplayer/features/live/presentation/providers/live_providers.dart';
import 'package:tiviplayer/features/live/presentation/screens/live_streams_screen.dart';
import 'package:tiviplayer/shared/presentation/layout/interface_mode_scope.dart';

void main() {
  testWidgets('mobile mostra EPG no destaque e no tile', (tester) async {
    final now = DateTime.now();
    final entries = _epgNowNext(now);
    final streams = _sampleStreams();

    await _pumpLiveScreen(
      tester,
      interfaceMode: InterfaceMode.mobile,
      streams: streams,
      epgByStreamId: {'stream-1': entries},
    );

    await tester.pumpAndSettle();

    expect(find.text('Canal em destaque'), findsOneWidget);
    expect(find.text('Proximo: Novela das 9'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();

    expect(find.textContaining('CANAL AO VIVO'), findsWidgets);
    expect(find.text('Agora: Jornal da Noite'), findsWidgets);
    expect(find.text('Canais disponíveis • 2'), findsOneWidget);
  });

  testWidgets('mobile mostra fallback quando EPG nao existe', (tester) async {
    final streams = _sampleStreams();

    await _pumpLiveScreen(
      tester,
      interfaceMode: InterfaceMode.mobile,
      streams: streams,
      epgByStreamId: const {'stream-1': <LiveEpgEntry>[]},
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();

    expect(find.text('Sem guia de programacao'), findsOneWidget);
    expect(find.textContaining('Canal com replay'), findsOneWidget);
  });

  testWidgets('tv faz prefetch de EPG no card com autofocus', (tester) async {
    final now = DateTime.now();
    final entries = _epgNowNext(now);
    final streamCalls = <String, int>{};

    await _pumpLiveScreen(
      tester,
      interfaceMode: InterfaceMode.tv,
      streams: [_sampleStreams().first],
      epgByStreamId: {'stream-1': entries},
      onEpgRequest: (streamId) {
        streamCalls.update(streamId, (value) => value + 1, ifAbsent: () => 1);
      },
    );

    await tester.pumpAndSettle();

    expect(find.text('Agora: Jornal da Noite'), findsWidgets);
    expect(streamCalls['stream-1'] ?? 0, greaterThanOrEqualTo(1));
  });
}

Future<void> _pumpLiveScreen(
  WidgetTester tester, {
  required InterfaceMode interfaceMode,
  required List<LiveStream> streams,
  required Map<String, List<LiveEpgEntry>> epgByStreamId,
  void Function(String streamId)? onEpgRequest,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentSessionProvider.overrideWithValue(_session),
        liveStreamsProvider.overrideWith((ref, categoryId) async => streams),
        liveShortEpgProvider.overrideWith((ref, streamId) async {
          onEpgRequest?.call(streamId);
          return epgByStreamId[streamId] ?? const <LiveEpgEntry>[];
        }),
      ],
      child: InterfaceModeScope(
        mode: interfaceMode,
        child: const MaterialApp(home: LiveStreamsScreen(categoryId: 'all')),
      ),
    ),
  );
}

List<LiveEpgEntry> _epgNowNext(DateTime now) {
  return [
    LiveEpgEntry(
      title: 'Jornal da Noite',
      startAt: now.subtract(const Duration(minutes: 10)),
      endAt: now.add(const Duration(minutes: 20)),
    ),
    LiveEpgEntry(
      title: 'Novela das 9',
      startAt: now.add(const Duration(minutes: 20)),
      endAt: now.add(const Duration(minutes: 80)),
    ),
  ];
}

List<LiveStream> _sampleStreams() {
  return const [
    LiveStream(
      id: 'stream-1',
      name: 'Canal Centro',
      hasArchive: true,
      isAdult: false,
      epgChannelId: 'epg-1',
      containerExtension: 'ts',
    ),
    LiveStream(
      id: 'stream-2',
      name: 'Canal Sul',
      hasArchive: false,
      isAdult: false,
    ),
  ];
}

const _session = XtreamSession(
  credentials: XtreamCredentials(
    baseUrl: 'http://provider.example:8080',
    username: 'sergio',
    password: '123456',
  ),
  accountStatus: 'Active',
  serverUrl: 'http://provider.example:8080',
);
