import 'package:flutter/material.dart';

import '../../core/tv/tv_focusable.dart';
import '../presentation/layout/device_layout.dart';
import '../presentation/support/on_demand_library.dart';
import 'branded_artwork.dart';

class TvLibraryFilterOption {
  const TvLibraryFilterOption({
    required this.id,
    required this.label,
    required this.count,
    this.subtitle,
    this.icon,
    this.interactiveKey,
    this.testId,
  });

  final String id;
  final String label;
  final int count;
  final String? subtitle;
  final IconData? icon;
  final Key? interactiveKey;
  final String? testId;
}

class TvLibraryPosterCardData {
  const TvLibraryPosterCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
    required this.onPressed,
    this.badge,
    this.interactiveKey,
    this.testId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData icon;
  final VoidCallback onPressed;
  final String? badge;
  final Key? interactiveKey;
  final String? testId;
}

class TvLibraryShell extends StatefulWidget {
  const TvLibraryShell({
    super.key,
    required this.layout,
    required this.spec,
    required this.filters,
    required this.selectedFilterId,
    required this.onFilterSelected,
    required this.items,
    required this.emptyTitle,
    this.description,
  });

  final DeviceLayout layout;
  final OnDemandLibrarySpec spec;
  final List<TvLibraryFilterOption> filters;
  final String selectedFilterId;
  final ValueChanged<String> onFilterSelected;
  final List<TvLibraryPosterCardData> items;
  final String emptyTitle;
  final String? description;

  @override
  State<TvLibraryShell> createState() => _TvLibraryShellState();
}

class _TvLibraryShellState extends State<TvLibraryShell> {
  final ScrollController _filterController = ScrollController();
  final ScrollController _gridController = ScrollController();

  @override
  void didUpdateWidget(covariant TvLibraryShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilterId != widget.selectedFilterId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_gridController.hasClients) {
          return;
        }
        _gridController.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedFilter = _selectedFilter;
    final totalItems = widget.items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.description ?? widget.spec.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.72),
            height: 1.35,
            fontSize: widget.layout.isTvCompact ? 14 : 14.5,
          ),
        ),
        SizedBox(height: widget.layout.isTvCompact ? 14 : 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Filtro',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: widget.layout.isTvCompact ? 14 : 14.5,
              ),
            ),
            SizedBox(width: widget.layout.isTvCompact ? 12 : 14),
            Expanded(
              child: SizedBox(
                height: widget.layout.isTvCompact ? 62 : 64,
                child: Scrollbar(
                  controller: _filterController,
                  thumbVisibility: false,
                  child: ListView.separated(
                    controller: _filterController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: widget.filters.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(width: widget.layout.isTvCompact ? 10 : 12),
                    itemBuilder: (context, index) {
                      final filter = widget.filters[index];
                      return _TvLibraryFilterChip(
                        option: filter,
                        selected: filter.id == widget.selectedFilterId,
                        autofocus: index == 0,
                        onPressed: () => widget.onFilterSelected(filter.id),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: widget.layout.isTvCompact ? 10 : 12),
        Text(
          '${widget.spec.countLabel(totalItems)} • ${selectedFilter.label}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.82),
            fontWeight: FontWeight.w700,
            fontSize: widget.layout.isTvCompact ? 14 : 14.5,
          ),
        ),
        SizedBox(height: widget.layout.sectionSpacing),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = widget.layout.columnsForWidth(
                constraints.maxWidth,
                minTileWidth: widget.layout.isTvCompact ? 176 : 188,
                maxColumns: widget.layout.isTvCompact ? 5 : 6,
              );
              final childAspectRatio = widget.layout.isTvCompact ? 0.63 : 0.61;

              if (widget.items.isEmpty) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(
                      widget.emptyTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        fontSize: widget.layout.isTvCompact ? 17 : 18,
                      ),
                    ),
                  ),
                );
              }

              return Scrollbar(
                controller: _gridController,
                thumbVisibility: true,
                child: GridView.builder(
                  controller: _gridController,
                  padding: EdgeInsets.fromLTRB(
                    6,
                    2,
                    6,
                    widget.layout.pageBottomPadding,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: widget.layout.cardSpacing,
                    mainAxisSpacing: widget.layout.cardSpacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    return _TvLibraryPosterCard(
                      data: widget.items[index],
                      layout: widget.layout,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  TvLibraryFilterOption get _selectedFilter {
    for (final filter in widget.filters) {
      if (filter.id == widget.selectedFilterId) {
        return filter;
      }
    }
    return widget.filters.first;
  }
}

class _TvLibraryFilterChip extends StatelessWidget {
  const _TvLibraryFilterChip({
    required this.option,
    required this.selected,
    required this.autofocus,
    required this.onPressed,
  });

  final TvLibraryFilterOption option;
  final bool selected;
  final bool autofocus;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusable(
      autofocus: autofocus,
      interactiveKey: option.interactiveKey,
      testId: option.testId,
      onPressed: onPressed,
      builder: (context, focused) {
        final emphasized = focused || selected;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minWidth: 152, maxWidth: 212),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: emphasized
                ? colorScheme.surfaceContainerHighest.withValues(
                    alpha: selected ? 0.52 : 0.32,
                  )
                : colorScheme.surface.withValues(alpha: 0.12),
            border: Border.all(
              color: emphasized
                  ? colorScheme.primary.withValues(alpha: focused ? 0.72 : 0.42)
                  : colorScheme.outline.withValues(alpha: 0.14),
              width: focused ? 1.8 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.icon != null) ...[
                Icon(
                  option.icon,
                  size: 16,
                  color: emphasized
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.78),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    if (option.subtitle != null &&
                        option.subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        option.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.64),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${option.count}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: emphasized
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.74),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TvLibraryPosterCard extends StatelessWidget {
  const _TvLibraryPosterCard({required this.data, required this.layout});

  final TvLibraryPosterCardData data;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusable(
      interactiveKey: data.interactiveKey,
      testId: data.testId,
      onPressed: data.onPressed,
      builder: (context, focused) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: focused
                        ? colorScheme.primary.withValues(alpha: 0.78)
                        : colorScheme.outline.withValues(alpha: 0.08),
                    width: focused ? 2.2 : 0.8,
                  ),
                  boxShadow: focused
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: BrandedArtwork(
                          imageUrl: data.imageUrl,
                          aspectRatio: 2 / 3,
                          borderRadius: 18,
                          icon: data.icon,
                          placeholderLabel: 'Poster indisponível',
                          chrome: BrandedArtworkChrome.flat,
                        ),
                      ),
                      if (data.badge != null && data.badge!.trim().isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.black.withValues(alpha: 0.58),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              child: Text(
                                data.badge!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.32,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: layout.isTvCompact ? 10 : 12),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.1,
                fontSize: layout.isTvCompact ? 15.5 : 16.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.3,
                fontSize: layout.isTvCompact ? 12 : 12.5,
              ),
            ),
          ],
        );
      },
    );
  }
}
