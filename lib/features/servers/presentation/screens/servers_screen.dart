import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/persian_digits.dart';
import '../../../../core/widgets/circle_icon_button.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/server_tile.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/server_models.dart';
import '../../providers/servers_provider.dart';
import '../../../home/providers/home_provider.dart';

class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(serversProvider);
    final colors = Theme.of(context).extension<AppColors>()!;

    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ServersAppBar(state: state, colors: colors),
            Expanded(
              child: state.isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: ShimmerList(count: 6),
                    )
                  : state.errorMessage != null
                      ? _ErrorView(
                          message: state.errorMessage!,
                          onRetry: () =>
                              ref.read(serversProvider.notifier).loadServers(),
                        )
                      : _ServersList(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────
class _ServersAppBar extends ConsumerWidget {
  const _ServersAppBar({required this.state, required this.colors});
  final ServersState state;
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPinging   = state.isPinging;
    final isRefreshing = state.isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          // Refresh ping
          CircleIconButton(
            icon: Icons.network_ping_rounded,
            isLoading: isPinging,
            onTap: () {
              AppHaptics.light();
              ref.read(serversProvider.notifier).fetchPings();
            },
            tooltip: 'بررسی پینگ',
          ),
          const SizedBox(width: 10),
          // Refresh servers
          CircleIconButton(
            icon: Icons.refresh_rounded,
            isLoading: isRefreshing,
            onTap: () {
              AppHaptics.light();
              ref.read(serversProvider.notifier).refresh();
            },
            tooltip: S.serversRefresh,
          ),
          const Spacer(),
          // Title + subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                S.serversTitle,
                style: AppTypography.title1.copyWith(color: colors.textPrimary),
                textDirection: TextDirection.rtl,
              ),
              if (!state.isLoading && state.groups.isNotEmpty)
                Text(
                  '${state.totalServers.toFa()} ${S.serversSubtitle}',
                  style: AppTypography.caption
                      .copyWith(color: colors.textSecondary),
                  textDirection: TextDirection.rtl,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Servers list ─────────────────────────────────────────────────────────────
class _ServersList extends ConsumerWidget {
  const _ServersList({required this.state});
  final ServersState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // پینگ بهترین سرور برای SmartServerTile
    final bestServer = ref.watch(serversProvider.notifier).bestServer;
    final bestPing   = bestServer != null ? state.pingOf(bestServer.id) : 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: [
        // Smart server
        SmartServerTile(
          isSelected:  state.selectedServerId == 'smart' || state.selectedServerId == null,
          bestPingMs:  bestPing,
          onTap: () {
            AppHaptics.selection();
            ref.read(serversProvider.notifier).selectSmart();
            // اگه وصل بود با سرور هوشمند reconnect کن
            _connectIfNeeded(ref, context, isSmart: true);
          },
        ),
        const SizedBox(height: 14),

        // Country groups
        ...state.groups.map((group) {
          final isExpanded  = state.expandedGroupId == group.id;
          final anySelected = group.locations
              .any((l) => l.id == state.selectedServerId);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ServerGroupTile(
              group:      group,
              isExpanded: isExpanded,
              isSelected: anySelected,
              onToggle: () {
                AppHaptics.light();
                ref.read(serversProvider.notifier).toggleGroup(group.id);
              },
              onSelect: () {},
              children: group.locations.map((loc) {
                final ping = state.pingOf(loc.id);
                return ServerLocationTile(
                  location:   loc,
                  isSelected: state.selectedServerId == loc.id,
                  pingMs:     ping,
                  onTap: () {
                    AppHaptics.selection();
                    ref.read(serversProvider.notifier).selectServer(loc.id);
                    // مستقیم connect می‌کنیم
                    _connectServer(ref, context, loc);
                  },
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  // کلیک روی سرور → مستقیم connect
  void _connectServer(WidgetRef ref, BuildContext context, ServerItem server) {
    ref.read(homeProvider.notifier).connectToServer(server);
  }

  void _connectIfNeeded(WidgetRef ref, BuildContext context, {bool isSmart = false}) {
    ref.read(homeProvider.notifier).connectSmart();
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, color: colors.textTertiary, size: 48),
          const SizedBox(height: 16),
          Text(
            S.errorNetwork,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onRetry,
            child: Text(
              S.retry,
              style: AppTypography.body.copyWith(color: colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
