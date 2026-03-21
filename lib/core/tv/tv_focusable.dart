import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvFocusable extends StatefulWidget {
  const TvFocusable({
    super.key,
    required this.builder,
    this.onPressed,
    this.autofocus = false,
    this.focusNode,
    this.testId,
    this.interactiveKey,
  });

  final Widget Function(BuildContext context, bool focused) builder;
  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? testId;
  final Key? interactiveKey;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool _focused = false;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode(debugLabel: widget.testId);
    }
    _scheduleAutofocusIfNeeded();
  }

  @override
  void didUpdateWidget(covariant TvFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) {
        _internalFocusNode?.dispose();
      }
      _internalFocusNode = widget.focusNode == null
          ? FocusNode(debugLabel: widget.testId)
          : null;
    }

    if (widget.autofocus && !oldWidget.autofocus) {
      _scheduleAutofocusIfNeeded();
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _scheduleAutofocusIfNeeded() {
    if (!widget.autofocus) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _effectiveFocusNode.hasFocus) {
        return;
      }
      FocusScope.of(context).requestFocus(_effectiveFocusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final usesDirectionalNavigation =
        MediaQuery.navigationModeOf(context) == NavigationMode.directional;
    final focusedScale = usesDirectionalNavigation ? 1.028 : 1.01;

    return FocusableActionDetector(
      autofocus: widget.autofocus,
      focusNode: _effectiveFocusNode,
      enabled: widget.onPressed != null,
      mouseCursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onFocusChange: (focused) {
        if (_focused != focused) {
          setState(() {
            _focused = focused;
          });
        }
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: Stack(
        children: [
          GestureDetector(
            key: widget.interactiveKey,
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 140),
              scale: _focused ? focusedScale : 1,
              child: widget.builder(context, _focused),
            ),
          ),
          if (_focused && widget.testId != null)
            Positioned(
              top: 0,
              right: 0,
              child: SizedBox(
                key: ValueKey<String>('focus.${widget.testId!}'),
                width: 1,
                height: 1,
              ),
            ),
        ],
      ),
    );
  }
}
