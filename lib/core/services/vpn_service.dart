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
  final int uploadSpeed;
  final int downloadSpeed;
  final int upload;
  final int download;
  const VpnStats({
    this.uploadSpeed   = 0,
    this.downloadSpeed = 0,
    this.upload        = 0,
    this.download      = 0,
  });
}

class VpnService {
  static final VpnService _instance = VpnService._internal();
  factory VpnService() => _instance;
  VpnService._internal();

  // ── Public streams ────────────────────────────────────────

  final _statusController = StreamController<VpnConnectionStatus>.broadcast();
  final _statsController  = StreamController<VpnStats>.broadcast();

  Stream<VpnConnectionStatus> get statusStream => _statusController.stream;
  Stream<VpnStats>            get statsStream  => _statsController.stream;

  VpnConnectionStatus _status = VpnConnectionStatus.disconnected;
  VpnConnectionStatus get status => _status;

  // ── flutter_v2ray ────────────────────────────────────────

  late final FlutterV2ray _flutterV2ray;
  bool _initialized = false;

  // ── Init — دقیقاً مثل مثال رسمی ─────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _flutterV2ray = FlutterV2ray(
      onStatusChanged: (V2RayStatus status) {
        // stats
        _statsController.add(VpnStats(
          uploadSpeed:   status.uploadSpeed,
          downloadSpeed: status.downloadSpeed,
          upload:        status.upload,
          download:      status.download,
        ));

        // وضعیت
        VpnConnectionStatus newStatus;
        switch (status.state) {
          case 'CONNECTED':
            newStatus = VpnConnectionStatus.connected;
            break;
          case 'CONNECTING':
            newStatus = VpnConnectionStatus.connecting;
            break;
          case 'DISCONNECTING':
            newStatus = VpnConnectionStatus.disconnecting;
            break;
          default:
            newStatus = VpnConnectionStatus.disconnected;
        }
        if (newStatus != _status) {
          _status = newStatus;
          _statusController.add(_status);
        }
      },
    );

    // دقیقاً مثل مثال رسمی
    await _flutterV2ray.initializeV2Ray(
      notificationIconResourceType: 'mipmap',
      notificationIconResourceName: 'ic_launcher',
    );
    _initialized = true;
  }

  // ── Connect — دقیقاً مثل importConfig + connect در مثال ─

  Future<VpnConnectResult> connect({
    required String configUri,
    String? serverName, // اسم سرور از اپ — نشون داده میشه توی notification
  }) async {
    if (!_initialized) await initialize();

    try {
      _emit(VpnConnectionStatus.connecting);

      final V2RayURL v2rayURL = FlutterV2ray.parseFromURL(configUri);
      // اگه serverName از اپ پاس شد اونو استفاده کن، وگرنه از config
      final String remark = (serverName != null && serverName.isNotEmpty)
          ? serverName
          : v2rayURL.remark;
      final String config = v2rayURL.getFullConfiguration();

      if (await _flutterV2ray.requestPermission()) {
        _flutterV2ray.startV2Ray(
          remark:                           remark,
          config:                           config,
          proxyOnly:                        false,
          bypassSubnets:                    null,
          notificationDisconnectButtonName: 'قطع اتصال',
        );
        return const VpnConnectResult(success: true);
      } else {
        _emit(VpnConnectionStatus.error);
        return const VpnConnectResult(success: false, error: 'دسترسی VPN رد شد');
      }
    } catch (e) {
      _emit(VpnConnectionStatus.error);
      return VpnConnectResult(success: false, error: e.toString());
    }
  }

  // ── Disconnect ────────────────────────────────────────────

  void disconnect() {
    _flutterV2ray.stopV2Ray();
  }

  // ── Delay ─────────────────────────────────────────────────

  static const _kPingTimeout = Duration(seconds: 8);

  /// پینگ یک سرور — ms برمیگردونه، -1 اگه مرده یا timeout شد
  /// طبق داکیومنت فقط getServerDelay — بدون TCP fallback
  Future<int> getDelay(String configUri) async {
    if (!_initialized) await initialize();
    try {
      final V2RayURL v2rayURL = FlutterV2ray.parseFromURL(configUri);
      final config = v2rayURL.getFullConfiguration();

      final ping = await _flutterV2ray
          .getServerDelay(config: config)
          .timeout(_kPingTimeout, onTimeout: () => -1);

      if (ping > 0) return ping;
      return -1;
    } catch (_) {
      return -1;
    }
  }

  /// پینگ سرور متصل فعلی — طبق داکیومنت فقط وقتی CONNECTED
  Future<int> getConnectedDelay() async {
    if (!_initialized) return -1;
    try {
      final ping = await _flutterV2ray
          .getConnectedServerDelay()
          .timeout(_kPingTimeout, onTimeout: () => -1);
      if (ping <= 0) return -1;
      return ping;
    } catch (_) {
      return -1;
    }
  }

  /// پینگ موازی چند سرور — Map<serverId, pingMs> (-1 = مرده/نامشخص)
  Future<Map<String, int>> pingAll(Map<String, String> serverConfigs) async {
    if (!_initialized) await initialize();
    final futures = serverConfigs.entries.map((e) async {
      final ping = await getDelay(e.value);
      return MapEntry(e.key, ping);
    });
    final results = await Future.wait(futures);
    return Map.fromEntries(results);
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
