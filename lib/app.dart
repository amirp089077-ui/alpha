import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/settings/providers/config_provider.dart';

class AlphaVpnApp extends ConsumerWidget {
  const AlphaVpnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // config رو eager load می‌کنیم — splash منتظرش نیست ولی کش می‌شه
    ref.watch(appConfigProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'ALPHA VPN',
          debugShowCheckedModeBanner: false,

          // ── Routing ─────────────────────────────────────────────────────
          routerConfig: appRouter,

          // ── Theme ────────────────────────────────────────────────────────
          theme:      AppTheme.light(),
          darkTheme:  AppTheme.dark(),
          themeMode:  themeMode,

          // ── Locale / RTL ─────────────────────────────────────────────────
          locale: const Locale('fa', 'IR'),
          supportedLocales: const [
            Locale('fa', 'IR'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ── Text scale clamp ─────────────────────────────────────────────
          builder: (context, widget) {
            final mq = MediaQuery.of(context);
            final clampedScale = mq.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.1,
            );
            return Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                data: mq.copyWith(textScaler: clampedScale),
                child: widget!,
              ),
            );
          },
        );
      },
    );
  }
}
