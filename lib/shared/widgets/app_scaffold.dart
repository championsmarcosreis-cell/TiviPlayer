import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/layout/device_layout.dart';
import 'brand_logo.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.showBack = false,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF05080D), Color(0xFF0A1120), Color(0xFF05080D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -140,
              right: -120,
              child: _GlowOrb(
                size: 320,
                colors: const [Color(0x33FF6A1A), Color(0x00FF6A1A)],
              ),
            ),
            Positioned(
              bottom: -180,
              left: -120,
              child: _GlowOrb(
                size: 360,
                colors: const [Color(0x3316C7FF), Color(0x00E33DFF)],
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layout = DeviceLayout.of(
                    context,
                    constraints: constraints,
                  );
                  final horizontalPadding = layout.pageHorizontalPadding;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      layout.pageTopPadding,
                      horizontalPadding,
                      layout.pageBottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AppScaffoldHeader(
                          title: title,
                          subtitle: subtitle,
                          actions: actions,
                          showBack: showBack,
                          onBack: onBack,
                          layout: layout,
                        ),
                        SizedBox(height: layout.sectionSpacing + 6),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: layout.maxContentWidth,
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppScaffoldHeader extends StatelessWidget {
  const _AppScaffoldHeader({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.showBack,
    required this.onBack,
    required this.layout,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconSize = layout.headerIconContainer;
    final isWide = layout.isTv || layout.width >= 940;

    final backButton = showBack
        ? Padding(
            padding: EdgeInsets.only(
              right: layout.isMobilePortrait ? 8 : 12,
              top: 2,
            ),
            child: IconButton.filledTonal(
              onPressed:
                  onBack ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                    }
                  },
              padding: EdgeInsets.all(layout.isTv ? 16 : 12),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          )
        : const SizedBox.shrink();

    final titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        backButton,
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                padding: EdgeInsets.all(layout.isTv ? 10 : 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.82,
                  ),
                  borderRadius: BorderRadius.circular(layout.isTv ? 20 : 16),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.55),
                  ),
                ),
                child: const BrandLogo(
                  variant: BrandLogoVariant.icon,
                  width: 32,
                  height: 32,
                ),
              ),
              SizedBox(width: layout.isMobilePortrait ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (layout.isMobilePortrait
                                  ? Theme.of(context).textTheme.headlineMedium
                                  : Theme.of(context).textTheme.headlineLarge)
                              ?.copyWith(
                                fontSize: switch (layout.deviceClass) {
                                  DeviceClass.mobilePortrait => 30,
                                  DeviceClass.mobileLandscape => 34,
                                  DeviceClass.tablet => 36,
                                  DeviceClass.tvCompact => 40,
                                  DeviceClass.tvLarge => 44,
                                },
                                height: 1.05,
                              ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: layout.isTv ? 8 : 6),
                      Text(
                        subtitle!,
                        maxLines: layout.isMobilePortrait ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.84),
                          fontSize: switch (layout.deviceClass) {
                            DeviceClass.mobilePortrait => 14,
                            DeviceClass.mobileLandscape => 15,
                            DeviceClass.tablet => 16,
                            DeviceClass.tvCompact => 18,
                            DeviceClass.tvLarge => 19,
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (actions.isEmpty) {
      return titleBlock;
    }

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          SizedBox(height: layout.sectionSpacing),
          Wrap(spacing: 12, runSpacing: 12, children: actions),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.end,
          children: actions,
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}
