import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/vpn_service.dart';
import '../../../core/services/usage_service.dart';
import '../data/models/home_models.dart';
import '../../servers/data/models/server_models.dart';
import '../../servers/providers/servers_provider.dart';
import '../../auth/data/models/auth_models.dart';
import '../../auth/providers/auth_provider.dart';

// ── VpnService provider ────────────────────────────────────

final vpnServiceProvider = Provider<VpnService>((_) => VpnService());

// ─────────────────────────────────────────────────────────────
// HomeNotifier
// ─────────────────────────────────────────────────────────────

class HomeNotifier extends StateNotifier<HomeState> {
  final Ref          _ref;
  final VpnService   _vpn;
  final UsageService _usage;

  StreamSubscription<VpnConnectionStatus>? _statusSub;
  StreamSubscription<VpnStats>?            _statsSub;
  Timer?                                   _timerSec;

  HomeNotifier(this._ref, this._vpn, this._usage)
      : super(const HomeState()) {
    _init();
  }

  // ─────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────

  Future<void> _init() async {
    _syncFromUser(_ref.read(currentUserProvider));
    await _vpn.initialize();
    _statusSub = _vpn.statusStream.listen(_onVpnStatus);
    _statsSub  = _vpn.statsStream.listen(_onVpnStats);

    // گوش دادن به تغییر کاربر (ورود، خروج، یا سوئیچ اکانت)
    _ref.listen<UserModel?>(currentUserProvider, (previous, next) {
      if (previous?.username != next?.username || previous?.token != next?.token) {
        _syncFromUser(next);
      }
    });
  }

  void _syncFromUser(UserModel? user) {
    if (user == null) {
      if (state.isConnected || state.isConnecting) {
        _vpn.disconnect();
      }
      _usage.reset();
      state = const HomeState();
      return;
    }

    _usage.reset(newUsername: user.username);
    _usage.updateLimit(
      limitGb:  user.totalQuotaGb,
      usedGb:   user.usedGb,
      username: user.username,
    );

    state = state.copyWith(
      remainingGb:       user.remainingGb,
      remainingDays:     user.remainingDays,
      connectionSeconds: 0,
      uploadBytes:       0,
      downloadBytes:     0,
      pingMs:            0,
      errorMessage:      null,
    );
  }

  void _syncFromAuth() => _syncFromUser(_ref.read(currentUserProvider));

  // ─────────────────────────────────────────────────────────
  // Callbacks از VpnService
  // ─────────────────────────────────────────────────────────

  void _onVpnStatus(VpnConnectionStatus status) {
    state = state.copyWith(vpnStatus: status, errorMessage: null);

    if (status == VpnConnectionStatus.connected) {
      final user = _ref.read(currentUserProvider);
      _startSecTimer();
      _startPingTimer();
      _usage.start(
        limitGb:        user?.totalQuotaGb ?? 0,
        usedGb:         user?.usedGb       ?? 0,
        username:       user?.username,
        onLimitReached: _onLimitReached,
      );
    } else if (status == VpnConnectionStatus.disconnected ||
               status == VpnConnectionStatus.error) {
      _stopSecTimer();
      _stopPingTimer();
      // flush: true — bytes رو فوری بفرست موقع disconnect
      _usage.stop(flush: true);
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
    // ارسال به UsageService برای جمع‌آوری
    _usage.updateStats(stats);
  }

  /// وقتی حجم تموم شد
  void _onLimitReached() {
    _vpn.disconnect();
    state = state.copyWith(
      errorMessage: 'حجم اینترنت شما تمام شد. لطفاً اشتراک خود را تمدید کنید.',
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
  // Timer پینگ — هر ۱۰ ثانیه وقتی connected هستیم
  // ─────────────────────────────────────────────────────────

  Timer? _timerPing;
  bool   _pingInFlight = false;

  void _startPingTimer() {
    _timerPing?.cancel();
    _pingInFlight = false;
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
    if (_pingInFlight) return;
    _pingInFlight = true;
    try {
      final ping = await _vpn.getConnectedDelay();
      if (state.isConnected && ping > 0) {
        state = state.copyWith(pingMs: ping);
      }
    } finally {
      _pingInFlight = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // چک سقف قبل از اتصال
  // ─────────────────────────────────────────────────────────

  bool get _isQuotaExceeded {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;
    if (user.totalQuotaGb <= 0) return false; // بی‌نهایت

    // تسک ۲: به جای user.usedGb (قدیمی از login)، از UsageService بخون
    // UsageService.currentUsedGb شامل pending bytes این session هم هست
    final liveUsedGb = _usage.currentUsedGb;

    // اگه UsageService هنوز start نشده (قبل از اولین اتصال)، از auth بخون
    final effectiveUsedGb = liveUsedGb > 0 ? liveUsedGb : user.usedGb;

    return effectiveUsedGb >= user.totalQuotaGb;
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
    // چک حجم
    if (_isQuotaExceeded) {
      state = state.copyWith(
        errorMessage: 'حجم اینترنت شما تمام شد. لطفاً اشتراک خود را تمدید کنید.',
      );
      return;
    }

    final server = _pickServer();
    if (server == null) {
      state = state.copyWith(errorMessage: 'هیچ سروری انتخاب نشده');
      return;
    }
    if (server.configUri.isEmpty) {
      state = state.copyWith(errorMessage: 'آدرس کانفیگ سرور خالی است');
      return;
    }

    state = state.copyWith(activeServer: server, errorMessage: null);

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
    final serversState    = _ref.read(serversProvider);
    final serversNotifier = _ref.read(serversProvider.notifier);

    if (serversState.selectedServerId != null &&
        serversState.selectedServerId != 'smart') {
      for (final g in serversState.groups) {
        try {
          return g.locations
              .firstWhere((l) => l.id == serversState.selectedServerId);
        } catch (_) {}
      }
    }

    final best = serversNotifier.bestServer;
    if (best != null) return best;

    for (final g in serversState.groups) {
      for (final s in g.locations) {
        if (s.configUri.isNotEmpty) return s;
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────
  // connectToServer — از ServersScreen
  // ─────────────────────────────────────────────────────────

  Future<void> connectToServer(ServerItem server) async {
    // چک حجم
    if (_isQuotaExceeded) {
      state = state.copyWith(
        errorMessage: 'حجم اینترنت شما تمام شد. لطفاً اشتراک خود را تمدید کنید.',
      );
      return;
    }

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
  // connectSmart
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
    _usage.stop(flush: true);
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(
    ref,
    ref.watch(vpnServiceProvider),
    ref.watch(usageServiceProvider),
  );
});
