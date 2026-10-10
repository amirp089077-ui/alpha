import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/servers/presentation/screens/servers_screen.dart';
import '../../features/subscription/presentation/screens/subscription_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/whitelist/presentation/screens/whitelist_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';

// Route name constants
class AppRoutes {
  static const splash         = '/';
  static const login          = '/login';
  static const shell          = '/app';
  static const home           = '/app/home';
  static const servers        = '/app/servers';
  static const subscription   = '/app/subscription';
  static const settings       = '/app/settings';
  static const whitelist      = '/app/settings/whitelist';
  static const notifications  = '/app/notifications';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (ctx, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (ctx, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (ctx, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (ctx, state) => const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: AppRoutes.servers,
          pageBuilder: (ctx, state) => const NoTransitionPage(child: ServersScreen()),
        ),
        GoRoute(
          path: AppRoutes.subscription,
          pageBuilder: (ctx, state) => const NoTransitionPage(child: SubscriptionScreen()),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (ctx, state) => const NoTransitionPage(child: SettingsScreen()),
        ),
        GoRoute(
          path: AppRoutes.whitelist,
          builder: (ctx, state) => const WhitelistScreen(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (ctx, state) => const NotificationsScreen(),
        ),
      ],
    ),
  ],
);
