import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/persian_digits.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/settings_tile.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/settings_models.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final colors = Theme.of(context).extension<AppColors>()!;
    final user = authState.user;

    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 100 + MediaQuery.of(context).padding.bottom),
          children: [
            // ── Page title ──────────────────────────────────────────────
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                S.settingsTitle,
                style: AppTypography.title1.copyWith(color: colors.textPrimary),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 20),

            // ── Profile card ────────────────────────────────────────────
            GlassCard(
              borderColor: colors.cardBorderStrong,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Device row
                  Row(
                    children: [
                      // Logo mark
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: colors.cardBorderStrong, width: 1.5),
                          color: colors.card,
                        ),
                        child: const Center(
                          child: Text('✦', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const Spacer(),
                      // Device info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            user?.deviceName ?? 'poco i',
                            style: AppTypography.title3
                                .copyWith(color: colors.textPrimary),
                            textDirection: TextDirection.ltr,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user != null
                                    ? user.deviceId.digitsToFa()
                                    : '۳۶۹۶',
                                style: AppTypography.caption.copyWith(
                                    color: colors.textSecondary),
                                textDirection: TextDirection.ltr,
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.phone_android_rounded,
                                  size: 14, color: colors.textTertiary),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(height: 1, color: colors.divider),
                  const SizedBox(height: 12),

                  // Username row
                  Row(
                    children: [
                      // Username chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.chipBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?.username ?? 'mehdi06',
                          style: AppTypography.body
                              .copyWith(color: colors.chipText),
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                      const Spacer(),
                      // Label
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            S.settingsUsername,
                            style: AppTypography.body
                                .copyWith(color: colors.textSecondary),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.alternate_email_rounded,
                              size: 16, color: colors.textTertiary),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Section: Appearance ─────────────────────────────────────
            _SectionHeader(label: S.settingsAppearance, colors: colors),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SettingsTile(
                    icon: Icons.dark_mode_rounded,
                    iconColor: colors.orange,
                    iconBgColor: colors.iconTileOrange,
                    title: S.settingsDisplayMode,
                    trailing: const SizedBox.shrink(),
                    showDivider: false,
                  ),
                  const SizedBox(height: 4),
                  _ThemeSegment(current: settings.themeMode),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Section: Connection ─────────────────────────────────────
            _SectionHeader(label: S.settingsConnection, colors: colors),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  // Whitelist
                  SettingsTile(
                    icon: Icons.apps_rounded,
                    iconColor: colors.blue,
                    iconBgColor: colors.iconTileBlue,
                    title: S.settingsWhitelist,
                    subtitle: S.settingsWhitelistSub,
                    onTap: () => context.push(AppRoutes.whitelist),
                  ),

                  // Bypass Iran
                  SettingsTile(
                    icon: Icons.flag_rounded,
                    iconColor: colors.green,
                    iconBgColor: colors.iconTileGreen,
                    title: S.settingsDirectIran,
                    subtitle: S.settingsDirectIranSub,
                    trailing: Switch(
                      value: settings.bypassIranSites,
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).toggleBypassIran(v),
                    ),
                  ),

                  // Ad block
                  SettingsTile(
                    icon: Icons.block_rounded,
                    iconColor: colors.red,
                    iconBgColor: colors.iconTileRed,
                    title: S.settingsAdBlock,
                    subtitle: S.settingsAdBlockSub,
                    showDivider: false,
                    trailing: Switch(
                      value: settings.adBlock,
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).toggleAdBlock(v),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Logout ──────────────────────────────────────────────────
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SettingsTile(
                icon: Icons.logout_rounded,
                iconColor: colors.red,
                iconBgColor: colors.iconTileRed,
                title: S.settingsLogout,
                showDivider: false,
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          S.settingsLogout,
          style: AppTypography.title2.copyWith(color: colors.textPrimary),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          S.settingsLogoutConfirm,
          style: AppTypography.body.copyWith(color: colors.textSecondary),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.settingsLogoutNo,
                style: AppTypography.body.copyWith(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.settingsLogoutYes,
                style: AppTypography.body.copyWith(color: colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.colors});
  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: colors.textSecondary),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(width: 6),
        Icon(Icons.keyboard_arrow_down_rounded,
            color: colors.textTertiary, size: 18),
      ],
    );
  }
}

// ─── Theme segment control ────────────────────────────────────────────────────
class _ThemeSegment extends ConsumerWidget {
  const _ThemeSegment({required this.current});
  final ThemeMode2 current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final options = [
      (ThemeMode2.auto, S.settingsThemeAuto),
      (ThemeMode2.light, S.settingsThemeLight),
      (ThemeMode2.dark, S.settingsThemeDark),
    ];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.isLight
            ? const Color(0xFFEDF3F7)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt.$1 == current;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(settingsProvider.notifier).setTheme(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: isSelected ? colors.brandGradient : null,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Text(
                  opt.$2,
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? Colors.white
                        : colors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
