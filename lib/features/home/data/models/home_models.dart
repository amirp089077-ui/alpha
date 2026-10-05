import '../../../servers/data/models/server_models.dart';
import '../../../../core/services/vpn_service.dart';

export '../../../../core/services/vpn_service.dart'
    show VpnConnectionStatus, VpnStats;

// VpnStatus رو از VpnConnectionStatus می‌گیریم برای backward-compat
typedef VpnStatus = VpnConnectionStatus;

class HomeState {
  final VpnConnectionStatus vpnStatus;
  final int connectionSeconds;
  final int pingMs;

  /// مصرف آپلود از flutter_v2ray (bytes)
  final int uploadBytes;
  /// مصرف دانلود از flutter_v2ray (bytes)
  final int downloadBytes;

  /// حجم باقی‌مانده از سرور (GB) — از authProvider می‌آد
  final double remainingGb;
  final int remainingDays;
  final ServerLocation? activeServer;

  /// پیام خطا هنگام connect
  final String? errorMessage;

  const HomeState({
    this.vpnStatus         = VpnConnectionStatus.disconnected,
    this.connectionSeconds = 0,
    this.pingMs            = 0,
    this.uploadBytes       = 0,
    this.downloadBytes     = 0,
    this.remainingGb       = 0,
    this.remainingDays     = 0,
    this.activeServer,
    this.errorMessage,
  });

  // ── Backward-compat getters ────────────────────────────────
  bool get isConnected     => vpnStatus == VpnConnectionStatus.connected;
  bool get isConnecting    => vpnStatus == VpnConnectionStatus.connecting;
  bool get isDisconnecting => vpnStatus == VpnConnectionStatus.disconnecting;

  /// مگابایت آپلود
  double get usageMb => downloadBytes / (1024 * 1024);

  HomeState copyWith({
    VpnConnectionStatus? vpnStatus,
    int?                 connectionSeconds,
    int?                 pingMs,
    int?                 uploadBytes,
    int?                 downloadBytes,
    double?              remainingGb,
    int?                 remainingDays,
    ServerLocation?      activeServer,
    String?              errorMessage,
  }) {
    return HomeState(
      vpnStatus:         vpnStatus         ?? this.vpnStatus,
      connectionSeconds: connectionSeconds ?? this.connectionSeconds,
      pingMs:            pingMs            ?? this.pingMs,
      uploadBytes:       uploadBytes       ?? this.uploadBytes,
      downloadBytes:     downloadBytes     ?? this.downloadBytes,
      remainingGb:       remainingGb       ?? this.remainingGb,
      remainingDays:     remainingDays     ?? this.remainingDays,
      activeServer:      activeServer      ?? this.activeServer,
      errorMessage:      errorMessage,
    );
  }
}
