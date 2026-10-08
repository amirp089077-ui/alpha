import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/persian_digits.dart';
import '../../../../core/widgets/app_logo_mark.dart';
import '../../../../core/widgets/circle_icon_button.dart';
import '../../../../core/widgets/circular_gauge.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/home_models.dart';
import '../../providers/home_provider.dart';
import '../../../servers/data/models/server_models.dart';
import '../../../servers/providers/servers_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final colors = Theme.of(context).extension<AppColors>()!;

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
                padding: EdgeInsets.fromLTRB(20, 0, 20, 100 + MediaQuery.of(context).padding.bottom),
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
                      _ActiveServerCard(server: state.activeServer!, colors: colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────
class _HomeAppBar extends ConsumerWidget {
  const _HomeAppBar({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPinging = ref.watch(serversProvider).isPinging;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // دکمه سرورها
          CircleIconButton(
            icon: Icons.dns_rounded,
            onTap: () => context.go(AppRoutes.servers),
            tooltip: 'سرورها',
          ),
          const SizedBox(width: 10),
          // دکمه ping
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
          // ALPHA VPN logotype (LTR)
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
                        style: AppTypography.logoLatinSmall.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: 'VPN',
                        style: AppTypography.logoLatinSmall.copyWith(
                          color: colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Orb / connect button ─────────────────────────────────────────────────────
class _OrbSection extends ConsumerWidget {
  const _OrbSection({required this.state, required this.colors});
  final HomeState state;
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = state.isConnected;
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
            // Outer orbit ring
            _OrbitRing(
              isConnected: isConnected,
              colors: colors,
            ),

            // Inner frosted orb
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
                        )
                      ]
                    : [
                        BoxShadow(
                          color: colors.blue.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 4,
                        )
                      ],
              ),
            ),

            // Logo mark in center
            AppLogoMark(
              size: 130,
              ringWidth: 2,
              showGlow: isConnected,
            ),

            // Loading overlay
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

// ─── Animated orbit ring ──────────────────────────────────────────────────────
class _OrbitRing extends StatefulWidget {
  const _OrbitRing({required this.isConnected, required this.colors});
  final bool isConnected;
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
    if (MediaQuery.of(context).disableAnimations) {
      return _buildRingStatic();
    }
    return TickerMode(
      enabled: true,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.rotate(
          angle: _ctrl.value * 2 * 3.14159,
          child: _buildRingStatic(),
        ),
      ),
    );
  }

  Widget _buildRingStatic() {
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
          // Small dot on the ring
          Positioned(
            top: 12,
            right: 80,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isConnected ? widget.colors.mint : widget.colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isConnected ? widget.colors.mint : widget.colors.blue)
                        .withValues(alpha: 0.8),
                    blurRadius: 6,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status text ──────────────────────────────────────────────────────────────
class _StatusText extends StatelessWidget {
  const _StatusText({required this.state, required this.colors});
  final HomeState state;
  final AppColors colors;

  String get _statusLabel {
    switch (state.vpnStatus) {
      case VpnStatus.connected:     return S.homeConnected;
      case VpnStatus.connecting:    return S.homeConnecting;
      case VpnStatus.disconnecting: return S.homeDisconnecting;
      case VpnStatus.disconnected:  return S.homeNotConnected;
      case VpnStatus.error:         return state.errorMessage ?? 'خطا در اتصال';
    }
  }

  Color _statusColor(AppColors c) {
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
        // Status label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            key: ValueKey(state.vpnStatus),
            _statusLabel,
            style: AppTypography.status.copyWith(color: _statusColor(colors)),
            textDirection: TextDirection.rtl,
          ),
        ),

        // Timer (only when connected)
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
          // Server info
          if (state.activeServer != null)
            Directionality(
              textDirection: TextDirection.rtl,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTypography.body.copyWith(color: colors.textSecondary),
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
                      // pingMs == 0 یعنی هنوز اولین ping نگرفتیم → نقطه‌چین
                      // pingMs == -1 یعنی timeout/error → قرمز
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
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
            textDirection: TextDirection.rtl,
          ),
        ],

        if (!state.isConnected && !state.isConnecting && !state.isDisconnecting) ...[
          const SizedBox(height: 8),
          Text(
            S.homeTapToConnect,
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
            textDirection: TextDirection.rtl,
          ),
        ],
      ],
    );
  }
}

// ─── Stats row (remaining days + volume) ─────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state, required this.colors});
  final HomeState state;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final volumeProgress = state.remainingGb / 58.0;
    final timeProgress = state.remainingDays / 140.0;

    return Row(
      children: [
        // Volume remaining
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          S.homeGig,
                          style: AppTypography.caption.copyWith(
                              color: colors.textSecondary),
                        ),
                        const SizedBox(width: 4),
                        GradientText(
                          text: state.remainingGb.toFaDecimal(digits: 1),
                          style: AppTypography.title2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.homeRemainingVolume,
                      style: AppTypography.micro.copyWith(
                          color: colors.textTertiary),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                MiniCircularGauge(
                  progress: volumeProgress.clamp(0.0, 1.0),
                  gaugeType: GaugeType.volume,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Days remaining
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          S.homeDay,
                          style: AppTypography.caption.copyWith(
                              color: colors.textSecondary),
                        ),
                        const SizedBox(width: 4),
                        GradientText(
                          text: state.remainingDays.toFa(),
                          style: AppTypography.title2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.homeRemainingTime,
                      style: AppTypography.micro.copyWith(
                          color: colors.textTertiary),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                MiniCircularGauge(
                  progress: timeProgress.clamp(0.0, 1.0),
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

// ─── Active server card ───────────────────────────────────────────────────────
class _ActiveServerCard extends StatelessWidget {
  const _ActiveServerCard({required this.server, required this.colors});
  final ServerLocation server;
  final AppColors colors;

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
                Text(
                  server.name,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                  textDirection: TextDirection.rtl,
                ),
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
