import 'package:flutter/widgets.dart';

enum InterfaceMode { auto, mobile, tv }

class InterfaceModeScope extends InheritedWidget {
  const InterfaceModeScope({
    super.key,
    required this.mode,
    required super.child,
  });

  final InterfaceMode mode;

  static InterfaceMode maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<InterfaceModeScope>();
    return scope?.mode ?? InterfaceMode.auto;
  }

  @override
  bool updateShouldNotify(covariant InterfaceModeScope oldWidget) {
    return oldWidget.mode != mode;
  }
}
