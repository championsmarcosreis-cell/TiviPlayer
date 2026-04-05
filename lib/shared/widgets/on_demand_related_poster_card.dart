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
    final posterRadius = layout.isTv ? 16.0 : 18.0;
    final focusBorderColor = colorScheme.primary.withValues(
      alpha: layout.isTv ? 0.42 : 0.34,
    );
    final normalizedSubtitle = _normalizeText(subtitle);
    final normalizedBadge = _normalizeText(badge);

    return TvFocusable(
      autofocus: autofocus,
      onPressed: onPressed,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.all(layout.isTv ? 6 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.isTv ? 22 : 18),
            color: focused && layout.isTv
                ? colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(
              color: focused && layout.isTv
                  ? focusBorderColor
                  : Colors.transparent,
              width: layout.isTv ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(posterRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: layout.isTv ? 14 : 16,
                      offset: Offset(0, layout.isTv ? 7 : 8),
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
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(posterRadius),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.82),
                            ],
                            stops: const [0.44, 0.68, 1],
                          ),
                        ),
                      ),
                    ),
                    if (normalizedBadge != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _RelatedPosterBadge(label: normalizedBadge),
                      ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.08,
                        ),
                      ),
                    ),
                    if (focused)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(posterRadius),
                              border: Border.all(
                                color: focusBorderColor,
                                width: layout.isTv ? 1.8 : 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (normalizedSubtitle != null) ...[
                SizedBox(height: layout.isTv ? 10 : 8),
                Text(
                  normalizedSubtitle,
                  maxLines: layout.isTv ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                    fontSize: layout.isTv ? 12.5 : 11.5,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
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
    final isHighlight = label.startsWith('★');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight
            ? const Color(0xCCFF8A3D)
            : Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w800,
          fontSize: 10,
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
