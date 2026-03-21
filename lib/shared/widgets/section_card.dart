import 'package:flutter/material.dart';

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

    return TvFocusable(
      autofocus: autofocus,
      interactiveKey: interactiveKey,
      onPressed: onPressed,
      testId: testId,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: focused
                ? colorScheme.primary.withValues(alpha: 0.14)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(26),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: colorScheme.secondary),
              ),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }
}
