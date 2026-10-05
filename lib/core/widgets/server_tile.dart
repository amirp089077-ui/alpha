import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';
import '../theme/typography.dart';
import 'glass_card.dart';
import 'status_badge.dart';
import '../../features/servers/data/models/server_models.dart';

/// Top-level server group row (country + location count)
class ServerGroupTile extends StatelessWidget {
  const ServerGroupTile({
    super.key,
    required this.group,
    required this.isExpanded,
    required this.isSelected,
    required this.onToggle,
    required this.onSelect,
    this.children = const [],
  });

  final ServerGroup group;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onSelect;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      children: [
        GlassCard(
          selected: isSelected,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          onTap: onToggle,
          child: SizedBox(
            height: 78,
            child: Row(
              children: [
                // ── Expand chevron (RTL: points left when collapsed) ───
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: colors.textSecondary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // ── Country name + location chip ───────────────────────
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (group.isSpecial)
                            const Text('✦ ', style: TextStyle(fontSize: 14)),
                          Text(
                            group.country,
                            style: AppTypography.title2
                                .copyWith(color: colors.textPrimary),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(width: 8),
                          // ping star icon
                          const Text('✦', style: TextStyle(color: Color(0xFFF0693A), fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _LocationChip(
                          count: group.locations.length,
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // ── Flag ───────────────────────────────────────────────
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: Text(
                    group.isSpecial ? '🌐' : group.flagEmoji,
                    style: const TextStyle(fontSize: 32),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Expanded location children ─────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16),
                  child: Column(children: children),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Individual location row inside an expanded group
class ServerLocationTile extends StatelessWidget {
  const ServerLocationTile({
    super.key,
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  final ServerLocation location;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GlassCard(
        selected: isSelected,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        onTap: onTap,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              // Radio indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colors.blue : colors.textTertiary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.blue,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Name + badge
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (location.badge == ServerBadge.b) ...[
                      const StatusBadge(type: BadgeType.b),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      location.name,
                      style: AppTypography.body.copyWith(color: colors.textPrimary),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Flag
              Text(
                location.flagEmoji,
                style: const TextStyle(fontSize: 28),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Smart server tile (gradient border)
class SmartServerTile extends StatelessWidget {
  const SmartServerTile({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GlassCard(
      gradientBorder: true,
      borderWidth: 1.5,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
      child: SizedBox(
        height: 78,
        child: Row(
          children: [
            // Radio
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.blue : colors.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.blue,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'سرور هوشمند',
                    style: AppTypography.title2.copyWith(color: colors.textPrimary),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اتصال خودکار به کمترین پینگ',
                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Smart icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: colors.brandGradient,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.count, required this.colors});
  final int count;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${count.toString()} لوکیشن',
        style: AppTypography.caption.copyWith(color: colors.chipText),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
