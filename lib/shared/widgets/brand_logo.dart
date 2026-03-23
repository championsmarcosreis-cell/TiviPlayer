import 'package:flutter/material.dart';

import '../branding/brand_assets.dart';

enum BrandLogoVariant { lockup, icon }

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.variant = BrandLogoVariant.lockup,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final BrandLogoVariant variant;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      switch (variant) {
        BrandLogoVariant.lockup => BrandAssets.lockup,
        BrandLogoVariant.icon => BrandAssets.icon,
      },
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.height = 48,
    this.showTagline = false,
    this.compact = false,
    this.textColor,
  });

  final double height;
  final bool showTagline;
  final bool compact;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final resolvedTextColor = textColor ?? Colors.white;
    final iconSize = compact ? height * 0.82 : height;
    final titleSize = compact ? height * 0.47 : height * 0.44;
    final subtitleSize = compact ? height * 0.2 : height * 0.24;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(
          variant: BrandLogoVariant.icon,
          width: iconSize,
          height: iconSize,
        ),
        SizedBox(width: compact ? 10 : 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              BrandAssets.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: resolvedTextColor,
                fontSize: titleSize,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w800,
                height: 0.98,
              ),
            ),
            if (showTagline)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Streaming TV-first',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: resolvedTextColor.withValues(alpha: 0.72),
                    letterSpacing: 0.8,
                    fontSize: subtitleSize,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
