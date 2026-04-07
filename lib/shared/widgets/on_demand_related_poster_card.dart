import 'package:flutter/material.dart';

import '../../core/tv/tv_focusable.dart';
import '../presentation/layout/device_layout.dart';
import 'branded_artwork.dart';

class OnDemandRelatedPosterCard extends StatelessWidget {
  const OnDemandRelatedPosterCard({
    super.key,
    required this.layout,
    required this.title,
    required this.imageUrl,
    required this.icon,
    required this.placeholderLabel,
    required this.onPressed,
    this.subtitle,
    this.badge,
    this.autofocus = false,
  });

  final DeviceLayout layout;
  final String title;
  final String? imageUrl;
  final IconData icon;
  final String placeholderLabel;
  final VoidCallback onPressed;
  final String? subtitle;
  final String? badge;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final posterRadius = layout.isTv ? 18.0 : 18.0;
    final normalizedSubtitle = _normalizeText(subtitle);
    final normalizedBadge = _normalizeText(badge);

    return TvFocusable(
      autofocus: autofocus,
      onPressed: onPressed,
      builder: (context, focused) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(posterRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: focused ? 0.24 : 0.18,
                    ),
                    blurRadius: focused ? 22 : 14,
                    offset: const Offset(0, 10),
                  ),
                  if (focused)
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.22),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  BrandedArtwork(
                    imageUrl: imageUrl,
                    aspectRatio: 2 / 3,
                    borderRadius: posterRadius,
                    placeholderLabel: placeholderLabel,
                    icon: icon,
                    chrome: BrandedArtworkChrome.subtle,
                  ),
                  if (normalizedBadge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _RelatedPosterBadge(label: normalizedBadge),
                    ),
                  if (focused)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(posterRadius),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.9),
                              width: layout.isTv ? 2.2 : 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: layout.isTv ? 12 : 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.14,
                fontSize: layout.isTv ? 15.5 : null,
              ),
            ),
            if (normalizedSubtitle != null) ...[
              SizedBox(height: layout.isTv ? 6 : 5),
              Text(
                normalizedSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w600,
                  fontSize: layout.isTv ? 12.5 : null,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RelatedPosterBadge extends StatelessWidget {
  const _RelatedPosterBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          letterSpacing: 0.45,
          fontWeight: FontWeight.w700,
          fontSize: 9.5,
        ),
      ),
    );
  }
}

String? _normalizeText(String? value) {
  final normalized = value?.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}
