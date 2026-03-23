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
    this.overline,
    this.metadata = const <String>[],
    this.badge,
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
  final String? overline;
  final List<String> metadata;
  final String? badge;
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
        final baseThumbnailWidth = hasArtwork ? thumbnailWidth : 54.0;
        final resolvedThumbnailWidth = layout.isTv
            ? baseThumbnailWidth + 18
            : baseThumbnailWidth;
        final normalizedMetadata = metadata
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .take(layout.isTv ? 4 : 3)
            .toList();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.symmetric(
            horizontal: layout.isTv ? 20 : 16,
            vertical: layout.isTv ? 16 : 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: focused
                  ? [
                      colorScheme.primary.withValues(alpha: 0.22),
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.9,
                      ),
                    ]
                  : [
                      colorScheme.surface.withValues(alpha: 0.92),
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.72,
                      ),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(layout.isTv ? 24 : 20),
            border: Border.all(
              color: focused
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.64),
              width: focused ? 2 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: layout.listTileMinHeight + (layout.isTv ? 8 : 0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                    height: layout.isTv ? 62 : 50,
                    width: layout.isTv ? 62 : 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.secondary.withValues(alpha: 0.24),
                          colorScheme.primary.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        layout.isTv ? 18 : 16,
                      ),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.46),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: colorScheme.onSurface,
                      size: layout.isTv ? 30 : 24,
                    ),
                  ),
                SizedBox(width: layout.isTv ? 18 : 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (overline != null && overline!.trim().isNotEmpty) ...[
                        Text(
                          overline!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                letterSpacing: 1.1,
                                color: colorScheme.secondary.withValues(
                                  alpha: 0.92,
                                ),
                                fontWeight: FontWeight.w700,
                                fontSize: layout.isTv ? 13 : 11,
                              ),
                        ),
                        SizedBox(height: layout.isTv ? 8 : 6),
                      ],
                      Text(
                        title,
                        maxLines: layout.isTv ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: layout.isTv ? 25 : 18,
                              fontWeight: FontWeight.w700,
                              height: 1.12,
                            ),
                      ),
                      if (normalizedMetadata.isNotEmpty) ...[
                        SizedBox(height: layout.isTv ? 8 : 7),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            for (final value in normalizedMetadata)
                              _MetadataPill(value: value, layout: layout),
                          ],
                        ),
                      ],
                      if (subtitle != null) ...[
                        SizedBox(height: layout.isTv ? 9 : 8),
                        Text(
                          subtitle!,
                          maxLines: layout.isTv ? 2 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: layout.isTv ? 14 : 12.5,
                                height: 1.38,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: layout.isTv ? 16 : 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (badge != null && badge!.trim().isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: layout.isTv ? 10 : 8,
                          vertical: layout.isTv ? 5 : 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: colorScheme.secondary.withValues(alpha: 0.18),
                          border: Border.all(
                            color: colorScheme.secondary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          badge!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                        ),
                      ),
                    SizedBox(height: layout.isTv ? 10 : 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: layout.isTv ? 20 : 16,
                      color: focused
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.74),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({required this.value, required this.layout});

  final String value;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.isTv ? 9 : 8,
        vertical: layout.isTv ? 4.5 : 3.5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.38)),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: layout.isTv ? 11.5 : 10.5,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface.withValues(alpha: 0.88),
        ),
      ),
    );
  }
}
