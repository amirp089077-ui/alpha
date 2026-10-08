import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/vpn_service.dart';
import '../data/models/home_models.dart';
import '../../servers/data/models/server_models.dart';
import '../../servers/providers/servers_provider.dart';
import '../../auth/providers/auth_provider.dart';

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
      _startPingTimer();
    } else if (status == VpnConnectionStatus.disconnected ||
               status == VpnConnectionStatus.error) {
      _stopSecTimer();
      _stopPingTimer();
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
      uploadBytes:   stats.upload,
      downloadBytes: stats.download,
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
  // Timer پینگ — هر 5 ثانیه وقتی connected هستیم
  // ─────────────────────────────────────────────────────────

  Timer? _timerPing;
  bool   _pingInFlight = false;

  void _startPingTimer() {
    _timerPing?.cancel();
    _pingInFlight = false;
    // اولین پینگ رو کمی با تاخیر بزن تا VPN کاملاً وصل بشه
    Future.delayed(const Duration(seconds: 2), () {
      if (state.isConnected) _fetchConnectedPing();
    });
    _timerPing = Timer.periodic(const Duration(seconds: 10), (_) {
      if (state.isConnected) _fetchConnectedPing();
    });
  }

  void _stopPingTimer() {
    _timerPing?.cancel();
    _timerPing = null;
    _pingInFlight = false;
  }

  Future<void> _fetchConnectedPing() async {
    // از overlapping request جلوگیری کن
    if (_pingInFlight) return;
    _pingInFlight = true;
    try {
      final ping = await _vpn.getConnectedDelay();
      // فقط اگه هنوز متصلیم آپدیت کن
      if (state.isConnected) {
        // -1 یعنی timeout/error — مقدار قبلی رو نگه دار تا UI نپره
        if (ping > 0) {
          state = state.copyWith(pingMs: ping);
        }
      }
    } finally {
      _pingInFlight = false;
    }
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

    final result = await _vpn.connect(
      configUri:  server.configUri,
      serverName: server.name,
    );

    if (!result.success) {
      state = state.copyWith(
        errorMessage: result.error ?? 'اتصال ناموفق بود',
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // Disconnect
  // ─────────────────────────────────────────────────────────

  Future<void> _disconnect() async {
    _vpn.disconnect();
  }

  // ─────────────────────────────────────────────────────────
  // انتخاب سرور
  // ─────────────────────────────────────────────────────────

  ServerItem? _pickServer() {
    final serversState   = _ref.read(serversProvider);
    final serversNotifier = _ref.read(serversProvider.notifier);

    // اگه سرور خاصی انتخاب شده (نه smart)
    if (serversState.selectedServerId != null &&
        serversState.selectedServerId != 'smart') {
      for (final g in serversState.groups) {
        try {
          return g.locations
              .firstWhere((l) => l.id == serversState.selectedServerId);
        } catch (_) {}
      }
    }

    // smart: از bestServer که بر اساس پینگ واقعی کار می‌کنه استفاده کن
    final best = serversNotifier.bestServer;
    if (best != null) return best;

    // fallback: اولین سرور معتبر
    for (final g in serversState.groups) {
      for (final s in g.locations) {
        if (s.configUri.isNotEmpty) return s;
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────
  // set active server (از ServersScreen)
  // ─────────────────────────────────────────────────────────

  void setActiveServer(ServerLocation server) {
    state = state.copyWith(activeServer: server);
  }

  // ─────────────────────────────────────────────────────────
  // connectToServer — از ServersScreen کلیک مستقیم
  // ─────────────────────────────────────────────────────────

  Future<void> connectToServer(ServerItem server) async {
    if (state.isConnected || state.isConnecting) {
      _vpn.disconnect();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    state = state.copyWith(activeServer: server, errorMessage: null);

    if (server.configUri.isEmpty) {
      state = state.copyWith(errorMessage: 'آدرس کانفیگ سرور خالی است');
      return;
    }
    _emit(VpnConnectionStatus.connecting);

    final result = await _vpn.connect(
      configUri:  server.configUri,
      serverName: server.name,
    );
    if (!result.success) {
      state = state.copyWith(errorMessage: result.error ?? 'اتصال ناموفق بود');
    }
  }

  // ─────────────────────────────────────────────────────────
  // connectSmart — بهترین سرور بر اساس پینگ
  // ─────────────────────────────────────────────────────────

  Future<void> connectSmart() async {
    final best = _ref.read(serversProvider.notifier).bestServer;
    if (best != null) {
      await connectToServer(best);
    } else {
      await _connect();
    }
  }

  void _emit(VpnConnectionStatus s) {
    state = state.copyWith(vpnStatus: s);
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
    _stopPingTimer();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref, ref.watch(vpnServiceProvider));
});
