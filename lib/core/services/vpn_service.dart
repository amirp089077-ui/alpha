import 'dart:async';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../utils/bypass_subnets.dart';

// ─────────────────────────────────────────────────────────────
// VPN Status
// ─────────────────────────────────────────────────────────────

enum VpnConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

// ─────────────────────────────────────────────────────────────
// VPN Stats (traffic)
// ─────────────────────────────────────────────────────────────

class VpnStats {
  final int uploadBytes;
  final int downloadBytes;
  final int pingMs;

  const VpnStats({
    this.uploadBytes  = 0,
    this.downloadBytes = 0,
    this.pingMs       = 0,
  });

  double get uploadMb   => uploadBytes   / (1024 * 1024);
  double get downloadMb => downloadBytes / (1024 * 1024);
}

// ─────────────────────────────────────────────────────────────
// VpnService — singleton wrapper روی flutter_v2ray
// ─────────────────────────────────────────────────────────────

class VpnService {
  static final VpnService _instance = VpnService._internal();
  factory VpnService() => _instance;
  VpnService._internal();

  // ── State streams ──────────────────────────────────────────

  final _statusController =
      StreamController<VpnConnectionStatus>.broadcast();
  final _statsController = StreamController<VpnStats>.broadcast();

  Stream<VpnConnectionStatus> get statusStream => _statusController.stream;
  Stream<VpnStats>            get statsStream  => _statsController.stream;

  VpnConnectionStatus _status = VpnConnectionStatus.disconnected;
  VpnConnectionStatus get status => _status;

  // ── flutter_v2ray instance ─────────────────────────────────

  late final FlutterV2ray _v2ray;
  bool _initialized = false;

  // ─────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _v2ray = FlutterV2ray(
      onStatusChanged: _onStatusChanged,
    );
    await _v2ray.initializeV2Ray();
    _initialized = true;
  }

  // ─────────────────────────────────────────────────────────
  // Status callback از flutter_v2ray
  // ─────────────────────────────────────────────────────────

  void _onStatusChanged(V2RayStatus v2status) {
    final upload   = v2status.uploadSpeed;
    final download = v2status.downloadSpeed;

    // stats
    _statsController.add(VpnStats(
      uploadBytes:   (upload   * 1024).round(),
      downloadBytes: (download * 1024).round(),
    ));

    // وضعیت
    VpnConnectionStatus newStatus;
    switch (v2status.state) {
      case 'CONNECTED':
        newStatus = VpnConnectionStatus.connected;
        break;
      case 'CONNECTING':
        newStatus = VpnConnectionStatus.connecting;
        break;
      case 'DISCONNECTING':
        newStatus = VpnConnectionStatus.disconnecting;
        break;
      case 'STOPPED':
      case 'DISCONNECTED':
        newStatus = VpnConnectionStatus.disconnected;
        break;
      default:
        newStatus = VpnConnectionStatus.disconnected;
    }

    if (newStatus != _status) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  // ─────────────────────────────────────────────────────────
  // Request VPN permission (Android)
  // ─────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    return await _v2ray.requestPermission();
  }

  // ─────────────────────────────────────────────────────────
  // Connect با config_uri (VLESS link)
  // ─────────────────────────────────────────────────────────

  Future<VpnConnectResult> connect({
    required String configUri,
    required String remark,
    bool bypassIran = true,
    List<String>? blockedApps,
  }) async {
    if (!_initialized) await initialize();

    try {
      _status = VpnConnectionStatus.connecting;
      _statusController.add(_status);

      // Parse VLESS/VMess link
      final parser = FlutterV2ray.parseFromURL(configUri);

      // دریافت delay قبل از اتصال
      final delay = await _v2ray.getServerDelay(
        config: parser.getFullConfiguration(),
      );

      // درخواست permission اندروید
      final permitted = await _v2ray.requestPermission();
      if (!permitted) {
        _status = VpnConnectionStatus.error;
        _statusController.add(_status);
        return VpnConnectResult(
          success: false,
          error: 'دسترسی VPN رد شد',
        );
      }

      await _v2ray.startV2Ray(
        remark:        remark,
        config:        parser.getFullConfiguration(),
        blockedApps:   blockedApps,
        bypassSubnets: bypassIran ? kBypassIranSubnets : null,
        proxyOnly:     false,
      );

      return VpnConnectResult(success: true, pingMs: delay);
    } catch (e) {
      _status = VpnConnectionStatus.error;
      _statusController.add(_status);
      return VpnConnectResult(success: false, error: e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────
  // Disconnect
  // ─────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    if (!_initialized) return;
    _status = VpnConnectionStatus.disconnecting;
    _statusController.add(_status);
    _v2ray.stopV2Ray();
  }

  // ─────────────────────────────────────────────────────────
  // Ping تنها (بدون اتصال)
  // ─────────────────────────────────────────────────────────

  Future<int> ping(String configUri) async {
    if (!_initialized) await initialize();
    try {
      final parser = FlutterV2ray.parseFromURL(configUri);
      return await _v2ray.getServerDelay(config: parser.getFullConfiguration());
    } catch (_) {
      return 9999;
    }
  }

  void dispose() {
    _statusController.close();
    _statsController.close();
  }
}

// ─────────────────────────────────────────────────────────────

class VpnConnectResult {
  final bool    success;
  final String? error;
  final int     pingMs;

  const VpnConnectResult({
    required this.success,
    this.error,
    this.pingMs = 0,
  });
}
