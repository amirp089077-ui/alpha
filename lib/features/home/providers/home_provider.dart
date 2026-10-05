import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/home_models.dart';
import '../../servers/data/models/server_models.dart';
import '../../servers/providers/servers_provider.dart';

class HomeNotifier extends StateNotifier<HomeState> {
  Timer? _timer;
  final Ref _ref;

  HomeNotifier(this._ref) : super(const HomeState());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> toggleConnection() async {
    if (state.isConnected || state.isDisconnecting) {
      await _disconnect();
    } else if (!state.isConnecting) {
      await _connect();
    }
  }

  Future<void> _connect() async {
    state = state.copyWith(vpnStatus: VpnStatus.connecting);
    await Future.delayed(const Duration(milliseconds: 1800));

    // Pick active server from servers provider
    final servers = _ref.read(serversProvider);
    ServerLocation? server;
    if (servers.selectedServerId != null && servers.selectedServerId != 'smart') {
      for (final g in servers.groups) {
        try {
          server = g.locations.firstWhere((l) => l.id == servers.selectedServerId);
          break;
        } catch (_) {}
      }
    }
    server ??= const ServerLocation(
      id: 'de-1', name: 'آلمان - ۱', flagEmoji: '🇩🇪', ping: 165, badge: ServerBadge.b,
    );

    state = state.copyWith(
      vpnStatus: VpnStatus.connected,
      pingMs: server.ping,
      activeServer: server,
      connectionSeconds: 0,
    );
    _startTimer();
  }

  Future<void> _disconnect() async {
    _timer?.cancel();
    state = state.copyWith(vpnStatus: VpnStatus.disconnecting);
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(
      vpnStatus: VpnStatus.disconnected,
      connectionSeconds: 0,
      pingMs: 0,
      usageMb: 0,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isConnected) {
        _timer?.cancel();
        return;
      }
      state = state.copyWith(
        connectionSeconds: state.connectionSeconds + 1,
        usageMb: state.usageMb + 0.05,
      );
    });
  }

  void setActiveServer(ServerLocation server) {
    state = state.copyWith(activeServer: server);
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref);
});
