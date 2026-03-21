import 'package:flutter/material.dart';

import '../../core/tv/tv_focusable.dart';
import '../presentation/layout/device_layout.dart';
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
    final layout = DeviceLayout.of(context);

    return TvFocusable(
      autofocus: autofocus,
      interactiveKey: interactiveKey,
      onPressed: onPressed,
      testId: testId,
      builder: (context, focused) {
        final hasArtwork = imageUrl != null || thumbnailLabel != null;
        final baseThumbnailWidth = hasArtwork ? thumbnailWidth : 44.0;
        final resolvedThumbnailWidth = layout.isTv
            ? baseThumbnailWidth + 18
            : baseThumbnailWidth;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.symmetric(
            horizontal: layout.isTv ? 22 : 18,
            vertical: layout.isTv ? 18 : 14,
          ),
          decoration: BoxDecoration(
            color: focused
                ? colorScheme.primary.withValues(alpha: 0.12)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(layout.isTv ? 24 : 22),
            border: Border.all(
              color: focused
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.7),
              width: focused ? 2 : 1,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: layout.listTileMinHeight),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasArtwork)
                  SizedBox(
                    width: resolvedThumbnailWidth,
                    child: BrandedArtwork(
                      imageUrl: imageUrl,
                      aspectRatio: thumbnailAspectRatio,
                      fit: thumbnailFit,
                      imagePadding: imagePadding,
                      borderRadius: layout.isTv ? 20 : 18,
                      icon: icon,
                      placeholderLabel: thumbnailLabel,
                    ),
                  )
                else
                  Container(
                    height: layout.isTv ? 54 : 44,
                    width: layout.isTv ? 54 : 44,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(
                        layout.isTv ? 16 : 14,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: colorScheme.secondary,
                      size: layout.isTv ? 30 : 24,
                    ),
                  ),
                SizedBox(width: layout.isTv ? 18 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: layout.isTv ? 23 : 18,
                              fontWeight: FontWeight.w700,
                              height: 1.18,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          maxLines: layout.isTv ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: layout.isTv ? 15 : 13,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.78,
                                ),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: layout.isTv ? 14 : 10),
                Icon(
                  Icons.chevron_right_rounded,
                  size: layout.isTv ? 30 : 24,
                  color: focused ? colorScheme.primary : colorScheme.onSurface,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
