import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';
import '../theme/typography.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: colors.blue.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              child: Row(
                children: [
                  // ── Chevron (RTL arrow pointing left = towards content) ──
                  if (onTap != null && trailing == null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: colors.textTertiary,
                        size: 22,
                      ),
                    ),

                  // ── Trailing control ───────────────────────────────────
                  if (trailing != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: trailing!,
                    ),

                  // ── Text block ─────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          title,
                          style: AppTypography.title3
                              .copyWith(color: colors.textPrimary),
                          textDirection: TextDirection.rtl,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: AppTypography.caption
                                .copyWith(color: colors.textSecondary),
                            textDirection: TextDirection.rtl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // ── Icon tile ──────────────────────────────────────────
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Divider ──────────────────────────────────────────────────────
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, thickness: 1, color: colors.divider),
          ),
      ],
    );
  }
}
