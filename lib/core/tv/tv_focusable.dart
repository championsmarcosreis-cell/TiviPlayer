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
    this.onFocusChanged,
    this.onKeyEvent,
  });

  final Widget Function(BuildContext context, bool focused) builder;
  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? testId;
  final Key? interactiveKey;
  final ValueChanged<bool>? onFocusChanged;
  final FocusOnKeyEventCallback? onKeyEvent;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  static final Set<LogicalKeyboardKey> _activationKeys = {
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.gameButtonA,
  };
  static const _activationCooldown = Duration(milliseconds: 450);

  bool _focused = false;
  FocusNode? _internalFocusNode;
  DateTime? _lastActivationAt;

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

  void _ensureVisibleIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_effectiveFocusNode.hasFocus) {
        return;
      }
      if (MediaQuery.maybeNavigationModeOf(context) !=
          NavigationMode.directional) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final usesDirectionalNavigation =
        MediaQuery.navigationModeOf(context) == NavigationMode.directional;
    final focusedScale = usesDirectionalNavigation ? 1.014 : 1.008;

    return Focus(
      autofocus: widget.autofocus,
      focusNode: _effectiveFocusNode,
      canRequestFocus: widget.onPressed != null,
      onFocusChange: (focused) {
        if (_focused != focused) {
          setState(() {
            _focused = focused;
          });
        }
        if (focused) {
          _ensureVisibleIfNeeded();
        }
        widget.onFocusChanged?.call(focused);
      },
      onKeyEvent: (node, event) {
        final customResult = widget.onKeyEvent?.call(node, event);
        if (customResult == KeyEventResult.handled ||
            customResult == KeyEventResult.skipRemainingHandlers) {
          return customResult!;
        }

        if (event is KeyDownEvent &&
            widget.onPressed != null &&
            _activationKeys.contains(event.logicalKey)) {
          _activate();
          return KeyEventResult.handled;
        }

        return customResult ?? KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: widget.onPressed != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: _buildFocusableChild(context, focusedScale),
      ),
    );
  }

  Widget _buildFocusableChild(BuildContext context, double focusedScale) {
    return Stack(
      children: [
        GestureDetector(
          key: widget.interactiveKey,
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed == null ? null : _activate,
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
    );
  }

  void _activate() {
    final onPressed = widget.onPressed;
    if (onPressed == null) {
      return;
    }

    final now = DateTime.now();
    final lastActivationAt = _lastActivationAt;
    if (lastActivationAt != null &&
        now.difference(lastActivationAt) < _activationCooldown) {
      return;
    }

    _lastActivationAt = now;
    onPressed();
  }
}
