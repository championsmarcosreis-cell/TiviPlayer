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
