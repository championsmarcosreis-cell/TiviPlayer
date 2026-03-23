import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiviplayer/core/di/providers.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_credentials.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_session.dart';
import 'package:tiviplayer/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tiviplayer/features/player/domain/entities/playback_context.dart';
import 'package:tiviplayer/features/player/domain/entities/player_recovery_policy.dart';
import 'package:tiviplayer/features/player/domain/entities/resolved_playback.dart';
import 'package:tiviplayer/features/player/domain/repositories/player_repository.dart';
import 'package:tiviplayer/features/player/domain/usecases/resolve_playback_use_case.dart';
import 'package:tiviplayer/features/player/presentation/providers/player_providers.dart';
import 'package:tiviplayer/features/player/presentation/screens/player_screen.dart';
import 'package:tiviplayer/shared/testing/app_test_keys.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final originalVideoPlatform = VideoPlayerPlatform.instance;

  tearDown(() {
    VideoPlayerPlatform.instance = originalVideoPlatform;
  });

  test('fake video platform initializes controller', () async {
    final fakePlatform = _FakeVideoPlayerPlatform(
      initializationOutcomes: [_InitOutcome.success],
    );
    VideoPlayerPlatform.instance = fakePlatform;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse('https://example.test/stream.mp4'),
    );
    await controller.initialize().timeout(const Duration(seconds: 1));

    expect(controller.value.isInitialized, isTrue);
    await controller.dispose();
  });

  testWidgets(
    'retries initialization after play failure and disposes failed controller',
    (tester) async {
      final fakePlatform = _FakeVideoPlayerPlatform(
        initializationOutcomes: [_InitOutcome.success, _InitOutcome.success],
        playFailures: [true, false],
      );
      VideoPlayerPlatform.instance = fakePlatform;

      await _pumpPlayer(
        tester,
        recoveryPolicy: const PlayerRecoveryPolicy(
          maxInitializationRetries: 1,
          initializationBaseDelay: Duration(milliseconds: 1),
          initializationStepDelay: Duration.zero,
          runtimeRecoveryDelay: Duration(milliseconds: 1),
          bufferingStallThreshold: Duration(seconds: 1),
        ),
      );

      await _waitFor(
        tester,
        condition: () => fakePlatform.createdPlayerIds.isNotEmpty,
        timeout: const Duration(seconds: 1),
        step: const Duration(milliseconds: 20),
      );
      final screen = tester.widget<PlayerScreen>(find.byType(PlayerScreen));
      expect(screen.recoveryPolicy.maxInitializationRetries, 1);
      final loaded = await _waitForPlayerLoaded(tester);
      final hasErrorUi = find
          .byKey(AppTestKeys.playerErrorState)
          .evaluate()
          .isNotEmpty;
      final hasLoadedUi = find
          .byKey(AppTestKeys.playerLoadedState)
          .evaluate()
          .isNotEmpty;
      final hasLoadingText = find
          .textContaining('Carregando')
          .evaluate()
          .isNotEmpty;
      expect(
        loaded,
        isTrue,
        reason:
            'estado do fake: ${fakePlatform.debugState()} ui(error=$hasErrorUi loaded=$hasLoadedUi loading=$hasLoadingText)',
      );

      expect(fakePlatform.createdPlayerIds.length, 2);
      expect(
        fakePlatform.disposedPlayerIds,
        contains(fakePlatform.createdPlayerIds.first),
      );
    },
  );

  testWidgets('recovers automatically after runtime stream error', (
    tester,
  ) async {
    final fakePlatform = _FakeVideoPlayerPlatform(
      initializationOutcomes: [_InitOutcome.success, _InitOutcome.success],
    );
    VideoPlayerPlatform.instance = fakePlatform;

    await _pumpPlayer(
      tester,
      recoveryPolicy: const PlayerRecoveryPolicy(
        maxInitializationRetries: 0,
        maxRuntimeRecoveries: 1,
        initializationBaseDelay: Duration(milliseconds: 1),
        initializationStepDelay: Duration.zero,
        runtimeRecoveryDelay: Duration(milliseconds: 1),
        bufferingStallThreshold: Duration(seconds: 1),
      ),
    );

    await _waitFor(
      tester,
      condition: () => fakePlatform.createdPlayerIds.isNotEmpty,
      timeout: const Duration(seconds: 1),
      step: const Duration(milliseconds: 20),
    );
    final initiallyLoaded = await _waitForPlayerLoaded(tester);
    expect(
      initiallyLoaded,
      isTrue,
      reason: 'estado inicial do fake: ${fakePlatform.debugState()}',
    );
    expect(fakePlatform.latestCreatedPlayerId, isNotNull);

    fakePlatform.emitRuntimeErrorOnLatestPlayer();
    await tester.pump();
    expect(find.textContaining('Recuperando'), findsOneWidget);

    await _waitFor(
      tester,
      condition: () => fakePlatform.createdPlayerIds.length >= 2,
      timeout: const Duration(seconds: 3),
      step: const Duration(milliseconds: 20),
    );
    final recovered = await _waitForPlayerLoaded(tester);
    expect(
      recovered,
      isTrue,
      reason: 'estado pós-recuperação do fake: ${fakePlatform.debugState()}',
    );

    expect(fakePlatform.createdPlayerIds.length, 2);
    expect(find.byKey(AppTestKeys.playerLoadedState), findsOneWidget);
    expect(find.byKey(AppTestKeys.playerErrorState), findsNothing);
  });

  testWidgets('handles remote keyboard shortcuts for seek and play pause', (
    tester,
  ) async {
    final fakePlatform = _FakeVideoPlayerPlatform(
      initializationOutcomes: [_InitOutcome.success],
    );
    VideoPlayerPlatform.instance = fakePlatform;

    await _pumpPlayer(
      tester,
      recoveryPolicy: const PlayerRecoveryPolicy(
        maxInitializationRetries: 0,
        maxRuntimeRecoveries: 0,
        initializationBaseDelay: Duration(milliseconds: 1),
        initializationStepDelay: Duration.zero,
      ),
    );

    final loaded = await _waitForPlayerLoaded(tester);
    expect(loaded, isTrue, reason: 'player não carregou para testar atalhos');

    final playCallsAfterInit = fakePlatform.playCalls;
    expect(playCallsAfterInit, greaterThanOrEqualTo(1));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 20));

    expect(fakePlatform.seekRequests, isNotEmpty);
    expect(fakePlatform.seekRequests.last, const Duration(seconds: 10));

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await _waitFor(
      tester,
      condition: () => fakePlatform.pauseCalls >= 1,
      timeout: const Duration(seconds: 1),
      step: const Duration(milliseconds: 20),
    );
    expect(fakePlatform.pauseCalls, greaterThanOrEqualTo(1));

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await _waitFor(
      tester,
      condition: () => fakePlatform.playCalls > playCallsAfterInit,
      timeout: const Duration(seconds: 1),
      step: const Duration(milliseconds: 20),
    );
    expect(fakePlatform.playCalls, greaterThan(playCallsAfterInit));

    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await _waitFor(
      tester,
      condition: () => fakePlatform.volumeRequests.contains(0),
      timeout: const Duration(seconds: 1),
      step: const Duration(milliseconds: 20),
    );
    expect(fakePlatform.volumeRequests.last, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await _waitFor(
      tester,
      condition: () => fakePlatform.volumeRequests.last > 0,
      timeout: const Duration(seconds: 1),
      step: const Duration(milliseconds: 20),
    );
    expect(fakePlatform.volumeRequests.last, greaterThan(0));
  });
}

Future<void> _pumpPlayer(
  WidgetTester tester, {
  required PlayerRecoveryPolicy recoveryPolicy,
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        currentSessionProvider.overrideWithValue(_session),
        resolvePlaybackUseCaseProvider.overrideWithValue(
          ResolvePlaybackUseCase(_FakePlayerRepository()),
        ),
      ],
      child: MaterialApp(
        home: PlayerScreen(
          playbackContext: _playbackContext,
          recoveryPolicy: recoveryPolicy,
        ),
      ),
    ),
  );
}

Future<bool> _waitForPlayerLoaded(WidgetTester tester) async {
  var reachedTerminal = false;
  final end = DateTime.now().add(const Duration(seconds: 3));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    if (find.byKey(AppTestKeys.playerLoadedState).evaluate().isNotEmpty ||
        find.byKey(AppTestKeys.playerErrorState).evaluate().isNotEmpty) {
      reachedTerminal = true;
      break;
    }
  }

  if (!reachedTerminal) {
    final asyncError = tester.takeException();
    if (asyncError != null) {
      fail('Player não chegou a loaded/error. Exceção: $asyncError');
    }
    return false;
  }

  final hasError = find
      .byKey(AppTestKeys.playerErrorState)
      .evaluate()
      .isNotEmpty;
  final hasLoaded = find
      .byKey(AppTestKeys.playerLoadedState)
      .evaluate()
      .isNotEmpty;
  return !hasError && hasLoaded;
}

Future<void> _waitFor(
  WidgetTester tester, {
  required bool Function() condition,
  required Duration timeout,
  required Duration step,
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    if (condition()) {
      return;
    }
  }

  fail('Condição não atingida dentro de $timeout.');
}

const _playbackContext = PlaybackContext(
  contentType: PlaybackContentType.vod,
  itemId: 'vod-1',
  title: 'Teste VOD',
  containerExtension: 'mp4',
);

const _session = XtreamSession(
  credentials: XtreamCredentials(
    baseUrl: 'http://provider.example:8080',
    username: 'sergio',
    password: '123456',
  ),
  accountStatus: 'Active',
  serverUrl: 'http://provider.example:8080',
);

class _FakePlayerRepository implements PlayerRepository {
  @override
  ResolvedPlayback resolvePlayback(
    XtreamSession session,
    PlaybackContext context,
  ) {
    return ResolvedPlayback(
      uri: Uri.parse('https://example.test/stream.mp4'),
      context: context,
    );
  }
}

enum _InitOutcome { success, fail }

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  _FakeVideoPlayerPlatform({
    required List<_InitOutcome> initializationOutcomes,
    List<bool> playFailures = const [],
  }) : _initializationOutcomes = Queue<_InitOutcome>.from(
         initializationOutcomes,
       ),
       _playFailures = Queue<bool>.from(playFailures);

  final Queue<_InitOutcome> _initializationOutcomes;
  final Queue<bool> _playFailures;
  final Map<int, StreamController<VideoEvent>> _eventStreams =
      <int, StreamController<VideoEvent>>{};
  final Map<int, Duration> _positions = <int, Duration>{};

  final List<int> createdPlayerIds = <int>[];
  final List<int> disposedPlayerIds = <int>[];
  final List<int> listenedPlayerIds = <int>[];
  final List<int> initializedEventPlayerIds = <int>[];
  final List<int> initializationErrorPlayerIds = <int>[];
  final List<Duration> seekRequests = <Duration>[];
  final List<double> volumeRequests = <double>[];
  int playCalls = 0;
  int pauseCalls = 0;
  int _nextPlayerId = 1;
  int? latestCreatedPlayerId;

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) {
    return createWithOptions(
      VideoCreationOptions(
        dataSource: dataSource,
        viewType: VideoViewType.textureView,
      ),
    );
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final playerId = _nextPlayerId++;
    createdPlayerIds.add(playerId);
    latestCreatedPlayerId = playerId;

    final outcome = _initializationOutcomes.isNotEmpty
        ? _initializationOutcomes.removeFirst()
        : _InitOutcome.success;
    late final StreamController<VideoEvent> stream;
    stream = StreamController<VideoEvent>(
      sync: true,
      onListen: () {
        listenedPlayerIds.add(playerId);
        if (outcome == _InitOutcome.fail) {
          initializationErrorPlayerIds.add(playerId);
          stream.addError(
            PlatformException(
              code: 'VideoError',
              message: 'Falha fake na inicializacao.',
            ),
          );
          return;
        }

        initializedEventPlayerIds.add(playerId);
        stream.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(minutes: 2),
            size: const Size(1280, 720),
          ),
        );
      },
    );
    _eventStreams[playerId] = stream;

    return playerId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    return _eventStreams[playerId]!.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    disposedPlayerIds.add(playerId);
    final stream = _eventStreams.remove(playerId);
    await stream?.close();
  }

  @override
  Future<void> play(int playerId) async {
    playCalls += 1;
    final shouldFail = _playFailures.isNotEmpty && _playFailures.removeFirst();
    if (shouldFail) {
      throw PlatformException(
        code: 'VideoError',
        message: 'Falha fake no play.',
      );
    }
    _eventStreams[playerId]?.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: true,
      ),
    );
  }

  @override
  Future<void> pause(int playerId) async {
    pauseCalls += 1;
    _eventStreams[playerId]?.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: false,
      ),
    );
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    seekRequests.add(position);
    _positions[playerId] = position;
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    return _positions[playerId] ?? Duration.zero;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {
    volumeRequests.add(volume);
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    return const SizedBox.expand();
  }

  void emitRuntimeErrorOnLatestPlayer() {
    final playerId = latestCreatedPlayerId;
    if (playerId == null) {
      return;
    }
    _eventStreams[playerId]?.addError(
      PlatformException(code: 'VideoError', message: 'Falha fake em runtime.'),
    );
  }

  String debugState() {
    return 'created=${createdPlayerIds.length}, listened=${listenedPlayerIds.length}, initEvents=${initializedEventPlayerIds.length}, initErrors=${initializationErrorPlayerIds.length}, disposed=${disposedPlayerIds.length}, activeStreams=${_eventStreams.keys.length}';
  }
}
