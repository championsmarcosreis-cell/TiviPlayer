import 'package:flutter/material.dart';

import '../../../../core/tv/tv_focusable.dart';
import '../../../../shared/presentation/layout/device_layout.dart';

enum PlayerControlButtonKind { primary, secondary, subtle }

class PlayerControlButton extends StatelessWidget {
  const PlayerControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
    this.testId,
    this.interactiveKey,
    this.kind = PlayerControlButtonKind.secondary,
    this.prominent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool autofocus;
  final String? testId;
  final Key? interactiveKey;
  final PlayerControlButtonKind kind;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final layout = DeviceLayout.of(context);

    return TvFocusable(
      autofocus: autofocus,
      interactiveKey: interactiveKey,
      onPressed: onPressed,
      testId: testId,
      builder: (context, focused) {
        final palette = switch (kind) {
          PlayerControlButtonKind.primary => (
            background: focused
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.88),
            iconColor: colorScheme.onPrimary,
            textColor: colorScheme.onPrimary,
            borderColor: focused
                ? colorScheme.secondary.withValues(alpha: 0.7)
                : colorScheme.primary.withValues(alpha: 0.95),
          ),
          PlayerControlButtonKind.secondary => (
            background: focused
                ? Colors.white.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.14),
            iconColor: Colors.white,
            textColor: Colors.white,
            borderColor: focused
                ? colorScheme.secondary.withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.22),
          ),
          PlayerControlButtonKind.subtle => (
            background: focused
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.08),
            iconColor: Colors.white.withValues(alpha: 0.9),
            textColor: Colors.white.withValues(alpha: 0.9),
            borderColor: focused
                ? colorScheme.secondary.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.16),
          ),
        };

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.symmetric(
            horizontal: prominent
                ? (layout.isTv ? 24 : 18)
                : (layout.isTv ? 20 : 14),
            vertical: prominent
                ? (layout.isTv ? 15 : 12)
                : (layout.isTv ? 13 : 10),
          ),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(
              prominent ? (layout.isTv ? 24 : 18) : (layout.isTv ? 22 : 16),
            ),
            border: Border.all(
              color: palette.borderColor,
              width: focused ? 2.2 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: kind == PlayerControlButtonKind.primary
                          ? colorScheme.primary.withValues(alpha: 0.36)
                          : Colors.black.withValues(alpha: 0.28),
                      blurRadius: prominent ? 18 : 12,
                      offset: Offset(0, prominent ? 7 : 5),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: palette.iconColor,
                size: prominent
                    ? (layout.isTv ? 30 : 24)
                    : (layout.isTv ? 27 : 21),
              ),
              SizedBox(width: layout.isTv ? 10 : 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: palette.textColor,
                  fontSize: prominent
                      ? (layout.isTv ? 20 : 16)
                      : (layout.isTv ? 18 : 14.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
