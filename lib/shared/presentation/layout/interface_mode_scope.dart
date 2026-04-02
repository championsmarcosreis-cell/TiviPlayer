import 'package:flutter/widgets.dart';

import 'device_interaction_profile.dart';

enum InterfaceMode { auto, mobile, tv }

class InterfaceModeScope extends InheritedWidget {
  const InterfaceModeScope({
    super.key,
    required this.mode,
    this.deviceProfile,
    required super.child,
  });

  final InterfaceMode mode;
  final DeviceInteractionProfile? deviceProfile;

  static InterfaceMode maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<InterfaceModeScope>();
    return scope?.mode ?? InterfaceMode.auto;
  }

  static DeviceInteractionProfile? maybeDeviceProfileOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<InterfaceModeScope>();
    return scope?.deviceProfile;
  }

  @override
  bool updateShouldNotify(covariant InterfaceModeScope oldWidget) {
    return oldWidget.mode != mode || oldWidget.deviceProfile != deviceProfile;
  }
}
