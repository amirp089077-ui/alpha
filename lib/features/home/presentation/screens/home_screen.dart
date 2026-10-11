import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/persian_digits.dart';
import '../../../../core/widgets/country_flag_badge.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/neon_orb_logo.dart';
import '../../data/models/home_models.dart';
import '../../providers/home_provider.dart';
import '../../../servers/data/models/server_models.dart';
import '../../../servers/providers/servers_provider.dart';
import '../../../settings/providers/config_provider.dart';
import '../../../notifications/providers/notifications_provider.dart';
import '../../../notifications/data/models/notification_models.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// HomeScreen
// ═══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _broadcastShownKey = 'broadcast_shown_v1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkQuotaOnInit();
      _checkBroadcast();
    });
  }

  void _checkQuotaOnInit() {
    final state = ref.read(homeProvider);
    if (state.errorMessage != null && state.errorMessage!.contains('حجم')) {
      _showQuotaDialog();
    }
  }

  Future<void> _checkBroadcast() async {
    final config = ref.read(configProvider);
    if (!config.broadcastEnabled || config.broadcastMessage.isEmpty) return;
    final prefs    = await SharedPreferences.getInstance();
    final shownMsg = prefs.getString(_broadcastShownKey) ?? '';
    if (shownMsg == config.broadcastMessage) return;
    if (!mounted) return;
    _showBroadcastDialog(config.broadcastMessage, config.broadcastType);
    await prefs.setString(_broadcastShownKey, config.broadcastMessage);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<HomeState>(homeProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage!.contains('حجم') &&
          prev?.errorMessage != next.errorMessage) {
        _showQuotaDialog();
      }
    });

    final state    = ref.watch(homeProvider);
    final serversState = ref.watch(serversProvider);
    final colors   = Theme.of(context).extension<AppColors>()!;
    final glowMode = state.isConnected ? GlowMode.connected : GlowMode.neutral;

    final currentServer = state.activeServer ??
        (serversState.groups.isNotEmpty &&
                serversState.groups.first.locations.isNotEmpty
            ? serversState.groups.first.locations.first
            : const ServerItem(
                id: 'default',
                country: 'انگلیس ۲',
                city: 'لندن',
                flag: '🇬🇧',
                host: 'uk2.alphavpn.net',
                port: 443,
                ping: 214,
                configUri: '',
              ));

    return GradientBackground(
      glowMode: glowMode,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeAppBar(colors: colors),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    16.w, 4.h, 16.w, 90.h + MediaQuery.of(context).padding.bottom),
                child: Column(
                  children: [
                    SizedBox(height: 8.h),
                    _OrbSection(state: state, colors: colors),
                    SizedBox(height: 18.h),
                    _StatusText(state: state, colors: colors),
                    SizedBox(height: 22.h),
                    _StatsRow(state: state, colors: colors),
                    SizedBox(height: 14.h),
                    _ActiveServerCard(
                      server: currentServer,
                      colors: colors,
                      isSmart: serversState.selectedServerId == 'smart',
                    ),
                    _HomeNotifBanners(colors: colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  void _showQuotaDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final c = Theme.of(ctx).extension<AppColors>()!;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            backgroundColor: c.card,
            title: Text('حجم اینترنت تمام شد',
                style: AppTypography.title2.copyWith(color: c.textPrimary)),
            content: Text(
              'حجم اشتراک شما به پایان رسیده است.\n'
              'برای ادامه استفاده لطفاً اشتراک خود را تمدید کنید.',
              style: AppTypography.body.copyWith(color: c.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('بعداً',
                    style:
                        AppTypography.body.copyWith(color: c.textTertiary)),
              ),
              GradientButton(
                label: 'تمدید اشتراک',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go(AppRoutes.subscription);
                },
                height: 44,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBroadcastDialog(String message, String type) {
    if (!mounted) return;

    final Color accent;
    final IconData icon;
    switch (type) {
      case 'warning':
        accent = Colors.orange;
        icon   = Icons.warning_amber_rounded;
      case 'success':
        accent = Colors.green;
        icon   = Icons.check_circle_outline_rounded;
      case 'error':
        accent = Colors.red;
        icon   = Icons.error_outline_rounded;
      default:
        accent = const Color(0xFF0FA3B1);
        icon   = Icons.campaign_rounded;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final c = Theme.of(ctx).extension<AppColors>()!;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            backgroundColor: c.card,
            title: Row(
              children: [
                Icon(icon, color: accent, size: 24),
                const SizedBox(width: 8),
                Text('اطلاعیه',
                    style:
                        AppTypography.title2.copyWith(color: c.textPrimary)),
              ],
            ),
            content: Text(message,
                style: AppTypography.body
                    .copyWith(color: c.textSecondary, height: 1.6)),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('متوجه شدم'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// App Bar
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeAppBar extends ConsumerWidget {
  const _HomeAppBar({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPinging = ref.watch(serversProvider).isPinging;
    final unread    = ref.watch(notificationsProvider).unreadCount;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            // ── لوگوی کوچک و عنوان برند در سمت چپ ────────────────────
            GestureDetector(
              onTap: () => context.go(AppRoutes.home),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFE2F7F6), Color(0xFFCEEFF1)],
                      ),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0E8A98).withValues(alpha: 0.15),
                          blurRadius: 8.r,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(2.r),
                    child: Image.asset(
                      'assets/images/appbar_logo.webp',
                      width: 28.r,
                      height: 28.r,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'ALPHA',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0E8A98),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: 'VPN',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFE05A38),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── دکمه اعلانات و دکمه رفرش در سمت راست ──────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NotifButton(unread: unread, colors: colors),
                SizedBox(width: 10.w),
                _RefreshButton(isPinging: isPinging, colors: colors),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── دکمه رفرش/پینگ گرد با بک‌گراند شیشه‌ای ──────────────────────────────────
class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.isPinging, required this.colors});
  final bool isPinging;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return GestureDetector(
          onTap: () {
            AppHaptics.light();
            ref.read(serversProvider.notifier).fetchPings();
          },
          child: Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE8EEF1), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8.r,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: isPinging
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2.w,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0E8A98),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      color: const Color(0xFF0F172A),
                      size: 22.r,
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ─── دکمه اعلانات گرد با نشانگر قرمز ──────────────────────────────────────────
class _NotifButton extends StatelessWidget {
  const _NotifButton({required this.unread, required this.colors});
  final int       unread;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptics.light();
        context.push(AppRoutes.notifications);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE8EEF1), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8.r,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.confirmation_number_outlined,
                color: const Color(0xFFE68A00),
                size: 22.r,
              ),
            ),
          ),
          Positioned(
            top: 2.h,
            right: 2.w,
            child: Container(
              width: 10.r,
              height: 10.r,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                    blurRadius: 4.r,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// بخش کره مرکزی ۳ بعدی
// ═══════════════════════════════════════════════════════════════════════════════

class _OrbSection extends ConsumerWidget {
  const _OrbSection({required this.state, required this.colors});
  final HomeState state;
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NeonOrbButton(
      isConnected: state.isConnected,
      isConnecting: state.isConnecting || state.isDisconnecting,
      onTap: () {
        AppHaptics.medium();
        ref.read(homeProvider.notifier).toggleConnection();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// وضعیت اتصال، تایمر، مشخصات سرور و پینگ
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusText extends StatelessWidget {
  const _StatusText({required this.state, required this.colors});
  final HomeState state;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final bool isConnected = state.isConnected;
    final bool isConnecting = state.isConnecting;
    final String serverName = state.activeServer?.name ?? 'انگلیس ۲';

    return Column(
      children: [
        // متن وضعیت اتصال (سبز فیروزه‌ای دقیق مرجع)
        Text(
          isConnected
              ? 'متصل هستید'
              : (isConnecting ? 'در حال اتصال...' : 'قطع هستید'),
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: isConnected
                ? const Color(0xFF0D9488)
                : (isConnecting ? const Color(0xFFE8590C) : const Color(0xFF64748B)),
          ),
          textDirection: TextDirection.rtl,
        ),

        if (isConnected) ...[
          SizedBox(height: 6.h),
          // زمان اتصال با ارقام فارسی
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              formatDurationFa(state.connectionSeconds),
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 23.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: 1.0,
              ),
            ),
          ),
          SizedBox(height: 6.h),

          // نام سرور، نشان CL و پینگ
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.pingMs > 0 ? '${state.pingMs.toFa()}ms' : '۲۱۴ms',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                'پینگ',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Text('•', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 13.sp)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE04838),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'CL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                serverName,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          SizedBox(height: 6.h),

          // مصرف این اتصال ۵ مگ
          Text(
            'مصرف این اتصال ${state.usageMb > 0 ? formatDataFa(state.usageMb / 1024) : '۵ مگ'}',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
            ),
            textDirection: TextDirection.rtl,
          ),
        ] else if (!isConnecting) ...[
          SizedBox(height: 6.h),
          Text(
            'برای اتصال دکمه بالا را لمس کنید',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ردیف سنجش حجم و زمان باقیمانده (کامپوننت ۲ حلقه‌ای دقیق مرجع)
// ═══════════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state, required this.colors});
  final HomeState state;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final bool showMb = state.remainingGb < 2.0;
    final String volumeValue = showMb
        ? '${(state.remainingGb * 1024).toInt().toFa()} مگ'
        : '${state.remainingGb.toFaDecimal(digits: 1)} گیگ';
    final String timeValue = '${state.remainingDays.toFa()} روز';

    final double volumeProgress = (state.remainingGb / 50.0).clamp(0.05, 1.0);
    final double timeProgress = (state.remainingDays / 60.0).clamp(0.05, 1.0);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Row(
        children: [
          // آیتم سمت چپ: زمان باقیمانده (حلقه زرد/نارنجی)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeValue,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'زمان باقیمانده',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
                SizedBox(width: 10.w),
                _CircularRingGauge(
                  progress: timeProgress,
                  color: const Color(0xFFF59E0B),
                  size: 32.r,
                ),
              ],
            ),
          ),

          // جداکننده عمودی وسط
          Container(
            width: 1.2.w,
            height: 36.h,
            color: const Color(0xFFE2E8F0),
          ),

          // آیتم سمت راست: حجم باقیمانده (حلقه سبز)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      volumeValue,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'حجم باقیمانده',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
                SizedBox(width: 10.w),
                _CircularRingGauge(
                  progress: volumeProgress,
                  color: const Color(0xFF10B981),
                  size: 32.r,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── حلقه کوچک گیج پیشرفت ──────────────────────────────────────────────────
class _CircularRingGauge extends StatelessWidget {
  const _CircularRingGauge({
    required this.progress,
    required this.color,
    required this.size,
  });

  final double progress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingGaugePainter(
          progress: progress,
          color: color,
        ),
      ),
    );
  }
}

class _RingGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2.5;

    // پس‌زمینه کم‌رنگ دایره
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6;
    canvas.drawCircle(center, radius, trackPaint);

    // کمان فعال
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.6;

    final sweep = progress.clamp(0.05, 1.0) * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingGaugePainter old) =>
      old.progress != progress || old.color != color;
}

// ═══════════════════════════════════════════════════════════════════════════════
// کارت انتخاب سرور فعال کپسولی سفید با پرچم دایره‌ای
// ═══════════════════════════════════════════════════════════════════════════════

class _ActiveServerCard extends StatelessWidget {
  const _ActiveServerCard({
    required this.server,
    required this.colors,
    this.isSmart = false,
  });
  final ServerLocation server;
  final AppColors      colors;
  final bool           isSmart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.servers),
      child: Container(
        height: 60.h,
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(
            color: isSmart ? const Color(0xFF0E8A98).withValues(alpha: 0.35) : const Color(0xFFE8EEF1),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSmart
                  ? const Color(0xFF0E8A98).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 14.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.chevron_left_rounded,
              color: const Color(0xFF94A3B8),
              size: 24.r,
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isSmart ? const Color(0xFF0D9488) : const Color(0xFFE04838),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    isSmart ? 'AUTO' : 'CL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  isSmart ? 'سرور هوشمند' : server.name,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            SizedBox(width: 12.w),
            if (isSmart)
              Container(
                width: 34.r,
                height: 34.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE05A38), Color(0xFF0E8A98)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0E8A98).withValues(alpha: 0.3),
                      blurRadius: 6.r,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.bolt_rounded, color: Colors.white, size: 20.r),
                ),
              )
            else
              CountryFlagBadge(
                countryCodeOrName: server.name,
                flagEmoji: server.flagEmoji,
                size: 34.r,
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Home Notification Banners
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeNotifBanners extends ConsumerWidget {
  const _HomeNotifBanners({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider).homeItems;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: items.map((n) {
        if (n.type == NotifType.offer) {
          return _BannerOffer(n: n, colors: colors);
        }
        if (n.type == NotifType.tip) {
          return _BannerTip(n: n, colors: colors);
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}

// ─── Offer Banner ─────────────────────────────────────────────────────────────

class _BannerOffer extends StatelessWidget {
  const _BannerOffer({required this.n, required this.colors});
  final AppNotification n;
  final AppColors       colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: n.actionUrl.isNotEmpty
            ? () {
                const ch = MethodChannel('alpha_vpn/launcher');
                ch.invokeMethod('openUrl', {'url': n.actionUrl});
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(n.title,
                              style: AppTypography.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ),
                        if (n.discount.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${n.discount}٪',
                                style: AppTypography.micro.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                    if (n.body.isNotEmpty)
                      Text(n.body,
                          style: AppTypography.micro.copyWith(
                              color: Colors.white.withValues(alpha: 0.85)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded,
                  color: Colors.white.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tip Banner ───────────────────────────────────────────────────────────────

class _BannerTip extends StatefulWidget {
  const _BannerTip({required this.n, required this.colors});
  final AppNotification n;
  final AppColors       colors;

  @override
  State<_BannerTip> createState() => _BannerTipState();
}

class _BannerTipState extends State<_BannerTip> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: widget.colors.card,
          border: Border.all(
              color: AppColorsLight.teal.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.n.title,
                      style: AppTypography.caption.copyWith(
                          color: widget.colors.textPrimary,
                          fontWeight: FontWeight.w700)),
                  Text(widget.n.body,
                      style: AppTypography.micro
                          .copyWith(color: widget.colors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded,
                  size: 18, color: widget.colors.textTertiary),
              onPressed: () => setState(() => _dismissed = true),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
