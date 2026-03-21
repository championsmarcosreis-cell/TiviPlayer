import 'package:flutter/material.dart';

import '../../../../core/tv/tv_focusable.dart';

class PlayerControlButton extends StatelessWidget {
  const PlayerControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusable(
      autofocus: autofocus,
      onPressed: onPressed,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: focused
                ? colorScheme.primary.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: focused
                  ? colorScheme.primary
                  : Colors.white.withValues(alpha: 0.18),
              width: focused ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}
