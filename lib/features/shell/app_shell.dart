import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/strings.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/haptics.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(route: AppRoutes.home,         icon: Icons.shield_outlined,    activeIcon: Icons.shield,           label: S.navHome),
    _TabItem(route: AppRoutes.servers,      icon: Icons.dns_outlined,        activeIcon: Icons.dns,              label: S.navServers),
    _TabItem(route: AppRoutes.subscription, icon: Icons.sync_alt_rounded,    activeIcon: Icons.sync_alt_rounded, label: S.navSubscription),
    _TabItem(route: AppRoutes.settings,     icon: Icons.tune_outlined,       activeIcon: Icons.tune,             label: S.navSettings),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Page content ──────────────────────────────────────────────
          child,

          // ── Floating nav bar ──────────────────────────────────────────
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _FloatingNavBar(
              currentIndex: currentIndex,
              tabs: _tabs,
              onTap: (i) {
                AppHaptics.selection();
                context.go(_tabs[i].route);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Floating nav bar ─────────────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: colors.navGlass,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: colors.navBorder, width: 1),
          ),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isActive = i == currentIndex;
              final tab = tabs[i];
              return Expanded(
                child: _NavItem(
                  tab: tab,
                  isActive: isActive,
                  onTap: () => onTap(i),
                  colors: colors,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Individual nav item ──────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.colors,
  });

  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: isActive ? colors.brandGradient : null,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? tab.activeIcon : tab.icon,
              size: 22,
              color: isActive ? Colors.white : colors.textTertiary,
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              style: AppTypography.micro.copyWith(
                color: isActive ? Colors.white : colors.textTertiary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                fontSize: 11,
              ),
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
