import 'package:flutter/material.dart';

import '../presentation/layout/device_layout.dart';
import '../../core/tv/tv_focusable.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onPressed,
    this.autofocus = false,
    this.testId,
    this.interactiveKey,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onPressed;
  final bool autofocus;
  final String? testId;
  final Key? interactiveKey;

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
        final containerPadding = layout.cardPadding;
        final iconSize = layout.isTv ? 56.0 : 50.0;
        final titleStyle = layout.isTv
            ? Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: layout.isTv ? 28 : 24)
            : Theme.of(context).textTheme.titleLarge;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: focused
                  ? [
                      colorScheme.primary.withValues(alpha: 0.22),
                      colorScheme.surface.withValues(alpha: 0.98),
                    ]
                  : [
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.85,
                      ),
                      colorScheme.surface.withValues(alpha: 0.98),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(layout.cardBorderRadius),
            border: Border.all(
              color: focused
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.7),
              width: focused ? 2.2 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : const [],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: layout.isTv ? 210 : 182),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      height: iconSize,
                      width: iconSize,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(
                          layout.isTv ? 18 : 16,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: colorScheme.secondary,
                        size: layout.isTv ? 30 : 26,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: focused
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.72),
                      size: layout.isTv ? 30 : 26,
                    ),
                  ],
                ),
                SizedBox(height: layout.isTv ? 30 : 24),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                SizedBox(height: layout.isTv ? 12 : 10),
                Text(
                  description,
                  maxLines: layout.isTv ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
