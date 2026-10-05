import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/app_logo_mark.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/models/auth_models.dart';

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
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
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

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textCtrl.forward();

    // حداقل زمان نمایش splash + منتظر auth و config
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1800)),
      _waitForAuth(),
    ]);

    if (!mounted) return;
    _navigate();
  }

  /// منتظر می‌ماند تا AuthNotifier وضعیت اولیه‌اش رو مشخص کنه
  Future<void> _waitForAuth() async {
    // اگر هنوز initial یا loading است صبر می‌کنیم
    final completer = Future.doWhile(() async {
      final status = ref.read(authProvider).status;
      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      }
      return false;
    });
    await completer;
  }

  void _navigate() {
    final authStatus = ref.read(authProvider).status;
    if (authStatus == AuthStatus.authenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:                    Colors.transparent,
        statusBarIconBrightness:           Brightness.dark,
        systemNavigationBarColor:          Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColorsLight.bgBase,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.5),
              radius: 1.4,
              colors: [
                AppColorsLight.bgLight1,
                AppColorsLight.bgBase,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // ── Logo ─────────────────────────────────────
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

                // ── App name ──────────────────────────────────
                FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: RichText(
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

                // ── Dots ─────────────────────────────────────
                FadeTransition(
                  opacity: _textOpacity,
                  child: _SplashDots(controller: _dotsCtrl),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
            _Dot(color: AppColorsShared.orange, active: controller.value > 0.66),
            const SizedBox(width: 8),
            _Dot(color: AppColorsLight.textTertiary, active: controller.value > 0.33 && controller.value <= 0.66),
            const SizedBox(width: 8),
            _Dot(color: AppColorsLight.teal, active: controller.value <= 0.33),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.active});
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 10 : 8,
      height: active ? 10 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : color.withValues(alpha: 0.35),
      ),
    );
  }
}
