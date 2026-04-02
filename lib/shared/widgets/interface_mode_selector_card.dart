import 'package:flutter/material.dart';

import '../presentation/layout/device_layout.dart';
import '../presentation/layout/interface_mode_scope.dart';

class InterfaceModeSelectorCard extends StatelessWidget {
  const InterfaceModeSelectorCard({
    super.key,
    required this.layout,
    required this.mode,
    required this.onChanged,
    this.compactForTv = false,
    this.eyebrow,
    this.title,
    this.description,
    this.helperText,
  });

  final DeviceLayout layout;
  final InterfaceMode mode;
  final ValueChanged<InterfaceMode> onChanged;
  final bool compactForTv;
  final String? eyebrow;
  final String? title;
  final String? description;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compactTv = layout.isTv && compactForTv;
    final resolvedDescription =
        layout.isTv
            ? (compactTv ? null : description)
            : description;
    final resolvedHelperText =
        layout.isTv
            ? (compactTv ? null : helperText)
            : helperText;

    final selector = Theme(
      data: Theme.of(context).copyWith(
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            minimumSize: WidgetStatePropertyAll<Size>(
              Size.fromHeight(layout.isTv ? (compactTv ? 44 : 52) : 52),
            ),
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return colorScheme.secondary.withValues(alpha: 0.16);
              }
              return const Color(0xFF111B2C);
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return colorScheme.onSurface;
              }
              return colorScheme.onSurface.withValues(alpha: 0.82);
            }),
            side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
              if (states.contains(WidgetState.selected)) {
                return BorderSide(
                  color: colorScheme.secondary.withValues(alpha: 0.62),
                  width: 1.2,
                );
              }
              return BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.34),
              );
            }),
            textStyle: WidgetStatePropertyAll<TextStyle?>(
              Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: layout.isTv ? (compactTv ? 14 : 16) : null,
              ),
            ),
          ),
        ),
      ),
      child: SegmentedButton<InterfaceMode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment<InterfaceMode>(
            value: InterfaceMode.auto,
            icon: Icon(Icons.tune_rounded),
            label: Text('Auto'),
          ),
          ButtonSegment<InterfaceMode>(
            value: InterfaceMode.mobile,
            icon: Icon(Icons.smartphone_rounded),
            label: Text('Mobile'),
          ),
          ButtonSegment<InterfaceMode>(
            value: InterfaceMode.tv,
            icon: Icon(Icons.tv_rounded),
            label: Text('TV'),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) {
            onChanged(selection.first);
          }
        },
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        layout.isTv ? (compactTv ? 18 : 22) : layout.cardPadding,
        layout.isTv ? (compactTv ? 12 : 14) : 16,
        layout.isTv ? (compactTv ? 18 : 22) : layout.cardPadding,
        layout.isTv ? (compactTv ? 12 : 14) : 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.cardBorderRadius),
        gradient: const LinearGradient(
          colors: [Color(0xD2121C2C), Color(0xB5162234)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((eyebrow ?? '').trim().isNotEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compactTv ? 8 : 10,
                vertical: compactTv ? 5 : 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: colorScheme.primary.withValues(alpha: 0.14),
              ),
              child: Text(
                eyebrow!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: layout.isTv ? (compactTv ? 12 : 13) : null,
                  letterSpacing: 0.24,
                ),
              ),
            ),
            SizedBox(height: compactTv ? 8 : 12),
          ],
          Text(
            title ?? 'Modo de interface',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: layout.isTv ? (compactTv ? 18 : 20) : 18,
            ),
          ),
          if (compactTv) ...[
            SizedBox(height: layout.isTv ? 10 : 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth >= 760;
                if (horizontal) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Troque entre mobile e TV quando a box responder diferente ao controle.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.74),
                            fontSize: 12.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(child: selector),
                    ],
                  );
                }
                return selector;
              },
            ),
          ] else ...[
          if ((resolvedDescription ?? '').trim().isNotEmpty) ...[
            SizedBox(height: compactTv ? 6 : 8),
            Text(
              resolvedDescription!,
              maxLines: compactTv ? 2 : null,
              overflow: compactTv ? TextOverflow.ellipsis : null,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.78),
                fontSize: layout.isTv ? (compactTv ? 12.5 : 13.5) : null,
              ),
            ),
          ],
          SizedBox(height: layout.isTv ? (compactTv ? 8 : 12) : layout.sectionSpacing - 2),
          selector,
          if ((resolvedHelperText ?? '').trim().isNotEmpty) ...[
            SizedBox(height: compactTv ? 6 : 8),
            Text(
              resolvedHelperText!,
              maxLines: compactTv ? 2 : null,
              overflow: compactTv ? TextOverflow.ellipsis : null,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.76),
                fontSize: layout.isTv ? (compactTv ? 12 : 13) : null,
              ),
            ),
          ],
          ],
        ],
      ),
    );
  }
}
