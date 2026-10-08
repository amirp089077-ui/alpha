import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/l10n/strings.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/theme/typography.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/gradient_background.dart';
import '../../../../../core/widgets/shimmer_skeleton.dart';
import '../../../../settings/data/models/settings_models.dart';
import '../../../../settings/providers/settings_provider.dart';

class WhitelistScreen extends ConsumerStatefulWidget {
  const WhitelistScreen({super.key});

  @override
  ConsumerState<WhitelistScreen> createState() => _WhitelistScreenState();
}

class _WhitelistScreenState extends ConsumerState<WhitelistScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final appsAsync = ref.watch(whitelistAppsProvider);
    final colors = Theme.of(context).extension<AppColors>()!;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── App bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_forward_ios_rounded,
                          color: colors.textPrimary, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      S.whitelistTitle,
                      style: AppTypography.title2
                          .copyWith(color: colors.textPrimary),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Search bar ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.cardBorder),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    textDirection: TextDirection.rtl,
                    style: AppTypography.body
                        .copyWith(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: S.whitelistSearch,
                      hintStyle: AppTypography.body
                          .copyWith(color: colors.textTertiary),
                      hintTextDirection: TextDirection.rtl,
                      prefixIcon: Icon(Icons.search_rounded,
                          color: colors.textTertiary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Select all / deselect all ────────────────────────────
              appsAsync.when(
                data: (apps) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => ref
                            .read(settingsProvider.notifier)
                            .deselectAllApps(),
                        child: Text(S.whitelistDeselectAll,
                            style: AppTypography.caption
                                .copyWith(color: colors.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => ref
                            .read(settingsProvider.notifier)
                            .selectAllApps(
                                apps.map((a) => a.packageName).toList()),
                        child: Text(S.whitelistSelectAll,
                            style: AppTypography.caption
                                .copyWith(color: colors.blue)),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // ── App list ─────────────────────────────────────────────
              Expanded(
                child: appsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: ShimmerList(count: 8),
                  ),
                  error: (e, _) => Center(
                    child: Text(S.errorUnknown,
                        style: AppTypography.body
                            .copyWith(color: colors.textSecondary),
                        textDirection: TextDirection.rtl),
                  ),
                  data: (apps) {
                    final filtered = _query.isEmpty
                        ? apps
                        : apps
                            .where((a) =>
                                a.appName
                                    .toLowerCase()
                                    .contains(_query) ||
                                a.packageName.contains(_query))
                            .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(S.whitelistEmpty,
                            style: AppTypography.body
                                .copyWith(color: colors.textTertiary),
                            textDirection: TextDirection.rtl),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 100 + MediaQuery.of(context).padding.bottom),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final app = filtered[i];
                        final isChecked = settings.whitelistedApps
                            .contains(app.packageName);
                        return _AppTile(
                          app: app,
                          isChecked: isChecked,
                          onTap: () => ref
                              .read(settingsProvider.notifier)
                              .toggleWhitelistApp(app.packageName),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({
    required this.app,
    required this.isChecked,
    required this.onTap,
  });
  final AppInfo app;
  final bool isChecked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          // Checkbox
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: isChecked ? colors.blue : Colors.transparent,
              border: Border.all(
                color: isChecked ? colors.blue : colors.textTertiary,
                width: 1.5,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16)
                : null,
          ),
          const Spacer(),
          // App name + package name
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                app.appName,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
                textDirection: TextDirection.rtl,
              ),
              Text(
                app.packageName,
                style: AppTypography.micro.copyWith(color: colors.textTertiary),
                textDirection: TextDirection.ltr,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(width: 12),
          // آیکون واقعی یا fallback به حرف اول
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: app.iconBytes != null
                ? Image.memory(
                    app.iconBytes!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _FallbackIcon(
                      app: app,
                      colors: colors,
                    ),
                  )
                : _FallbackIcon(app: app, colors: colors),
          ),
        ],
      ),
    );
  }
}

// ── Fallback icon — حرف اول اسم برنامه ────────────────────────────────────────
class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.app, required this.colors});
  final AppInfo app;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.iconTileBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
          style: AppTypography.title3.copyWith(color: colors.blue),
        ),
      ),
    );
  }
}
