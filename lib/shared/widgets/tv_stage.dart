import 'package:flutter/material.dart';

import '../presentation/layout/device_layout.dart';

class TvStageScaffold extends StatelessWidget {
  const TvStageScaffold({
    super.key,
    required this.child,
    this.padding,
    this.backdrop = const TvStageBackdrop(),
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final TvStageBackdrop backdrop;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);
    final resolvedPadding =
        padding ??
        EdgeInsets.fromLTRB(
          layout.isTvCompact ? 26 : 38,
          layout.isTvCompact ? 18 : 24,
          layout.isTvCompact ? 26 : 38,
          layout.isTvCompact ? 18 : 24,
        );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: backdrop.gradientColors,
              ),
            ),
          ),
          Positioned(
            top: -210,
            left: -170,
            child: _GlowOrb(size: 620, color: backdrop.topGlowColor),
          ),
          Positioned(
            right: -180,
            bottom: -220,
            child: _GlowOrb(size: 520, color: backdrop.bottomGlowColor),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.26),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(padding: resolvedPadding, child: child),
          ),
        ],
      ),
    );
  }
}

class TvStageBackdrop {
  const TvStageBackdrop({
    this.gradientColors = const [
      Color(0xFF050B15),
      Color(0xFF0A1627),
      Color(0xFF060C16),
    ],
    this.topGlowColor = const Color(0x332B4F80),
    this.bottomGlowColor = const Color(0x1F163C67),
  });

  final List<Color> gradientColors;
  final Color topGlowColor;
  final Color bottomGlowColor;
}

class TvStagePanel extends StatelessWidget {
  const TvStagePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.emphasized = false,
    this.borderColor,
    this.gradientColors,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool emphasized;
  final Color? borderColor;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topColor = emphasized
        ? const Color(0xD61A2A41)
        : colorScheme.surface.withValues(alpha: 0.72);
    final bottomColor = emphasized
        ? const Color(0xC0111D30)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.58);
    final resolvedGradientColors = gradientColors ?? [topColor, bottomColor];

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: resolvedGradientColors,
        ),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: child,
    );
  }
}

class TvStageClock extends StatelessWidget {
  const TvStageClock({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      initialData: DateTime.now(),
      stream: Stream<DateTime>.periodic(
        const Duration(seconds: 15),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final dateText =
            '${_weekdayShort[now.weekday - 1]} ${now.day} ${_monthShort[now.month - 1]}';
        final timeText =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              dateText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.76),
                letterSpacing: 0.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeText,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

const _weekdayShort = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
const _monthShort = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];
