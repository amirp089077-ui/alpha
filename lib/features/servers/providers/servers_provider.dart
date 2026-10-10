import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/vpn_service.dart';
import '../data/models/server_models.dart';
import '../data/repository/servers_repository.dart';
import '../../auth/data/models/auth_models.dart';
import '../../auth/providers/auth_provider.dart';

// ── Repository + VpnService providers ─────────────────────

final serversRepositoryProvider = Provider<ServersRepository>(
  (_) => ServersRepository(),
);

final _vpnServiceProvider = Provider<VpnService>((_) => VpnService());

// ── Notifier ───────────────────────────────────────────────

class ServersNotifier extends StateNotifier<ServersState> {
  final ServersRepository _repo;
  final VpnService        _vpn;
  final Ref               _ref;

  ServersNotifier(this._repo, this._vpn, this._ref)
      : super(const ServersState()) {
    loadServers();
    // بروزرسانی سرورها هنگام سوئیچ اکانت یا تغییر کاربر
    _ref.listen<UserModel?>(currentUserProvider, (prev, next) {
      if (prev?.username != next?.username || prev?.token != next?.token) {
        state = const ServersState();
        loadServers();
      }
    });
  }

  // ── Load ─────────────────────────────────────────────────

  Future<void> loadServers() async {
    // چک کن کاربر اشتراک معتبر داره یا نه
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      final isExpired  = user.remainingDays <= 0;
      final isQuotaDone = user.totalQuotaGb > 0 && user.remainingGb <= 0;
      final isBanned   = user.status == 'BANNED';

      if (isExpired || isQuotaDone || isBanned) {
        final msg = isBanned
            ? 'حساب شما مسدود شده است. با پشتیبانی تماس بگیرید.'
            : isExpired
                ? 'اشتراک شما منقضی شده است. لطفاً تمدید کنید.'
                : 'حجم فیلترشکن شما تمام شده است. لطفاً تمدید کنید.';
        state = state.copyWith(
          isLoading:    false,
          groups:       [],
          errorMessage: msg,
        );
        return;
      }
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final groups = await _repo.fetchServers();
      state = state.copyWith(isLoading: false, groups: groups);
      // بعد از لود، پینگ همه رو بگیر
      fetchPings();
    } on ApiException catch (e) {
      // بک‌اند 403 = اشتراک منقضی یا مسدود
      if (e.statusCode == 403) {
        state = state.copyWith(
          isLoading:    false,
          groups:       [],
          errorMessage: 'اشتراک شما به پایان رسیده لطفا اشتراک تهیه کنید.',
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: e.message);
      }
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'خطا در دریافت سرورها');
    }
  }

  Future<void> refresh() => loadServers();

  // ── Real Delay همه سرورها منطبق بر رفتار v2rayNG ─────────────

  Future<void> fetchPings() async {
    if (state.groups.isEmpty) return;

    state = state.copyWith(isPinging: true);

    final allServers = state.groups.expand((g) => g.locations).toList();
    if (allServers.isEmpty) {
      state = state.copyWith(isPinging: false);
      return;
    }
    await _vpn.initialize();

    final Map<String, int> livePings = Map.from(state.pings);
    const concurrency = 12;
    int index = 0;

    Future<void> worker() async {
      while (true) {
        final i = index++;
        if (i >= allServers.length) break;
        final s = allServers[i];
        final ping = await _vpn.getDelay(
          s.configUri,
          host: s.host.isNotEmpty ? s.host : null,
          port: s.port > 0 ? s.port : null,
        );
        livePings[s.id] = ping;
        // بروزرسانی بلادرنگ UI برای هر سرور به محض آماده شدن پینگ (زنده مثل v2rayNG)
        state = state.copyWith(pings: Map.from(livePings));
      }
    }

    final workers = List.generate(
      concurrency.clamp(1, allServers.length),
      (_) => worker(),
    );
    await Future.wait(workers);

    state = state.copyWith(isPinging: false, pings: livePings);
  }

  // ── Smart select — بهترین پینگ ───────────────────────────

  void selectSmart() {
    state = state.copyWith(selectedServerId: 'smart');
  }

  /// پیدا کردن بهترین سرور بر اساس پینگ واقعی اندازه‌گیری‌شده
  /// فقط سرورهایی که پینگ واقعی (> 0) دارن رو در نظر می‌گیره
  /// اگه هیچ پینگ واقعی نداریم null برمیگردونه تا بعداً retry بشه
  ServerItem? get bestServer {
    final allServers = state.groups.expand((g) => g.locations).toList();
    if (allServers.isEmpty) return null;

    ServerItem? best;
    int bestPing = 99999;

    for (final server in allServers) {
      if (server.configUri.isEmpty) continue;
      final ping = state.pingOf(server.id);

      // -1 = سرور مرده → رد کن
      if (ping == -1) continue;

      // 0 = هنوز پینگ واقعی نگرفتیم → رد کن
      // (برخلاف قبل که از server.ping=50 fallback می‌کرد)
      if (ping == 0) continue;

      if (ping < bestPing) {
        bestPing = ping;
        best = server;
      }
    }

    // اگه هیچ پینگ واقعی نداریم، اولین سرور معتبر رو بده
    // (این حالت فقط قبل از fetchPings اتفاق میفته)
    if (best == null) {
      for (final server in allServers) {
        if (server.configUri.isNotEmpty && state.pingOf(server.id) != -1) {
          return server;
        }
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
    ref,
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
