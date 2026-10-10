import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/persian_digits.dart';
import '../../../../core/widgets/app_logo_mark.dart';
import '../../../../core/widgets/circle_icon_button.dart';
import '../../../../core/widgets/circular_gauge.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../../core/widgets/status_badge.dart';
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
    final colors   = Theme.of(context).extension<AppColors>()!;
    final glowMode = state.isConnected ? GlowMode.connected : GlowMode.neutral;

    return GradientBackground(
      glowMode: glowMode,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeAppBar(colors: colors),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 0, 20, 100 + MediaQuery.of(context).padding.bottom),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _OrbSection(state: state, colors: colors),
                    const SizedBox(height: 24),
                    _StatusText(state: state, colors: colors),
                    const SizedBox(height: 28),
                    _StatsRow(state: state, colors: colors),
                    const SizedBox(height: 16),
                    if (state.activeServer != null)
                      _ActiveServerCard(
                          server: state.activeServer!, colors: colors),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.dns_rounded,
            onTap: () => context.go(AppRoutes.servers),
            tooltip: 'سرورها',
          ),
          const SizedBox(width: 10),
          CircleIconButton(
            icon: Icons.network_ping_rounded,
            isLoading: isPinging,
            onTap: () {
              AppHaptics.light();
              ref.read(serversProvider.notifier).fetchPings();
            },
            tooltip: 'بررسی پینگ',
          ),
          const Spacer(),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogoMark(size: 32, ringWidth: 1.5, showGlow: false),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'ALPHA ',
                        style: AppTypography.logoLatinSmall
                            .copyWith(color: colors.textPrimary),
                      ),
                      TextSpan(
                        text: 'VPN',
                        style: AppTypography.logoLatinSmall
                            .copyWith(color: colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _NotifButton(unread: unread, colors: colors),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Notification Badge Button
// ═══════════════════════════════════════════════════════════════════════════════

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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.card,
              border: Border.all(color: colors.navBorder, width: 1),
            ),
            child: Icon(
              unread > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: unread > 0 ? colors.blue : colors.textTertiary,
              size: 22,
            ),
          ),
          if (unread > 0)
            Positioned(
              top: -2,
              left: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.bgBase, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    unread > 9 ? '۹+' : unread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'IranSans',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Orb / Connect Button
// ═══════════════════════════════════════════════════════════════════════════════

class _OrbSection extends ConsumerWidget {
  const _OrbSection({required this.state, required this.colors});
  final HomeState state;
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected     = state.isConnected;
    final isTransitioning = state.isConnecting || state.isDisconnecting;

    return GestureDetector(
      onTap: isTransitioning
          ? null
          : () {
              AppHaptics.medium();
              ref.read(homeProvider.notifier).toggleConnection();
            },
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _OrbitRing(isConnected: isConnected, colors: colors),
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isConnected
                      ? [
                          const Color(0xFF1D4A60).withValues(alpha: 0.9),
                          const Color(0xFF0D1E2C).withValues(alpha: 0.85),
                        ]
                      : [
                          const Color(0xFF1A3346).withValues(alpha: 0.85),
                          const Color(0xFF0D1824).withValues(alpha: 0.80),
                        ],
                ),
                border: Border.all(
                  color: isConnected
                      ? colors.mint.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.10),
                  width: 1.5,
                ),
                boxShadow: isConnected
                    ? [
                        BoxShadow(
                          color: colors.mint.withValues(alpha: 0.20),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: colors.blue.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
              ),
            ),
            AppLogoMark(size: 130, ringWidth: 2, showGlow: isConnected),
            if (isTransitioning)
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.30),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Orbit Ring ───────────────────────────────────────────────────────────────

class _OrbitRing extends StatefulWidget {
  const _OrbitRing({required this.isConnected, required this.colors});
  final bool      isConnected;
  final AppColors colors;

  @override
  State<_OrbitRing> createState() => _OrbitRingState();
}

class _OrbitRingState extends State<_OrbitRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return _ring();
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) =>
          Transform.rotate(angle: _ctrl.value * 2 * 3.14159, child: _ring()),
    );
  }

  Widget _ring() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.isConnected
              ? widget.colors.mint.withValues(alpha: 0.35)
              : widget.colors.blue.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 80,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isConnected
                    ? widget.colors.mint
                    : widget.colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isConnected
                            ? widget.colors.mint
                            : widget.colors.blue)
                        .withValues(alpha: 0.8),
                    blurRadius: 6,
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
// Status Text
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusText extends StatelessWidget {
  const _StatusText({required this.state, required this.colors});
  final HomeState state;
  final AppColors colors;

  String get _label {
    switch (state.vpnStatus) {
      case VpnStatus.connected:     return S.homeConnected;
      case VpnStatus.connecting:    return S.homeConnecting;
      case VpnStatus.disconnecting: return S.homeDisconnecting;
      case VpnStatus.disconnected:  return S.homeNotConnected;
      case VpnStatus.error:         return state.errorMessage ?? 'خطا در اتصال';
    }
  }

  Color _color(AppColors c) {
    switch (state.vpnStatus) {
      case VpnStatus.connected:     return c.mint;
      case VpnStatus.connecting:    return c.blue;
      case VpnStatus.disconnecting: return c.orange;
      case VpnStatus.disconnected:  return c.textSecondary;
      case VpnStatus.error:         return c.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            key: ValueKey(state.vpnStatus),
            _label,
            style: AppTypography.status.copyWith(color: _color(colors)),
            textDirection: TextDirection.rtl,
          ),
        ),
        if (state.isConnected) ...[
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              formatDurationFa(state.connectionSeconds),
              style: AppTypography.timer.copyWith(color: colors.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          if (state.activeServer != null)
            Directionality(
              textDirection: TextDirection.rtl,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTypography.body
                      .copyWith(color: colors.textSecondary),
                  children: [
                    TextSpan(text: state.activeServer!.name),
                    if (state.activeServer!.badge == ServerBadge.b)
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: StatusBadge(type: BadgeType.b),
                        ),
                      ),
                    const TextSpan(text: '  •  پینگ '),
                    TextSpan(
                      text: state.pingMs == 0
                          ? '...'
                          : state.pingMs < 0
                              ? 'خطا'
                              : '${state.pingMs} ms',
                      style: TextStyle(
                        fontFamily: 'IranSans',
                        color: state.pingMs <= 0
                            ? colors.textTertiary
                            : state.pingMs < 150
                                ? colors.mint
                                : colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            '${S.homeUsage}  ${formatDataFa(state.usageMb / 1024)}',
            style:
                AppTypography.caption.copyWith(color: colors.textSecondary),
            textDirection: TextDirection.rtl,
          ),
        ],
        if (!state.isConnected &&
            !state.isConnecting &&
            !state.isDisconnecting) ...[
          const SizedBox(height: 8),
          Text(
            S.homeTapToConnect,
            style:
                AppTypography.caption.copyWith(color: colors.textTertiary),
            textDirection: TextDirection.rtl,
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Stats Row
// ═══════════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state, required this.colors});
  final HomeState state;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(S.homeGig,
                            style: AppTypography.caption
                                .copyWith(color: colors.textSecondary)),
                        const SizedBox(width: 4),
                        GradientText(
                          text: state.remainingGb.toFaDecimal(digits: 1),
                          style: AppTypography.title2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(S.homeRemainingVolume,
                        style: AppTypography.micro
                            .copyWith(color: colors.textTertiary),
                        textDirection: TextDirection.rtl),
                  ],
                ),
                const SizedBox(width: 12),
                MiniCircularGauge(
                  progress: (state.remainingGb / 58.0).clamp(0.0, 1.0),
                  gaugeType: GaugeType.volume,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(S.homeDay,
                            style: AppTypography.caption
                                .copyWith(color: colors.textSecondary)),
                        const SizedBox(width: 4),
                        GradientText(
                          text: state.remainingDays.toFa(),
                          style: AppTypography.title2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(S.homeRemainingTime,
                        style: AppTypography.micro
                            .copyWith(color: colors.textTertiary),
                        textDirection: TextDirection.rtl),
                  ],
                ),
                const SizedBox(width: 12),
                MiniCircularGauge(
                  progress: (state.remainingDays / 140.0).clamp(0.0, 1.0),
                  gaugeType: GaugeType.time,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Active Server Card
// ═══════════════════════════════════════════════════════════════════════════════

class _ActiveServerCard extends StatelessWidget {
  const _ActiveServerCard({required this.server, required this.colors});
  final ServerLocation server;
  final AppColors      colors;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      onTap: () => context.go(AppRoutes.servers),
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            Icon(Icons.chevron_left_rounded,
                color: colors.textTertiary, size: 22),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (server.badge == ServerBadge.b) ...[
                  const StatusBadge(type: BadgeType.b),
                  const SizedBox(width: 8),
                ],
                Text(server.name,
                    style: AppTypography.body
                        .copyWith(color: colors.textPrimary),
                    textDirection: TextDirection.rtl),
              ],
            ),
            const SizedBox(width: 14),
            Text(server.flagEmoji,
                style: const TextStyle(fontSize: 32),
                textDirection: TextDirection.ltr),
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
