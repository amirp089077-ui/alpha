import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/persian_digits.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/circle_icon_button.dart';
import '../../../../core/widgets/circular_gauge.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/subscription_models.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionProvider);
    final colors = Theme.of(context).extension<AppColors>()!;

    // Snackbar feedback for gift code
    ref.listen(subscriptionProvider, (_, next) {
      if (next.giftCodeResult == 'success') {
        AppSnackBar.show(context, S.subGiftCodeSuccess,
            type: SnackBarType.success);
      } else if (next.giftCodeResult == 'error') {
        AppSnackBar.show(context, S.subGiftCodeError, type: SnackBarType.error);
      }
    });

    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _SubAppBar(colors: colors, onRefresh: () {
              AppHaptics.light();
              ref.read(subscriptionProvider.notifier).load();
            }),
            Expanded(
              child: state.isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(children: [
                        SizedBox(height: 16),
                        ShimmerSkeleton(height: 180, radius: 28),
                        SizedBox(height: 16),
                        ShimmerSkeleton(height: 200, radius: 28),
                        SizedBox(height: 16),
                        ShimmerSkeleton(height: 68, radius: 28),
                      ]),
                    )
                  : state.subscription == null
                      ? const SizedBox.shrink()
                      : _SubContent(sub: state.subscription!, state: state),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubAppBar extends StatelessWidget {
  const _SubAppBar({required this.colors, required this.onRefresh});
  final AppColors colors;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.refresh_rounded,
            onTap: onRefresh,
            tooltip: S.subRefresh,
          ),
          const Spacer(),
          Text(
            S.subTitle,
            style: AppTypography.title1.copyWith(color: colors.textPrimary),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

// ─── Main content ─────────────────────────────────────────────────────────────
class _SubContent extends ConsumerWidget {
  const _SubContent({required this.sub, required this.state});
  final SubscriptionModel sub;
  final SubscriptionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        // ── Two gauge cards ─────────────────────────────────────────────
        Row(
          children: [
            // Time gauge
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  children: [
                    CircularGauge(
                      progress: sub.timeProgress,
                      centerValue: sub.remainingDays.toFa(),
                      centerUnit: S.subDay,
                      gaugeType: GaugeType.time,
                      isLow: sub.isLowTime,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      S.subRemainingTime,
                      style: AppTypography.caption
                          .copyWith(color: colors.textPrimary),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${S.subFrom} ${sub.totalDays.toFa()} ${S.subDay}',
                      style: AppTypography.micro
                          .copyWith(color: colors.textSecondary),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Volume gauge
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  children: [
                    CircularGauge(
                      progress: sub.volumeProgress,
                      centerValue: sub.remainingGb.toFaDecimal(digits: 1),
                      centerUnit: S.subGig,
                      gaugeType: GaugeType.volume,
                      isLow: sub.isLowVolume,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      S.subRemainingVolume,
                      style: AppTypography.caption
                          .copyWith(color: colors.textPrimary),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${S.subFrom} ${sub.totalGb.toFaDecimal(digits: 0)} ${S.subGig}',
                      style: AppTypography.micro
                          .copyWith(color: colors.textSecondary),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Detail rows card ────────────────────────────────────────────
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              _DetailRow(
                label: S.subTotalUsage,
                value: formatGbFa(sub.usedGb),
                dotColor: colors.blue,
              ),
              _DetailRow(
                label: S.subTotalVolume,
                value: formatGbFa(sub.totalGb),
                dotColor: colors.mint,
              ),
              _DetailRow(
                label: S.subPurchasedDays,
                value: formatDaysFa(sub.totalDays),
                dotColor: colors.blue,
              ),
              _DetailRow(
                label: S.subRemainingDays,
                value: formatDaysFa(sub.remainingDays),
                dotColor: colors.green,
              ),
              _DetailRow(
                label: S.subExpiry,
                value: formatJalaliDate(sub.expiryDate),
                dotColor: colors.orange,
                showDivider: false,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Gift code accordion ─────────────────────────────────────────
        _GiftCodeCard(state: state),
      ],
    );
  }
}

// ─── Detail row ───────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.dotColor,
    this.showDivider = true,
  });
  final String label;
  final String value;
  final Color dotColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              // Value (LTR numbers)
              Text(
                value,
                style: AppTypography.title3.copyWith(color: colors.textPrimary),
                textDirection: TextDirection.rtl,
              ),
              const Spacer(),
              // Label + dot
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.body
                        .copyWith(color: colors.textSecondary),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: colors.divider),
      ],
    );
  }
}

// ─── Gift code accordion ──────────────────────────────────────────────────────
class _GiftCodeCard extends ConsumerStatefulWidget {
  const _GiftCodeCard({required this.state});
  final SubscriptionState state;

  @override
  ConsumerState<_GiftCodeCard> createState() => _GiftCodeCardState();
}

class _GiftCodeCardState extends ConsumerState<_GiftCodeCard> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final expanded = widget.state.giftCodeExpanded;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header row
          GestureDetector(
            onTap: () =>
                ref.read(subscriptionProvider.notifier).toggleGiftCode(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: colors.textSecondary, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    S.subGiftCode,
                    style: AppTypography.title3
                        .copyWith(color: colors.textPrimary),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.iconTileOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.card_giftcard_rounded,
                        color: colors.orange, size: 20),
                  ),
                ],
              ),
            ),
          ),

          // Expandable body
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        Divider(height: 1, color: colors.divider),
                        const SizedBox(height: 16),
                        // Code input
                        Container(
                          decoration: BoxDecoration(
                            color: colors.isLight
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: colors.fieldBorder, width: 1),
                          ),
                          child: TextField(
                            controller: _codeCtrl,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.center,
                            style: AppTypography.body
                                .copyWith(color: colors.textPrimary),
                            decoration: InputDecoration(
                              hintText: S.subGiftCodeHint,
                              hintStyle: AppTypography.body
                                  .copyWith(color: colors.textTertiary),
                              hintTextDirection: TextDirection.rtl,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GradientButton(
                          label: S.subGiftCodeSubmit,
                          onPressed: () {
                            if (_codeCtrl.text.trim().isNotEmpty) {
                              ref
                                  .read(subscriptionProvider.notifier)
                                  .redeemGiftCode(_codeCtrl.text.trim());
                            }
                          },
                          isLoading: widget.state.giftCodeLoading,
                          height: 48,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
