import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/vpn_service.dart';
import '../data/models/home_models.dart';
import '../../servers/data/models/server_models.dart';
import '../../servers/providers/servers_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';

// ── VpnService provider ────────────────────────────────────

final vpnServiceProvider = Provider<VpnService>((_) => VpnService());

// ─────────────────────────────────────────────────────────────
// HomeNotifier
// ─────────────────────────────────────────────────────────────

class HomeNotifier extends StateNotifier<HomeState> {
  final Ref        _ref;
  final VpnService _vpn;

  StreamSubscription<VpnConnectionStatus>? _statusSub;
  StreamSubscription<VpnStats>?            _statsSub;
  Timer?                                   _timerSec;

  HomeNotifier(this._ref, this._vpn) : super(const HomeState()) {
    _init();
  }

  // ─────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────

  Future<void> _init() async {
    // مقداردهی اولیه از auth (remainingGb / remainingDays)
    _syncFromAuth();

    // initialize v2ray core
    await _vpn.initialize();

    // subscribe به status stream
    _statusSub = _vpn.statusStream.listen(_onVpnStatus);

    // subscribe به stats stream
    _statsSub = _vpn.statsStream.listen(_onVpnStats);
  }

  void _syncFromAuth() {
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      state = state.copyWith(
        remainingGb:   user.remainingGb,
        remainingDays: user.remainingDays,
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // Callbacks از VpnService
  // ─────────────────────────────────────────────────────────

  void _onVpnStatus(VpnConnectionStatus status) {
    state = state.copyWith(vpnStatus: status, errorMessage: null);

    if (status == VpnConnectionStatus.connected) {
      _startSecTimer();
    } else if (status == VpnConnectionStatus.disconnected ||
               status == VpnConnectionStatus.error) {
      _stopSecTimer();
      if (status == VpnConnectionStatus.disconnected) {
        state = state.copyWith(
          connectionSeconds: 0,
          uploadBytes:       0,
          downloadBytes:     0,
          pingMs:            0,
        );
      }
    }
  }

  void _onVpnStats(VpnStats stats) {
    state = state.copyWith(
      uploadBytes:   stats.uploadBytes,
      downloadBytes: stats.downloadBytes,
    );
  }

  // ─────────────────────────────────────────────────────────
  // Timer ثانیه‌ای برای connectionSeconds
  // ─────────────────────────────────────────────────────────

  void _startSecTimer() {
    _timerSec?.cancel();
    _timerSec = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isConnected) {
        state = state.copyWith(
          connectionSeconds: state.connectionSeconds + 1,
        );
      }
    });
  }

  void _stopSecTimer() {
    _timerSec?.cancel();
    _timerSec = null;
  }

  // ─────────────────────────────────────────────────────────
  // Toggle connect / disconnect
  // ─────────────────────────────────────────────────────────

  Future<void> toggleConnection() async {
    if (state.isConnected || state.isDisconnecting) {
      await _disconnect();
    } else if (!state.isConnecting) {
      await _connect();
    }
  }

  // ─────────────────────────────────────────────────────────
  // Connect
  // ─────────────────────────────────────────────────────────

  Future<void> _connect() async {
    // انتخاب سرور
    final server = _pickServer();
    if (server == null) {
      state = state.copyWith(
        errorMessage: 'هیچ سروری انتخاب نشده',
      );
      return;
    }

    if (server.configUri.isEmpty) {
      state = state.copyWith(
        errorMessage: 'آدرس کانفیگ سرور خالی است',
      );
      return;
    }

    // آپدیت UI — سرور فعال
    state = state.copyWith(
      activeServer:  server,
      errorMessage:  null,
    );

    // تنظیمات bypass از settings provider
    final bypassIran = _ref.read(settingsProvider).bypassIranSites;
    final whitelistedApps =
        _ref.read(settingsProvider).whitelistedApps.toList();

    final result = await _vpn.connect(
      configUri:   server.configUri,
      remark:      server.displayName,
      bypassIran:  bypassIran,
      blockedApps: whitelistedApps.isNotEmpty ? whitelistedApps : null,
    );

    if (result.success) {
      state = state.copyWith(pingMs: result.pingMs);
    } else {
      state = state.copyWith(
        errorMessage: result.error ?? 'اتصال ناموفق بود',
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // Disconnect
  // ─────────────────────────────────────────────────────────

  Future<void> _disconnect() async {
    await _vpn.disconnect();
  }

  // ─────────────────────────────────────────────────────────
  // انتخاب سرور
  // ─────────────────────────────────────────────────────────

  ServerItem? _pickServer() {
    final servers = _ref.read(serversProvider);

    // اگه سرور خاصی انتخاب شده
    if (servers.selectedServerId != null &&
        servers.selectedServerId != 'smart') {
      for (final g in servers.groups) {
        try {
          return g.locations
              .firstWhere((l) => l.id == servers.selectedServerId);
        } catch (_) {}
      }
    }

    // smart: اولین سرور با کمترین ping
    final allServers = servers.groups
        .expand((g) => g.locations)
        .toList();

    if (allServers.isEmpty) return null;

    allServers.sort((a, b) => a.ping.compareTo(b.ping));
    return allServers.first;
  }

  // ─────────────────────────────────────────────────────────
  // set active server (از ServersScreen)
  // ─────────────────────────────────────────────────────────

  void setActiveServer(ServerLocation server) {
    state = state.copyWith(activeServer: server);
  }

  // ─────────────────────────────────────────────────────────
  // refresh stats از auth
  // ─────────────────────────────────────────────────────────

  void refreshFromAuth() => _syncFromAuth();

  // ─────────────────────────────────────────────────────────
  // dispose
  // ─────────────────────────────────────────────────────────

  @override
  void dispose() {
    _statusSub?.cancel();
    _statsSub?.cancel();
    _stopSecTimer();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref, ref.watch(vpnServiceProvider));
});
