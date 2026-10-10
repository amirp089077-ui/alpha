import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/theme/typography.dart';
import '../../data/models/notification_models.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(notificationsProvider);
    final colors = Theme.of(context).extension<AppColors>()!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: colors.isLight ? Brightness.dark : Brightness.light,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: colors.bgBase,
          appBar: _NotifAppBar(colors: colors, state: state),
          body: _buildBody(state, colors),
        ),
      ),
    );
  }

  Widget _buildBody(NotificationsState state, AppColors colors) {
    if (state.status == NotifStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == NotifStatus.error) {
      return _ErrorView(
        message: state.errorMessage ?? 'خطا در دریافت اطلاعیه‌ها',
        onRetry: () => ref.read(notificationsProvider.notifier).fetch(),
        colors: colors,
      );
    }
    if (state.items.isEmpty) {
      return _EmptyView(colors: colors);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationsProvider.notifier).fetch(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildCard(state.items[i], colors),
      ),
    );
  }

  Widget _buildCard(AppNotification n, AppColors colors) {
    switch (n.type) {
      case NotifType.broadcast:
        return _BroadcastCard(n: n, colors: colors);
      case NotifType.offer:
        return _OfferCard(n: n, colors: colors);
      case NotifType.tip:
        return _TipCard(n: n, colors: colors);
      case NotifType.warning:
        return _ToneCard(n: n, colors: colors,
            accent: AppColorsShared.orange,
            icon: Icons.warning_amber_rounded,
            gradientColors: [const Color(0xFFFFF3E0), const Color(0xFFFFF8F0)]);
      case NotifType.error:
        return _ToneCard(n: n, colors: colors,
            accent: AppColorsShared.red,
            icon: Icons.error_outline_rounded,
            gradientColors: [const Color(0xFFFFEBEE), const Color(0xFFFFF5F5)]);
      case NotifType.success:
        return _ToneCard(n: n, colors: colors,
            accent: const Color(0xFF22C55E),
            icon: Icons.check_circle_outline_rounded,
            gradientColors: [const Color(0xFFE8F5E9), const Color(0xFFF1FFF3)]);
      default:
        return _AnnouncementCard(n: n, colors: colors);
    }
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _NotifAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _NotifAppBar({required this.colors, required this.state});
  final AppColors        colors;
  final NotificationsState state;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor:  colors.bgBase,
      elevation:        0,
      centerTitle:      true,
      leading: IconButton(
        icon: Icon(Icons.arrow_forward_ios_rounded, color: colors.textPrimary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('اطلاعیه‌ها',
              style: AppTypography.title2.copyWith(color: colors.textPrimary)),
          if (state.unreadCount > 0)
            Text('${state.unreadCount} مورد خوانده‌نشده',
                style: AppTypography.micro.copyWith(color: AppColorsLight.teal)),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: colors.textSecondary),
          onPressed: () => ref.read(notificationsProvider.notifier).fetch(),
        ),
      ],
    );
  }
}

// ── Broadcast Card (پین‌شده — گرادیان کامل) ──────────────────────────────────

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard({required this.n, required this.colors});
  final AppNotification n;
  final AppColors       colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0F6FDE)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.campaign_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text('اطلاعیه رسمی',
                          style: AppTypography.micro.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Spacer(),
                if (n.isNew)
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(n.title,
                style: AppTypography.title2.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(n.body,
                style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.9), height: 1.6)),
            if (n.actionUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ActionButton(
                label: n.actionLabel.isNotEmpty ? n.actionLabel : 'مشاهده بیشتر',
                url:   n.actionUrl,
                light: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Offer Card (پیشنهاد ویژه — گرادیان طلایی) ────────────────────────────────

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.n, required this.colors});
  final AppNotification n;
  final AppColors       colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // دایره تزئینی پس‌زمینه
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text('پیشنهاد ویژه',
                              style: AppTypography.micro.copyWith(
                                  color: Colors.white, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    if (n.discount.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${n.discount}٪ تخفیف',
                            style: AppTypography.micro.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ],
                    const Spacer(),
                    if (n.expiresAt.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
                          const SizedBox(width: 3),
                          Text(n.expiresAt,
                              style: AppTypography.micro.copyWith(
                                  color: Colors.white70)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(n.title,
                    style: AppTypography.title2.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(n.body,
                    style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.9), height: 1.6)),
                if (n.actionUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ActionButton(
                    label: n.actionLabel.isNotEmpty ? n.actionLabel : 'خرید اشتراک',
                    url:   n.actionUrl,
                    light: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tip Card (نکته آموزشی — آبی روشن) ────────────────────────────────────────

class _TipCard extends StatelessWidget {
  const _TipCard({required this.n, required this.colors});
  final AppNotification n;
  final AppColors       colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colors.card,
        border: Border.all(
          color: AppColorsLight.teal.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColorsLight.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('💡', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(n.title,
                          style: AppTypography.body.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColorsLight.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('نکته',
                            style: AppTypography.micro.copyWith(
                                color: AppColorsLight.teal,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(n.body,
                      style: AppTypography.caption.copyWith(
                          color: colors.textSecondary, height: 1.6)),
                  if (n.actionUrl.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _ActionButton(label: n.actionLabel.isNotEmpty ? n.actionLabel : 'بیشتر بدان', url: n.actionUrl),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tone Card (warning / error / success) ────────────────────────────────────

class _ToneCard extends StatelessWidget {
  const _ToneCard({
    required this.n,
    required this.colors,
    required this.accent,
    required this.icon,
    required this.gradientColors,
  });
  final AppNotification n;
  final AppColors       colors;
  final Color           accent;
  final IconData        icon;
  final List<Color>     gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(n.title,
                            style: AppTypography.body.copyWith(
                                color: const Color(0xFF1A1A2E),
                                fontWeight: FontWeight.w700)),
                      ),
                      if (n.isNew)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: accent),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(n.body,
                      style: AppTypography.caption.copyWith(
                          color: const Color(0xFF4A4A6A), height: 1.6)),
                  if (n.expiresAt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 12, color: accent.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(n.expiresAt,
                            style: AppTypography.micro.copyWith(color: accent.withValues(alpha: 0.7))),
                      ],
                    ),
                  ],
                  if (n.actionUrl.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _ActionButton(label: n.actionLabel.isNotEmpty ? n.actionLabel : 'مشاهده', url: n.actionUrl, accent: accent),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Announcement Card (عمومی) ─────────────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.n, required this.colors});
  final AppNotification n;
  final AppColors       colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColorsLight.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.notifications_rounded,
                      color: AppColorsLight.teal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(n.title,
                      style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700)),
                ),
                if (n.isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColorsLight.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('جدید',
                        style: AppTypography.micro.copyWith(
                            color: AppColorsLight.teal,
                            fontWeight: FontWeight.w700)),
                  ),
                if (n.badge.isNotEmpty && !n.isNew) ...[
                  const SizedBox(width: 6),
                  Text(n.badge, style: const TextStyle(fontSize: 16)),
                ],
              ],
            ),
            if (n.body.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(n.body,
                  style: AppTypography.caption.copyWith(
                      color: colors.textSecondary, height: 1.6)),
            ],
            if (n.expiresAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 13, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text(n.expiresAt,
                      style: AppTypography.micro.copyWith(color: colors.textTertiary)),
                ],
              ),
            ],
            if (n.actionUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ActionButton(label: n.actionLabel.isNotEmpty ? n.actionLabel : 'مشاهده', url: n.actionUrl),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.url, this.light = false, this.accent});
  final String  label;
  final String  url;
  final bool    light;
  final Color?  accent;

  @override
  Widget build(BuildContext context) {
    final bg = light
        ? Colors.white.withValues(alpha: 0.25)
        : (accent ?? AppColorsLight.teal).withValues(alpha: 0.12);
    final fg = light ? Colors.white : (accent ?? AppColorsLight.teal);

    return GestureDetector(
      onTap: () => _launch(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(12),
          border: light ? Border.all(color: Colors.white.withValues(alpha: 0.4)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppTypography.caption.copyWith(
                    color: fg, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Icon(Icons.arrow_back_ios_rounded, size: 12, color: fg),
          ],
        ),
      ),
    );
  }

  void _launch(String url) {
    try {
      const ch = MethodChannel('alpha_vpn/launcher');
      ch.invokeMethod('openUrl', {'url': url});
    } catch (_) {}
  }
}

// ── Empty & Error ─────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColorsLight.teal.withValues(alpha: 0.08),
            ),
            child: Icon(Icons.notifications_none_rounded,
                size: 44, color: AppColorsLight.teal.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text('اطلاعیه‌ای وجود ندارد',
              style: AppTypography.body.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 6),
          Text('هنوز هیچ اعلانی برای شما ارسال نشده',
              style: AppTypography.caption.copyWith(color: colors.textTertiary)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry, required this.colors});
  final String       message;
  final VoidCallback onRetry;
  final AppColors    colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 56, color: colors.textTertiary),
          const SizedBox(height: 12),
          Text(message,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }
}
