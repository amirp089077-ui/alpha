import '../../../servers/data/models/server_models.dart';

enum VpnStatus { disconnected, connecting, connected, disconnecting }

class HomeState {
  final VpnStatus vpnStatus;
  final int connectionSeconds;
  final int pingMs;
  final double usageMb;
  final double remainingGb;
  final int remainingDays;
  final ServerLocation? activeServer;

  const HomeState({
    this.vpnStatus = VpnStatus.disconnected,
    this.connectionSeconds = 0,
    this.pingMs = 0,
    this.usageMb = 0,
    this.remainingGb = 34.1,
    this.remainingDays = 17,
    this.activeServer,
  });

  bool get isConnected    => vpnStatus == VpnStatus.connected;
  bool get isConnecting   => vpnStatus == VpnStatus.connecting;
  bool get isDisconnecting => vpnStatus == VpnStatus.disconnecting;

  HomeState copyWith({
    VpnStatus? vpnStatus,
    int? connectionSeconds,
    int? pingMs,
    double? usageMb,
    double? remainingGb,
    int? remainingDays,
    ServerLocation? activeServer,
  }) {
    return HomeState(
      vpnStatus:         vpnStatus         ?? this.vpnStatus,
      connectionSeconds: connectionSeconds ?? this.connectionSeconds,
      pingMs:            pingMs            ?? this.pingMs,
      usageMb:           usageMb           ?? this.usageMb,
      remainingGb:       remainingGb       ?? this.remainingGb,
      remainingDays:     remainingDays     ?? this.remainingDays,
      activeServer:      activeServer      ?? this.activeServer,
    );
  }
}
