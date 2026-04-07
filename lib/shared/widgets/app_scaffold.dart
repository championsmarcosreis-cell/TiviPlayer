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
    this.showHeader = true,
    this.showTvSidebar = true,
    this.mobileBottomBar,
    this.mobileBottomInset = 92,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final bool decoratedHeader;
  final bool showBrand;
  final bool showHeader;
  final bool showTvSidebar;
  final Widget? mobileBottomBar;
  final double mobileBottomInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = DeviceLayout.of(context, constraints: constraints);
        final horizontalPadding = layout.pageHorizontalPadding;
        final effectiveMobileBottomBar = layout.isTv ? null : mobileBottomBar;

        final contentColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
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
            ],
            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: layout.maxContentWidth,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: effectiveMobileBottomBar == null
                              ? 0
                              : mobileBottomInset,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                  if (effectiveMobileBottomBar != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: layout.maxContentWidth,
                          ),
                          child: effectiveMobileBottomBar,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

        final routeLocation = _resolveMatchedLocation(context);

        return Scaffold(
          body: ColoredBox(
            color: Colors.black,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  layout.pageTopPadding,
                  horizontalPadding,
                  layout.pageBottomPadding,
                ),
                child: layout.isTv && showTvSidebar
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: layout.isTvCompact ? 72 : 80,
                            child: _TvAppSidebar(routeLocation: routeLocation),
                          ),
                          SizedBox(width: layout.isTvCompact ? 12 : 14),
                          Expanded(child: contentColumn),
                        ],
                      )
                    : contentColumn,
              ),
            ),
          ),
        );
      },
    );
  }
}

String _resolveMatchedLocation(BuildContext context) {
  try {
    return GoRouterState.of(context).matchedLocation;
  } on GoError {
    return '';
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
                                DeviceClass.tvCompact => 35,
                                DeviceClass.tvLarge => 38,
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
                          DeviceClass.tvCompact => 16,
                          DeviceClass.tvLarge => 17,
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
              horizontal: layout.isTv ? 16 : 14,
              vertical: layout.isTv ? 12 : 12,
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

class _TvAppSidebar extends StatelessWidget {
  const _TvAppSidebar({required this.routeLocation});

  final String routeLocation;

  bool get _searchSelected => routeLocation == '/search';
  bool get _accountSelected => routeLocation == '/account';
  bool get _homeSelected => !_searchSelected && !_accountSelected;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: BrandLogo(
            variant: BrandLogoVariant.icon,
            width: 34,
            height: 34,
          ),
        ),
        SizedBox(height: layout.isTvCompact ? 26 : 30),
        _TvAppSidebarItem(
          icon: Icons.home_rounded,
          selected: _homeSelected,
          onPressed: () => context.go('/home'),
        ),
        SizedBox(height: layout.isTvCompact ? 18 : 20),
        _TvAppSidebarItem(
          icon: Icons.search_rounded,
          selected: _searchSelected,
          onPressed: () => context.go('/search'),
        ),
        SizedBox(height: layout.isTvCompact ? 18 : 20),
        _TvAppSidebarItem(
          icon: Icons.verified_user_rounded,
          selected: _accountSelected,
          onPressed: () => context.go('/account'),
        ),
      ],
    );
  }
}

class _TvAppSidebarItem extends StatelessWidget {
  const _TvAppSidebarItem({
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);

    return TvFocusable(
      onPressed: onPressed,
      builder: (context, focused) {
        final emphasized = focused || selected;
        final itemExtent = layout.isTvCompact ? 54.0 : 58.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: itemExtent,
          height: itemExtent,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: emphasized
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: const Color(0x66AF7BFF).withValues(alpha: 0.26),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : const [],
          ),
          child: Icon(
            icon,
            size: 23,
            color: emphasized
                ? Colors.white
                : Colors.white.withValues(alpha: 0.74),
          ),
        );
      },
    );
  }
}
