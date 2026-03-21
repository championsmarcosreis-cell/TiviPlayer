import 'package:flutter/material.dart';

import 'brand_logo.dart';

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
  });

  final String? imageUrl;
  final double aspectRatio;
  final BoxFit fit;
  final EdgeInsets imagePadding;
  final double borderRadius;
  final IconData icon;
  final String? placeholderLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedUrl = normalizeArtworkUrl(imageUrl);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.45),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: normalizedUrl == null
              ? _ArtworkFallback(icon: icon, label: placeholderLabel)
              : Image.network(
                  normalizedUrl,
                  fit: fit,
                  filterQuality: FilterQuality.medium,
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
            constraints.maxWidth < 84 || constraints.maxHeight < 110;
        final logoSize = compact ? 28.0 : 46.0;
        final contentPadding = compact ? 10.0 : 16.0;

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BrandLogo(
                      variant: BrandLogoVariant.icon,
                      width: logoSize,
                      height: logoSize,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 12),
                      Text(
                        label ?? 'Imagem indisponível',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (loading) ...[
                      SizedBox(height: compact ? 8 : 14),
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
            ],
          ),
        );
      },
    );
  }
}
