import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/app_logo_mark.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/models/auth_models.dart';
import '../../settings/providers/config_provider.dart';
import '../../settings/data/models/app_config_models.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _dotsCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset>  _textSlide;

  // وضعیت نمایش پایین splash
  String _statusText = 'در حال اتصال به سرور...';

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:                    Colors.transparent,
      statusBarIconBrightness:           Brightness.dark,
      systemNavigationBarColor:          Colors.transparent,
    ));

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0,
      upperBound: 1,
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.6)),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _startSequence();
  }

  // ── Sequence اصلی ────────────────────────────────────────────────────

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textCtrl.forward();

    // همزمان: حداقل نمایش ۱۸۰۰ms + دریافت config + auth
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1800)),
      _loadConfig(),
      _waitForAuth(),
    ]);

    if (!mounted) return;
    _handlePostLoad();
  }

  // ── دریافت config از سرور ───────────────────────────────────────────

  Future<void> _loadConfig() async {
    _setStatus('در حال اتصال به سرور...');
    try {
      await ref.read(appConfigProvider.notifier).fetch();
      _setStatus('');
    } catch (_) {
      // سایلنت — از defaultConfig استفاده می‌شه
      _setStatus('');
    }
  }

  // ── انتظار برای resolve شدن auth ────────────────────────────────────

  Future<void> _waitForAuth() async {
    await Future.doWhile(() async {
      final status = ref.read(authProvider).status;
      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      }
      return false;
    });
  }

  // ── پس از load: maintenance → forceUpdate → navigate ────────────────

  void _handlePostLoad() {
    final config = ref.read(configProvider);

    // ۱. حالت تعمیر
    if (config.maintenanceMode) {
      _showMaintenanceDialog(config.maintenanceMessage);
      return;
    }

    // ۲. اجبار به آپدیت — نیاز به مقایسه نسخه داریم
    if (config.forceUpdate && config.latestVersion.isNotEmpty) {
      _checkForceUpdate(config);
      return;
    }

    // ۳. اعلان (announcement) — فقط نمایش می‌ده، navigate هم می‌کنه
    if (config.announcement.isNotEmpty) {
      _showAnnouncementDialog(config.announcement, onDismiss: _navigate);
      return;
    }

    _navigate();
  }

  /// نسخه اپ رو از PackageInfo بخون و با latest_version سرور مقایسه کن
  Future<void> _checkForceUpdate(AppConfigModel config) async {
    try {
      final info       = await PackageInfo.fromPlatform();
      final appVersion = info.version; // مثلاً "1.0.0"
      final latest     = config.latestVersion; // مثلاً "1.2.0"

      if (_isOlderVersion(appVersion, latest)) {
        // نسخه اپ قدیمیه — dialog اجباری
        if (!mounted) return;
        _showForceUpdateDialog(
          updateUrl:  config.updateUrl,
          changelog:  config.updateChangelog,
          newVersion: latest,
          appVersion: appVersion,
        );
        return;
      }
    } catch (_) {
      // اگه PackageInfo خطا داد، بدون چک ادامه بده
    }

    // نسخه اپ به‌روزه
    if (config.announcement.isNotEmpty) {
      _showAnnouncementDialog(config.announcement, onDismiss: _navigate);
    } else {
      _navigate();
    }
  }

  /// مقایسه semantic version — true اگه a < b
  bool _isOlderVersion(String a, String b) {
    try {
      final aParts = a.split('.').map(int.parse).toList();
      final bParts = b.split('.').map(int.parse).toList();
      // طول هر دو رو برابر کن
      while (aParts.length < 3) aParts.add(0);
      while (bParts.length < 3) bParts.add(0);
      for (var i = 0; i < 3; i++) {
        if (aParts[i] < bParts[i]) return true;
        if (aParts[i] > bParts[i]) return false;
      }
      return false; // برابر
    } catch (_) {
      return false;
    }
  }

  // ── Navigate ─────────────────────────────────────────────────────────

  void _navigate() {
    if (!mounted) return;
    final authStatus = ref.read(authProvider).status;
    if (authStatus == AuthStatus.authenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  // ── Dialog ها ────────────────────────────────────────────────────────

  void _showMaintenanceDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.build_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('سرویس در دسترس نیست'),
            ],
          ),
          content: Text(
            message.isNotEmpty
                ? message
                : 'سرویس موقتاً در دسترس نیست. لطفاً بعداً تلاش کنید.',
            style: const TextStyle(height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // تلاش مجدد
                Navigator.of(context).pop();
                _startSequence();
              },
              child: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }

  void _showForceUpdateDialog({
    required String updateUrl,
    required String changelog,
    required String newVersion,
    String appVersion = '',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.system_update_rounded, color: Colors.teal),
              SizedBox(width: 8),
              Text('آپدیت اجباری'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (newVersion.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'IranSans',
                        color: Colors.black87,
                        height: 1.6,
                      ),
                      children: [
                        if (appVersion.isNotEmpty) ...[
                          const TextSpan(text: 'نسخه شما: '),
                          TextSpan(
                            text: appVersion,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const TextSpan(text: '\n'),
                        ],
                        const TextSpan(text: 'آخرین نسخه: '),
                        TextSpan(
                          text: newVersion,
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (changelog.isNotEmpty)
                Text(changelog, style: const TextStyle(height: 1.6))
              else
                const Text(
                  'برای استفاده از سرویس باید اپلیکیشن را به‌روز کنید.',
                  style: TextStyle(height: 1.6),
                ),
            ],
          ),
          actions: [
            if (updateUrl.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => _launchUrl(updateUrl),
                icon: const Icon(Icons.download_rounded),
                label: const Text('دانلود آپدیت'),
              ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementDialog(String message, {required VoidCallback onDismiss}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.campaign_rounded, color: Colors.teal),
              SizedBox(width: 8),
              Text('اطلاعیه'),
            ],
          ),
          content: Text(message, style: const TextStyle(height: 1.6)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss();
              },
              child: const Text('متوجه شدم'),
            ),
          ],
        ),
      ),
    ).then((_) {
      // اگه dismiss شد بدون دکمه (tap خارج)
      onDismiss();
    });
  }

  // ── Helper ───────────────────────────────────────────────────────────

  void _setStatus(String text) {
    if (mounted) setState(() => _statusText = text);
  }

  Future<void> _launchUrl(String url) async {
    try {
      const channel = MethodChannel('alpha_vpn/launcher');
      await channel.invokeMethod('openUrl', {'url': url});
    } catch (_) {
      // اگه channel جواب نداد، silent fail
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:                    Colors.transparent,
        statusBarIconBrightness:           Brightness.dark,
        systemNavigationBarColor:          Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          backgroundColor: AppColorsLight.bgBase,
          body: Container(
            width:  double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.4,
                colors: [AppColorsLight.bgLight1, AppColorsLight.bgBase],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // ── Logo ─────────────────────────────────────────────
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: const AppLogoMark(
                        size: 110,
                        ringWidth: 2.5,
                        showGlow: false,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── App name ──────────────────────────────────────────
                  FadeTransition(
                    opacity: _textOpacity,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'ALPHA ',
                                  style: AppTypography.logoLatin.copyWith(
                                    color: AppColorsLight.textPrimary,
                                  ),
                                ),
                                TextSpan(
                                  text: 'VPN',
                                  style: AppTypography.logoLatin.copyWith(
                                    color: AppColorsLight.teal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اینترنت آزاد، سریع و امن',
                            style: AppTypography.body.copyWith(
                              color: AppColorsLight.textSecondary,
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 4),

                  // ── Dots ──────────────────────────────────────────────
                  FadeTransition(
                    opacity: _textOpacity,
                    child: _SplashDots(controller: _dotsCtrl),
                  ),

                  const SizedBox(height: 12),

                  // ── Status text ───────────────────────────────────────
                  FadeTransition(
                    opacity: _textOpacity,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _statusText.isNotEmpty
                          ? Padding(
                              key: ValueKey(_statusText),
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _statusText,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColorsLight.textTertiary,
                                ),
                              ),
                            )
                          : const SizedBox(key: ValueKey('empty'), height: 18),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Splash dots ───────────────────────────────────────────────────────────────

class _SplashDots extends StatelessWidget {
  const _SplashDots({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(
              color: AppColorsShared.orange,
              active: controller.value > 0.66,
            ),
            const SizedBox(width: 8),
            _Dot(
              color: AppColorsLight.textTertiary,
              active: controller.value > 0.33 && controller.value <= 0.66,
            ),
            const SizedBox(width: 8),
            _Dot(
              color: AppColorsLight.teal,
              active: controller.value <= 0.33,
            ),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.active});
  final Color color;
  final bool  active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width:  active ? 10 : 8,
      height: active ? 10 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : color.withValues(alpha: 0.35),
      ),
    );
  }
}
