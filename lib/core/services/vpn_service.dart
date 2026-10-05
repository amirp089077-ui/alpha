import 'dart:async';
import 'package:flutter_v2ray/flutter_v2ray.dart';

enum VpnConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class VpnStats {
  final int uploadBytes;
  final int downloadBytes;
  const VpnStats({this.uploadBytes = 0, this.downloadBytes = 0});
  double get uploadMb   => uploadBytes   / (1024 * 1024);
  double get downloadMb => downloadBytes / (1024 * 1024);
}

class VpnService {
  static final VpnService _instance = VpnService._internal();
  factory VpnService() => _instance;
  VpnService._internal();

  final _statusController = StreamController<VpnConnectionStatus>.broadcast();
  final _statsController  = StreamController<VpnStats>.broadcast();

  Stream<VpnConnectionStatus> get statusStream => _statusController.stream;
  Stream<VpnStats>            get statsStream  => _statsController.stream;

  VpnConnectionStatus _status = VpnConnectionStatus.disconnected;
  VpnConnectionStatus get status => _status;

  late final FlutterV2ray _v2ray;
  bool _initialized = false;

  // ── Init ─────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _v2ray = FlutterV2ray(onStatusChanged: _onStatusChanged);
    await _v2ray.initializeV2Ray();
    _initialized = true;
  }

  // ── Status callback ───────────────────────────────────────

  void _onStatusChanged(V2RayStatus v2status) {
    _statsController.add(VpnStats(
      uploadBytes:   (v2status.uploadSpeed   * 1024).round(),
      downloadBytes: (v2status.downloadSpeed * 1024).round(),
    ));

    VpnConnectionStatus newStatus;
    switch (v2status.state) {
      case 'CONNECTED':      newStatus = VpnConnectionStatus.connected;     break;
      case 'CONNECTING':     newStatus = VpnConnectionStatus.connecting;    break;
      case 'DISCONNECTING':  newStatus = VpnConnectionStatus.disconnecting; break;
      default:               newStatus = VpnConnectionStatus.disconnected;
    }

    if (newStatus != _status) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  // ── Connect — دقیقاً طبق مستندات flutter_v2ray ───────────

  Future<VpnConnectResult> connect({
    required String configUri,
    required String remark,
  }) async {
    if (!_initialized) await initialize();

    try {
      _emit(VpnConnectionStatus.connecting);

      // parse — عین URI بدون دستکاری
      final V2RayURL parser = FlutterV2ray.parseFromURL(configUri);

      // permission
      final permitted = await _v2ray.requestPermission();
      if (!permitted) {
        _emit(VpnConnectionStatus.error);
        return VpnConnectResult(success: false, error: 'دسترسی VPN رد شد');
      }

      // start — دقیقاً طبق مستندات
      _v2ray.startV2Ray(
        remark:        parser.remark,
        config:        parser.getFullConfiguration(),
        blockedApps:   null,
        bypassSubnets: null,
        proxyOnly:     false,
      );

      return VpnConnectResult(success: true);
    } catch (e) {
      _emit(VpnConnectionStatus.error);
      return VpnConnectResult(success: false, error: e.toString());
    }
  }

  // ── Disconnect ────────────────────────────────────────────

  Future<void> disconnect() async {
    if (!_initialized) return;
    _emit(VpnConnectionStatus.disconnecting);
    _v2ray.stopV2Ray();
  }

  void _emit(VpnConnectionStatus s) {
    _status = s;
    _statusController.add(s);
  }

  void dispose() {
    _statusController.close();
    _statsController.close();
  }
}

class VpnConnectResult {
  final bool    success;
  final String? error;
  const VpnConnectResult({required this.success, this.error});
}
