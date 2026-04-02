import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/presentation/controllers/device_interaction_profile_provider.dart';
import '../shared/presentation/controllers/interface_mode_controller.dart';
import '../shared/presentation/layout/interface_mode_scope.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class TiviPlayerApp extends ConsumerWidget {
  const TiviPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interfaceMode = ref.watch(interfaceModeControllerProvider);
    final deviceProfileAsync = ref.watch(deviceInteractionProfileProvider);
    final deviceProfile =
        deviceProfileAsync is AsyncData ? deviceProfileAsync.value : null;

    return InterfaceModeScope(
      mode: interfaceMode,
      deviceProfile: deviceProfile,
      child: MaterialApp.router(
        title: 'TiviPlayer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        routerConfig: ref.watch(appRouterProvider),
      ),
    );
  }
}
