import 'package:flutter/material.dart';

import '../presentation/layout/device_layout.dart';
import 'brand_logo.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.isTv ? 560 : 420),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(layout.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: layout.isTv ? 92 : 78,
                      height: layout.isTv ? 92 : 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    const BrandLogo(
                      variant: BrandLogoVariant.icon,
                      width: 42,
                      height: 42,
                    ),
                    Positioned(
                      right: 4,
                      bottom: 2,
                      child: Icon(icon, size: layout.isTv ? 30 : 26),
                    ),
                  ],
                ),
                SizedBox(height: layout.sectionSpacing + 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: layout.isTv ? 30 : 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: layout.isTv ? 12 : 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: layout.isTv ? 16 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
