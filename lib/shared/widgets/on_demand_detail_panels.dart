import 'package:flutter/material.dart';

import '../../core/tv/tv_focusable.dart';
import '../presentation/layout/device_layout.dart';

class OnDemandDetailSection extends StatelessWidget {
  const OnDemandDetailSection({
    super.key,
    required this.layout,
    required this.title,
    required this.child,
    this.subtitle,
    this.eyebrow,
    this.trailing,
    this.topDivider = true,
    this.spacing,
  });

  final DeviceLayout layout;
  final String title;
  final Widget child;
  final String? subtitle;
  final String? eyebrow;
  final Widget? trailing;
  final bool topDivider;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topDivider) ...[
          Divider(color: dividerColor, height: 1),
          SizedBox(height: layout.sectionSpacing + 6),
        ],
        OnDemandDetailSectionHeader(
          title: title,
          subtitle: subtitle,
          eyebrow: eyebrow,
          trailing: trailing,
        ),
        SizedBox(height: spacing ?? layout.sectionSpacing),
        child,
      ],
    );
  }
}

class OnDemandDetailSectionHeader extends StatelessWidget {
  const OnDemandDetailSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final layout = DeviceLayout.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_normalizeText(eyebrow) case final eyebrowText?) ...[
                Text(
                  eyebrowText,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.18,
                    color: colorScheme.secondary.withValues(alpha: 0.94),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: layout.isTv ? 8 : 6),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: layout.isTv ? 30 : 22,
                  fontWeight: FontWeight.w800,
                  height: 1.04,
                ),
              ),
              if (_normalizeText(subtitle) case final subtitleText?) ...[
                SizedBox(height: layout.isTv ? 8 : 6),
                Text(
                  subtitleText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: layout.cardSpacing),
          trailing!,
        ],
      ],
    );
  }
}

class OnDemandDetailTag extends StatelessWidget {
  const OnDemandDetailTag({
    super.key,
    required this.label,
    this.icon,
    this.emphasized = false,
  });

  final String label;
  final IconData? icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: emphasized
            ? colorScheme.primary.withValues(alpha: 0.16)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.26),
        border: Border.all(
          color: emphasized
              ? colorScheme.primary.withValues(alpha: 0.32)
              : colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: emphasized
                  ? colorScheme.primary
                  : colorScheme.secondary.withValues(alpha: 0.88),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: emphasized
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class OnDemandDetailFactData {
  const OnDemandDetailFactData({
    required this.label,
    required this.value,
    this.icon,
    this.helper,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? helper;
}

class OnDemandDetailFactsList extends StatelessWidget {
  const OnDemandDetailFactsList({
    super.key,
    required this.layout,
    required this.facts,
    this.maxColumns = 2,
  });

  final DeviceLayout layout;
  final List<OnDemandDetailFactData> facts;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = layout.columnsForWidth(
          constraints.maxWidth,
          minTileWidth: layout.isTv ? 260 : 180,
          maxColumns: maxColumns,
        );

        return Wrap(
          spacing: layout.cardSpacing + 6,
          runSpacing: layout.cardSpacing,
          children: [
            for (final fact in facts)
              SizedBox(
                width: layout.itemWidth(
                  constraints.maxWidth,
                  columns: columns,
                  spacing: layout.cardSpacing + 6,
                ),
                child: _OnDemandDetailFactLine(layout: layout, fact: fact),
              ),
          ],
        );
      },
    );
  }
}

class _OnDemandDetailFactLine extends StatelessWidget {
  const _OnDemandDetailFactLine({required this.layout, required this.fact});

  final DeviceLayout layout;
  final OnDemandDetailFactData fact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(bottom: layout.isTv ? 16 : 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.16),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fact.icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                fact.icon,
                size: layout.isTv ? 18 : 16,
                color: colorScheme.secondary.withValues(alpha: 0.9),
              ),
            ),
            SizedBox(width: layout.isTv ? 12 : 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fact.label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1,
                    color: colorScheme.onSurface.withValues(alpha: 0.54),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: layout.isTv ? 7 : 6),
                Text(
                  fact.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: layout.isTv ? 19 : 16,
                    fontWeight: FontWeight.w700,
                    height: 1.22,
                  ),
                ),
                if (_normalizeText(fact.helper) case final helperText?) ...[
                  SizedBox(height: layout.isTv ? 5 : 4),
                  Text(
                    helperText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.66),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnDemandTvPillButton extends StatelessWidget {
  const OnDemandTvPillButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.autofocus = false,
    this.onFocused,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final bool autofocus;
  final VoidCallback? onFocused;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusable(
      autofocus: autofocus,
      onPressed: onPressed,
      onFocusChanged: (focused) {
        if (focused) {
          onFocused?.call();
        }
      },
      builder: (context, focused) {
        final active = selected || focused;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: active
                ? colorScheme.primary.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.02),
            border: Border.all(
              color: active
                  ? colorScheme.primary.withValues(alpha: 0.7)
                  : colorScheme.outline.withValues(alpha: 0.18),
              width: active ? 1.4 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: active
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.84),
            ),
          ),
        );
      },
    );
  }
}

class OnDemandTvRailButton extends StatelessWidget {
  const OnDemandTvRailButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.subtitle,
    this.autofocus = false,
    this.focusNode,
    this.onFocused,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onPressed;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onFocused;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedSubtitle = _normalizeText(subtitle);

    return TvFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      onPressed: onPressed,
      onFocusChanged: (focused) {
        if (focused) {
          onFocused?.call();
        }
      },
      builder: (context, focused) {
        final active = selected || focused;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: focused
                ? colorScheme.primary.withValues(alpha: 0.06)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: active
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.14),
                width: focused
                    ? 3
                    : selected
                    ? 2
                    : 1,
              ),
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: active
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              if (normalizedSubtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  normalizedSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: active
                        ? colorScheme.onSurface.withValues(alpha: 0.72)
                        : colorScheme.onSurface.withValues(alpha: 0.62),
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

String? _normalizeText(String? value) {
  final normalized = value?.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}
