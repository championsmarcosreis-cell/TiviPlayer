import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/account_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/live/presentation/screens/live_categories_screen.dart';
import '../../features/live/presentation/screens/live_streams_screen.dart';
import '../../features/player/domain/entities/playback_context.dart';
import '../../features/player/presentation/screens/player_screen.dart';
import '../../features/player/presentation/support/player_screen_arguments.dart';
import '../../features/series/presentation/screens/series_categories_screen.dart';
import '../../features/series/presentation/screens/series_details_screen.dart';
import '../../features/series/presentation/screens/series_items_screen.dart';
import '../../features/vod/presentation/screens/vod_categories_screen.dart';
import '../../features/vod/presentation/screens/vod_details_screen.dart';
import '../../features/vod/presentation/screens/vod_streams_screen.dart';
import '../../shared/presentation/screens/home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(
    authControllerProvider.select((state) => state.status),
  );

  return GoRouter(
    initialLocation: SplashScreen.routePath,
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: HomeScreen.routePath,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AccountScreen.routePath,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: LiveCategoriesScreen.routePath,
        builder: (context, state) => const LiveCategoriesScreen(),
      ),
      GoRoute(
        path: LiveStreamsScreen.routePath,
        builder: (context, state) =>
            LiveStreamsScreen(categoryId: state.pathParameters['categoryId']!),
      ),
      GoRoute(
        path: VodCategoriesScreen.routePath,
        builder: (context, state) => const VodCategoriesScreen(),
      ),
      GoRoute(
        path: VodStreamsScreen.routePath,
        builder: (context, state) =>
            VodStreamsScreen(categoryId: state.pathParameters['categoryId']!),
      ),
      GoRoute(
        path: VodDetailsScreen.routePath,
        builder: (context, state) =>
            VodDetailsScreen(vodId: state.pathParameters['vodId']!),
      ),
      GoRoute(
        path: SeriesCategoriesScreen.routePath,
        builder: (context, state) => const SeriesCategoriesScreen(),
      ),
      GoRoute(
        path: SeriesItemsScreen.routePath,
        builder: (context, state) =>
            SeriesItemsScreen(categoryId: state.pathParameters['categoryId']!),
      ),
      GoRoute(
        path: SeriesDetailsScreen.routePath,
        builder: (context, state) =>
            SeriesDetailsScreen(seriesId: state.pathParameters['seriesId']!),
      ),
      GoRoute(
        path: PlayerScreen.routePath,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is PlayerScreenArguments) {
            return PlayerScreen(arguments: extra);
          }

          return PlayerScreen(
            arguments: extra == null
                ? null
                : PlayerScreenArguments.standalone(extra as PlaybackContext),
          );
        },
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isInitializing = authStatus == AuthStatus.initializing;
      final isAuthenticated = authStatus == AuthStatus.authenticated;
      final isLogin = location == LoginScreen.routePath;
      final isSplash = location == SplashScreen.routePath;

      if (isInitializing && !isSplash) {
        return SplashScreen.routePath;
      }

      if (!isInitializing && !isAuthenticated && !isLogin) {
        return LoginScreen.routePath;
      }

      if (isAuthenticated && (isLogin || isSplash)) {
        return HomeScreen.routePath;
      }

      if (!isAuthenticated && isSplash) {
        return LoginScreen.routePath;
      }

      return null;
    },
  );
});
