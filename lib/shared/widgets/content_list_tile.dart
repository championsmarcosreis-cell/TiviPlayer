import 'package:flutter/material.dart';

import '../../core/tv/tv_focusable.dart';
import 'branded_artwork.dart';

class ContentListTile extends StatelessWidget {
  const ContentListTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
    this.subtitle,
    this.autofocus = false,
    this.testId,
    this.interactiveKey,
    this.imageUrl,
    this.thumbnailAspectRatio = 2 / 3,
    this.thumbnailWidth = 74,
    this.thumbnailFit = BoxFit.cover,
    this.thumbnailLabel,
    this.imagePadding = EdgeInsets.zero,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final bool autofocus;
  final String? testId;
  final Key? interactiveKey;
  final String? imageUrl;
  final double thumbnailAspectRatio;
  final double thumbnailWidth;
  final BoxFit thumbnailFit;
  final String? thumbnailLabel;
  final EdgeInsets imagePadding;

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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: focused
                ? colorScheme.primary.withValues(alpha: 0.12)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: focused
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.7),
              width: focused ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null || thumbnailLabel != null)
                SizedBox(
                  width: thumbnailWidth,
                  child: BrandedArtwork(
                    imageUrl: imageUrl,
                    aspectRatio: thumbnailAspectRatio,
                    fit: thumbnailFit,
                    imagePadding: imagePadding,
                    borderRadius: 18,
                    icon: icon,
                    placeholderLabel: thumbnailLabel,
                  ),
                )
              else
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colorScheme.secondary),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: focused ? colorScheme.primary : colorScheme.onSurface,
              ),
            ],
          ),
        );
      },
    );
  }
}
