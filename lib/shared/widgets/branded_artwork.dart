import 'package:flutter/material.dart';

import 'brand_logo.dart';

enum BrandedArtworkChrome { framed, subtle }

class BrandedArtwork extends StatelessWidget {
  const BrandedArtwork({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 2 / 3,
    this.fit = BoxFit.cover,
    this.imagePadding = EdgeInsets.zero,
    this.borderRadius = 22,
    this.icon = Icons.movie_rounded,
    this.placeholderLabel,
    this.chrome = BrandedArtworkChrome.framed,
  });

  final String? imageUrl;
  final double aspectRatio;
  final BoxFit fit;
  final EdgeInsets imagePadding;
  final double borderRadius;
  final IconData icon;
  final String? placeholderLabel;
  final BrandedArtworkChrome chrome;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedUrl = normalizeArtworkUrl(imageUrl);
    final radius = BorderRadius.circular(borderRadius);
    final decoration = switch (chrome) {
      BrandedArtworkChrome.framed => BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.45),
          width: 1.2,
        ),
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
            colorScheme.surface.withValues(alpha: 0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      BrandedArtworkChrome.subtle => BoxDecoration(
        borderRadius: radius,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
      ),
    };

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: decoration,
        child: ClipRRect(
          borderRadius: radius,
          child: normalizedUrl == null
              ? _ArtworkFallback(icon: icon, label: placeholderLabel)
              : Image.network(
                  normalizedUrl,
                  fit: fit,
                  headers: const {'Accept-Encoding': 'identity'},
                  filterQuality: FilterQuality.medium,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          return Padding(padding: imagePadding, child: child);
                        }
                        return _ArtworkFallback(
                          icon: icon,
                          label: placeholderLabel,
                          loading: true,
                        );
                      },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return Padding(padding: imagePadding, child: child);
                    }

                    return _ArtworkFallback(
                      icon: icon,
                      label: placeholderLabel,
                      loading: true,
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _ArtworkFallback(
                      icon: icon,
                      label: placeholderLabel,
                    );
                  },
                ),
        ),
      ),
    );
  }

  static String? normalizeArtworkUrl(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null ||
        trimmed.isEmpty ||
        trimmed == 'null' ||
        trimmed == 'N/A') {
      return null;
    }

    final encoded = Uri.encodeFull(trimmed);
    final uri = Uri.tryParse(encoded);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.host.isEmpty && uri.path.isEmpty)) {
      return null;
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }

    return uri.toString();
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback({
    required this.icon,
    required this.label,
    this.loading = false,
  });

  final IconData icon;
  final String? label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 92 || constraints.maxHeight < 124;
        final showLabel = !compact;
        final logoSize = compact ? 28.0 : 46.0;
        final contentPadding = compact ? 10.0 : 16.0;
        final labelSpacing = compact ? 8.0 : 12.0;
        final loadingSpacing = compact ? 8.0 : 14.0;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.18),
                colorScheme.tertiary.withValues(alpha: 0.12),
                colorScheme.surface.withValues(alpha: 0.98),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: compact ? -12 : -26,
                right: compact ? -8 : -10,
                child: Icon(
                  icon,
                  size: compact ? 54 : 92,
                  color: colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: compact ? 80 : 150),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BrandLogo(
                            variant: BrandLogoVariant.icon,
                            width: logoSize,
                            height: logoSize,
                          ),
                          if (showLabel) ...[
                            SizedBox(height: labelSpacing),
                            Text(
                              label ?? 'Imagem indisponível',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.72,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                          if (loading) ...[
                            SizedBox(height: loadingSpacing),
                            SizedBox(
                              width: compact ? 18 : 24,
                              height: compact ? 18 : 24,
                              child: CircularProgressIndicator(
                                strokeWidth: compact ? 2 : 2.4,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
