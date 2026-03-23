import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/layout/device_layout.dart';
import '../../core/tv/tv_focusable.dart';
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
    this.decoratedHeader = true,
    this.showBrand = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final bool decoratedHeader;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF03060D), Color(0xFF0A1321), Color(0xFF060B13)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -210,
              right: -180,
              child: _GlowOrb(
                size: 460,
                colors: const [Color(0x26FF6A1A), Color(0x00FF6A1A)],
              ),
            ),
            Positioned(
              bottom: -260,
              left: -150,
              child: _GlowOrb(
                size: 520,
                colors: const [Color(0x1E16C7FF), Color(0x00E33DFF)],
              ),
            ),
            const Positioned.fill(child: _ScaffoldTexture()),
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
                          decoratedHeader: decoratedHeader,
                          showBrand: showBrand,
                        ),
                        SizedBox(height: layout.sectionSpacing + 4),
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
    required this.decoratedHeader,
    required this.showBrand,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final DeviceLayout layout;
  final bool decoratedHeader;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = layout.isTv || layout.width >= 940;
    final onBackPressed =
        onBack ??
        () {
          if (context.canPop()) {
            context.pop();
          }
        };

    final titleContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBrand) ...[
          BrandWordmark(
            height: layout.isTv ? 38 : 34,
            compact: !layout.isTv,
            showTagline: false,
          ),
          SizedBox(height: layout.isTv ? 10 : 10),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBack)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _HeaderBackButton(
                  layout: layout,
                  onPressed: onBackPressed,
                ),
              ),
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
                              height: 1.02,
                            ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: layout.isTv ? 8 : 6),
                    Text(
                      subtitle!,
                      maxLines: layout.isMobilePortrait ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.82),
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
      ],
    );

    final titleBlock = decoratedHeader
        ? Container(
            padding: EdgeInsets.symmetric(
              horizontal: layout.isTv ? 18 : 14,
              vertical: layout.isTv ? 14 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(layout.isTv ? 22 : 18),
              color: colorScheme.surface.withValues(alpha: 0.68),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.38),
              ),
            ),
            child: titleContent,
          )
        : Padding(
            padding: EdgeInsets.symmetric(
              horizontal: layout.isTv ? 4 : 0,
              vertical: layout.isTv ? 4 : 0,
            ),
            child: titleContent,
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

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.layout, required this.onPressed});

  final DeviceLayout layout;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!layout.isTv) {
      return IconButton.filledTonal(
        onPressed: onPressed,
        padding: EdgeInsets.all(layout.isTv ? 15 : 11),
        icon: const Icon(Icons.arrow_back_rounded),
      );
    }

    return SizedBox(
      width: 74,
      height: 74,
      child: TvFocusable(
        autofocus: false,
        onPressed: onPressed,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: focused
                  ? const Color(0xFFFFF3E7)
                  : colorScheme.primary.withValues(alpha: 0.2),
              border: Border.all(
                color: focused
                    ? colorScheme.secondary
                    : colorScheme.primary.withValues(alpha: 0.55),
                width: focused ? 3 : 1.4,
              ),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: colorScheme.secondary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 36,
              color: focused ? const Color(0xFF161005) : colorScheme.primary,
            ),
          );
        },
      ),
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

class _ScaffoldTexture extends StatelessWidget {
  const _ScaffoldTexture();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.22,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.02),
                Colors.transparent,
                Colors.white.withValues(alpha: 0.015),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
          child: CustomPaint(painter: _TexturePainter()),
        ),
      ),
    );
  }
}

class _TexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    for (var index = 0; index < 18; index++) {
      final y = (size.height / 18) * index;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 22), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
