import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _homeRoutePath = '/home';
const _searchRoutePath = '/search';
const _accountRoutePath = '/account';
const _homeContextPrefixes = <String>['/home', '/live', '/vod', '/series'];

class MobilePrimaryDock extends StatelessWidget {
  const MobilePrimaryDock({super.key});

  @override
  Widget build(BuildContext context) {
    var currentPath = '';
    try {
      currentPath = GoRouter.of(
        context,
      ).routeInformationProvider.value.uri.path;
    } catch (_) {
      currentPath = '';
    }
    final activeSection = resolveMobilePrimaryDockSection(currentPath);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.black,
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _MobileDockButton(
                  icon: Icons.home_filled,
                  label: 'Home',
                  active: activeSection == MobilePrimaryDockSection.home,
                  onTap: () => context.go(_homeRoutePath),
                ),
              ),
              Expanded(
                child: _MobileDockButton(
                  icon: Icons.search_rounded,
                  label: 'Busca',
                  active: activeSection == MobilePrimaryDockSection.search,
                  onTap: () => context.go(_searchRoutePath),
                ),
              ),
              Expanded(
                child: _MobileDockButton(
                  icon: Icons.account_circle_rounded,
                  label: 'Conta',
                  active: activeSection == MobilePrimaryDockSection.account,
                  onTap: () => context.go(_accountRoutePath),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
MobilePrimaryDockSection resolveMobilePrimaryDockSection(String currentPath) {
  if (currentPath.startsWith(_searchRoutePath)) {
    return MobilePrimaryDockSection.search;
  }
  if (currentPath.startsWith(_accountRoutePath)) {
    return MobilePrimaryDockSection.account;
  }
  if (_homeContextPrefixes.any(currentPath.startsWith)) {
    return MobilePrimaryDockSection.home;
  }
  return MobilePrimaryDockSection.home;
}

enum MobilePrimaryDockSection { home, search, account }

class _MobileDockButton extends StatelessWidget {
  const _MobileDockButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active
              ? colorScheme.primary.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? colorScheme.primary : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
