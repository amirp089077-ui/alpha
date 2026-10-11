import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ── Page content ────────────────────────────────────────────
            child,

            // ── Floating nav bar ─────────────────────────────────────────
            Positioned(
              left: 20,
              right: 20,
              bottom: 20 + MediaQuery.of(context).padding.bottom,
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

    return Center(
      child: Container(
        height: 64.h,
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: colors.isLight ? Colors.white : colors.navGlass,
          borderRadius: BorderRadius.circular(36.r),
          border: Border.all(
            color: colors.isLight ? const Color(0xFFE2EDF0) : colors.navBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: colors.isLight ? 0.08 : 0.25),
              blurRadius: 20.r,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(tabs.length, (i) {
            final isActive = i == currentIndex;
            final tab = tabs[i];
            return _NavItem(
              tab: tab,
              isActive: isActive,
              onTap: () => onTap(i),
              colors: colors,
            );
          }),
        ),
      ),
    );
  }
}

// ─── Individual nav item (کپسول متحرک گرادینت برای تب فعال) ───────────────────
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
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16.w : 12.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF0E8A98), Color(0xFFE05A38)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              Text(
                tab.label,
                style: AppTypography.title3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(width: 6.w),
            ],
            Icon(
              isActive ? tab.activeIcon : tab.icon,
              size: 22.r,
              color: isActive
                  ? Colors.white
                  : (colors.isLight ? const Color(0xFF4A6572) : colors.textTertiary),
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
