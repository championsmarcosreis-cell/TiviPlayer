import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                  final isWide = constraints.maxWidth >= 900;
                  final horizontalPadding = isWide ? 40.0 : 20.0;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24,
                      horizontalPadding,
                      24,
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
                          isWide: isWide,
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isWide ? 1240 : double.infinity,
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
    required this.isWide,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final backButton = showBack
        ? Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              onPressed:
                  onBack ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                    }
                  },
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
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.55),
                  ),
                ),
                child: const BrandLogo(
                  variant: BrandLogoVariant.icon,
                  width: 30,
                  height: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyLarge,
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
          const SizedBox(height: 16),
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
