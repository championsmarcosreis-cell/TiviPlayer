import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiviplayer/app/theme/app_theme.dart';
import 'package:tiviplayer/core/di/providers.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_credentials.dart';
import 'package:tiviplayer/features/auth/domain/entities/xtream_session.dart';
import 'package:tiviplayer/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tiviplayer/features/home/presentation/providers/home_discovery_providers.dart';
import 'package:tiviplayer/features/auth/presentation/screens/login_screen.dart';
import 'package:tiviplayer/features/live/domain/entities/live_stream.dart';
import 'package:tiviplayer/features/live/presentation/providers/live_providers.dart';
import 'package:tiviplayer/features/player/presentation/screens/player_screen.dart';
import 'package:tiviplayer/features/series/domain/entities/series_item.dart';
import 'package:tiviplayer/features/series/presentation/providers/series_providers.dart';
import 'package:tiviplayer/features/vod/domain/entities/vod_info.dart';
import 'package:tiviplayer/features/vod/domain/entities/vod_stream.dart';
import 'package:tiviplayer/features/vod/presentation/providers/vod_providers.dart';
import 'package:tiviplayer/features/vod/presentation/screens/vod_details_screen.dart';
import 'package:tiviplayer/features/vod/presentation/screens/vod_streams_screen.dart';
import 'package:tiviplayer/shared/presentation/screens/home_screen.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_SCREENSHOT_TESTS');
  if (!enabled) {
    return;
  }

  testWidgets('gera screenshots mobile e tv', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _captureScenario(
      tester,
      sharedPreferences: prefs,
      scenario: _ScreenshotScenario.mobile,
      path: '../screenshots/mobile_login.png',
      child: const LoginScreen(),
    );
    await _captureScenario(
      tester,
      sharedPreferences: prefs,
      scenario: _ScreenshotScenario.mobile,
      path: '../screenshots/mobile_home.png',
      child: const HomeScreen(),
      overrides: [
        currentSessionProvider.overrideWith((ref) => _session),
        liveStreamsProvider.overrideWith((ref, categoryId) async => _live),
        vodStreamsProvider.overrideWith((ref, categoryId) async => _vod),
        seriesItemsProvider.overrideWith((ref, categoryId) async => _series),
        homeDiscoveryProvider.overrideWith((ref, limit) async => null),
      ],
    );
    await _captureScenario(
      tester,
      sharedPreferences: prefs,
      scenario: _ScreenshotScenario.mobile,
      path: '../screenshots/mobile_vod_list.png',
      child: const VodStreamsScreen(categoryId: 'all'),
      overrides: [
        currentSessionProvider.overrideWith((ref) => _session),
        vodStreamsProvider.overrideWith((ref, categoryId) async => _vod),
      ],
    );
    await _captureScenario(
      tester,
      sharedPreferences: prefs,
      scenario: _ScreenshotScenario.mobile,
      path: '../screenshots/mobile_detail.png',
      child: const VodDetailsScreen(vodId: '101'),
      overrides: [
        currentSessionProvider.overrideWith((ref) => _session),
        vodInfoProvider.overrideWith((ref, vodId) async => _vodInfo),
      ],
    );
    await _captureScenario(
      tester,
      sharedPreferences: prefs,
      scenario: _ScreenshotScenario.mobile,
      path: '../screenshots/mobile_player.png',
      child: const PlayerScreen(
        playbackContext: null,
        previewState: PlayerPreviewState(
          title: 'Horizonte Escarlate',
          isLive: false,
          position: Duration(minutes: 42, seconds: 12),
          duration: Duration(hours: 2, minutes: 5),
          isPlaying: true,
        ),
      ),
      overrides: [currentSessionProvider.overrideWith((ref) => _session)],
    );

    await _captureScenario(
      tester,
      sharedPreferences: prefs,
      scenario: _ScreenshotScenario.tv,
      path: '../screenshots/tv_login.png',
      child: const LoginScreen(),
    );
    await _captureScenario(
      tester,
      sharedPreferences: prefs,
      scenario: _ScreenshotScenario.tv,
      path: '../screenshots/tv_home.png',
      child: const HomeScreen(),
      overrides: [
        currentSessionProvider.overrideWith((ref) => _session),
        liveStreamsProvider.overrideWith((ref, categoryId) async => _live),
        vodStreamsProvider.overrideWith((ref, categoryId) async => _vod),
        seriesItemsProvider.overrideWith((ref, categoryId) async => _series),
        homeDiscoveryProvider.overrideWith((ref, limit) async => null),
      ],
    );
    await _captureScenario(
      tester,
      sharedPreferences: prefs,
      scenario: _ScreenshotScenario.tv,
      path: '../screenshots/tv_vod_list.png',
      child: const VodStreamsScreen(categoryId: 'all'),
      overrides: [
        currentSessionProvider.overrideWith((ref) => _session),
        vodStreamsProvider.overrideWith((ref, categoryId) async => _vod),
      ],
    );
    await _captureScenario(
      tester,
      sharedPreferences: prefs,
      scenario: _ScreenshotScenario.tv,
      path: '../screenshots/tv_vod_detail.png',
      child: const VodDetailsScreen(vodId: '101'),
      overrides: [
        currentSessionProvider.overrideWith((ref) => _session),
        vodInfoProvider.overrideWith((ref, vodId) async => _vodInfo),
      ],
    );
    await _captureScenario(
      tester,
      sharedPreferences: prefs,
      scenario: _ScreenshotScenario.tv,
      path: '../screenshots/tv_player.png',
      child: const PlayerScreen(
        playbackContext: null,
        previewState: PlayerPreviewState(
          title: 'Horizonte Escarlate',
          isLive: false,
          position: Duration(minutes: 42, seconds: 12),
          duration: Duration(hours: 2, minutes: 5),
          isPlaying: true,
        ),
      ),
      overrides: [currentSessionProvider.overrideWith((ref) => _session)],
    );
  });
}

enum _ScreenshotScenario { mobile, tv }

Future<void> _captureScenario(
  WidgetTester tester, {
  required SharedPreferences sharedPreferences,
  required _ScreenshotScenario scenario,
  required String path,
  required Widget child,
  List overrides = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = scenario == _ScreenshotScenario.mobile
      ? const Size(1080, 1920)
      : const Size(1920, 1080);

  final navigationMode = scenario == _ScreenshotScenario.mobile
      ? NavigationMode.traditional
      : NavigationMode.directional;
  const boundaryKey = ValueKey<String>('screenshot-boundary');

  await tester.pumpWidget(
    ProviderScope(
      key: ValueKey<String>('scope.$path'),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        builder: (context, appChild) {
          final data = MediaQuery.of(
            context,
          ).copyWith(navigationMode: navigationMode);
          return MediaQuery(
            data: data,
            child: RepaintBoundary(
              key: boundaryKey,
              child: appChild ?? const SizedBox.shrink(),
            ),
          );
        },
        home: child,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await expectLater(find.byKey(boundaryKey), matchesGoldenFile(path));
}

const _session = XtreamSession(
  credentials: XtreamCredentials(
    baseUrl: 'http://demo.provider',
    username: 'demo_user',
    password: 'demo_pass',
  ),
  accountStatus: 'Active',
  serverUrl: 'http://demo.provider',
  expirationDate: '1798761600',
  activeConnections: 1,
  maxConnections: 3,
);

const _vod = [
  VodStream(id: '101', name: 'Horizonte Escarlate', rating: '8.4'),
  VodStream(id: '102', name: 'Noite de Orion', rating: '7.8'),
  VodStream(id: '103', name: 'Cidade Neon', rating: '8.1'),
];

const _series = [
  SeriesItem(
    id: '201',
    name: 'Nebula 9',
    plot: 'Thriller futurista com temporadas em andamento.',
  ),
  SeriesItem(
    id: '202',
    name: 'Arquivo Lunar',
    plot: 'Misterio investigativo em episodios.',
  ),
];

const _live = [
  LiveStream(
    id: '301',
    name: 'Canal Prime HD',
    hasArchive: true,
    isAdult: false,
  ),
  LiveStream(
    id: '302',
    name: 'Esportes Max',
    hasArchive: false,
    isAdult: false,
  ),
];

const _vodInfo = VodInfo(
  id: '101',
  name: 'Horizonte Escarlate',
  plot:
      'Em um futuro proximo, uma equipe precisa atravessar uma cidade isolada para resgatar uma transmissao perdida.',
  genre: 'Ficcao cientifica • Acao',
  cast: 'R. Duarte, M. Salles, I. Costa',
  director: 'L. Azevedo',
  duration: '2h05',
  releaseDate: '1735689600',
  rating: '8.4',
);
