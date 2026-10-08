import 'dart:async';
import 'dart:io';
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

  static const _kPingTimeout   = Duration(seconds: 6);
  static const _kTcpTimeout    = Duration(seconds: 4);

  /// پینگ یک سرور — ms برمیگردونه، -1 اگه مرده یا timeout شد
  ///
  /// استراتژی دو مرحله‌ای:
  /// ۱. getServerDelay از flutter_v2ray (برای vmess/vless/trojan ساده)
  /// ۲. اگه نتیجه معتبر نبود → TCP socket مستقیم به host:port سرور
  ///    (برای xhttp/reality که getServerDelay روشون کار نمی‌کنه)
  Future<int> getDelay(String configUri) async {
    if (!_initialized) await initialize();
    try {
      final V2RayURL v2rayURL = FlutterV2ray.parseFromURL(configUri);
      final config = v2rayURL.getFullConfiguration();

      // مرحله ۱ — تلاش با getServerDelay
      final ping = await _flutterV2ray
          .getServerDelay(config: config)
          .timeout(_kPingTimeout, onTimeout: () => -1);

      if (ping > 0) return ping;

      // مرحله ۲ — fallback به TCP ping برای xhttp/reality
      return await _tcpPing(configUri);
    } catch (_) {
      return await _tcpPing(configUri);
    }
  }

  /// TCP ping مستقیم به host:port سرور
  Future<int> _tcpPing(String configUri) async {
    try {
      // برای لینک‌های v2ray، host و port در بعد @ هستن
      // فرمت: vless://uuid@host:port?...
      String? host;
      int? port;

      final atIdx = configUri.indexOf('@');
      final questionIdx = configUri.indexOf('?');
      if (atIdx != -1) {
        final hostPort = configUri
            .substring(atIdx + 1, questionIdx == -1 ? configUri.length : questionIdx)
            .split(':');
        if (hostPort.length >= 2) {
          host = hostPort[0];
          port = int.tryParse(hostPort[1]);
        }
      }

      if (host == null || port == null) return -1;

      final sw = Stopwatch()..start();
      final socket = await Socket.connect(
        host,
        port,
        timeout: _kTcpTimeout,
      );
      sw.stop();
      socket.destroy();
      return sw.elapsedMilliseconds;
    } catch (_) {
      return -1;
    }
  }

  /// پینگ سرور متصل فعلی — فقط وقتی واقعاً متصله صداش بزن
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

  /// پینگ موازی چند سرور — Map<serverId, pingMs>  (-1 = مرده)
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
