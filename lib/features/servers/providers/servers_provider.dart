import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/vpn_service.dart';
import '../data/models/server_models.dart';
import '../data/repository/servers_repository.dart';

// ── Repository + VpnService providers ─────────────────────

final serversRepositoryProvider = Provider<ServersRepository>(
  (_) => ServersRepository(),
);

final _vpnServiceProvider = Provider<VpnService>((_) => VpnService());

// ── Notifier ───────────────────────────────────────────────

class ServersNotifier extends StateNotifier<ServersState> {
  final ServersRepository _repo;
  final VpnService        _vpn;

  ServersNotifier(this._repo, this._vpn) : super(const ServersState()) {
    loadServers();
  }

  // ── Load ─────────────────────────────────────────────────

  Future<void> loadServers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final groups = await _repo.fetchServers();
      state = state.copyWith(isLoading: false, groups: groups);
      // بعد از لود، پینگ همه رو بگیر
      fetchPings();
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'خطا در دریافت سرورها');
    }
  }

  Future<void> refresh() => loadServers();

  // ── Ping همه سرورها به صورت موازی ────────────────────────

  Future<void> fetchPings() async {
    if (state.groups.isEmpty) return;

    state = state.copyWith(isPinging: true);

    // Map<serverId, configUri>
    final Map<String, String> configs = {};
    for (final group in state.groups) {
      for (final server in group.locations) {
        if (server.configUri.isNotEmpty) {
          configs[server.id] = server.configUri;
        }
      }
    }

    await _vpn.initialize();
    final pings = await _vpn.pingAll(configs);

    state = state.copyWith(isPinging: false, pings: pings);
  }

  // ── Smart select — بهترین پینگ ───────────────────────────

  void selectSmart() {
    state = state.copyWith(selectedServerId: 'smart');
  }

  /// پیدا کردن بهترین سرور بر اساس پینگ
  ServerItem? get bestServer {
    final allServers = state.groups.expand((g) => g.locations).toList();
    if (allServers.isEmpty) return null;

    ServerItem? best;
    int bestPing = 99999;

    for (final server in allServers) {
      if (server.configUri.isEmpty) continue;
      final ping = state.pingOf(server.id);
      // 0 یعنی هنوز پینگ نگرفته — از ping خود سرور استفاده کن
      final effectivePing = ping > 0 ? ping : server.ping;
      if (effectivePing < bestPing) {
        bestPing = effectivePing;
        best = server;
      }
    }
    return best;
  }

  // ── Select / toggle ───────────────────────────────────────

  void selectServer(String serverId) {
    state = state.copyWith(selectedServerId: serverId);
  }

  void toggleGroup(String groupId) {
    final current = state.expandedGroupId;
    state = state.copyWith(
      expandedGroupId: current == groupId ? null : groupId,
    );
  }
}

// ── Provider ───────────────────────────────────────────────

final serversProvider =
    StateNotifierProvider<ServersNotifier, ServersState>((ref) {
  return ServersNotifier(
    ref.watch(serversRepositoryProvider),
    ref.watch(_vpnServiceProvider),
  );
});

/// سرور انتخاب‌شده فعلی — اگه smart بود بهترین پینگ برمیگردونه
final selectedServerProvider = Provider<ServerItem?>((ref) {
  final notifier = ref.watch(serversProvider.notifier);
  final state    = ref.watch(serversProvider);
  final id       = state.selectedServerId;

  if (id == null || id == 'smart') {
    return notifier.bestServer;
  }
  for (final group in state.groups) {
    try {
      return group.locations.firstWhere((s) => s.id == id);
    } catch (_) {}
  }
  return null;
});
