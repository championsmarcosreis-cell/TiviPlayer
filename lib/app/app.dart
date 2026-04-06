import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/presentation/controllers/device_interaction_profile_provider.dart';
import '../shared/presentation/controllers/interface_mode_controller.dart';
import '../shared/presentation/layout/interface_mode_heuristics.dart';
import '../shared/presentation/layout/interface_mode_scope.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class TiviPlayerApp extends ConsumerWidget {
  const TiviPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interfaceMode = ref.watch(interfaceModeControllerProvider);
    final deviceProfileAsync = ref.watch(deviceInteractionProfileProvider);
    final deviceProfile = deviceProfileAsync is AsyncData
        ? deviceProfileAsync.value
        : null;

    return InterfaceModeScope(
      mode: interfaceMode,
      deviceProfile: deviceProfile,
      child: MaterialApp.router(
        title: 'TiviPlayer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final resolvedMode = InterfaceModeHeuristics.resolveMode(
            preferredMode: interfaceMode,
            navigationMode: mediaQuery.navigationMode,
            viewportWidth: mediaQuery.size.width,
            viewportHeight: mediaQuery.size.height,
            deviceProfile: deviceProfile,
          );
          if (resolvedMode != InterfaceMode.tv) {
            return child ?? const SizedBox.shrink();
          }

          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: const TextScaler.linear(0.9)),
            child: child ?? const SizedBox.shrink(),
          );
        },
        routerConfig: ref.watch(appRouterProvider),
      ),
    );
  }
}
