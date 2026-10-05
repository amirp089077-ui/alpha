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
// VPN Stats
// ─────────────────────────────────────────────────────────────

class VpnStats {
  final int uploadBytes;
  final int downloadBytes;

  const VpnStats({this.uploadBytes = 0, this.downloadBytes = 0});

  double get uploadMb   => uploadBytes   / (1024 * 1024);
  double get downloadMb => downloadBytes / (1024 * 1024);
}

// ─────────────────────────────────────────────────────────────
// VpnService
// ─────────────────────────────────────────────────────────────

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

  // ── URI cleaner — فقط پارامترهای خالی حذف میشن ──────────
  // fragment (#remark) دست نخورده می‌مونه

  String _cleanUri(String uri) {
    try {
      final hashIdx  = uri.indexOf('#');
      final fragment = hashIdx >= 0 ? uri.substring(hashIdx + 1) : '';
      final base     = hashIdx >= 0 ? uri.substring(0, hashIdx)  : uri;

      final u       = Uri.parse(base);
      final cleaned = Map<String, String>.fromEntries(
        u.queryParameters.entries.where((e) => e.value.isNotEmpty),
      );
      final result = u.replace(queryParameters: cleaned).toString();
      return fragment.isNotEmpty ? '$result#$fragment' : result;
    } catch (_) {
      return uri;
    }
  }

  // ── IP سرور VPN رو از لیست bypass حذف می‌کنه ────────────
  // بدون این کار ترافیک VPN خودش هم bypass میشه و loop

  List<String> _subnetsWithoutServer(String serverIp) {
    return kBypassIranSubnets
        .where((subnet) => !_subnetContainsIp(subnet, serverIp))
        .toList();
  }

  bool _subnetContainsIp(String subnet, String ip) {
    try {
      final parts      = subnet.split('/');
      final subnetIp   = parts[0];
      final prefixLen  = int.parse(parts[1]);

      final sparts = subnetIp.split('.').map(int.parse).toList();
      final iparts = ip.split('.').map(int.parse).toList();
      if (sparts.length != 4 || iparts.length != 4) return false;

      int sInt = 0, iInt = 0;
      for (int i = 0; i < 4; i++) {
        sInt = (sInt << 8) | sparts[i];
        iInt = (iInt << 8) | iparts[i];
      }
      final mask = prefixLen == 0 ? 0 : (0xFFFFFFFF << (32 - prefixLen)) & 0xFFFFFFFF;
      return (sInt & mask) == (iInt & mask);
    } catch (_) {
      return false;
    }
  }

  // ── IP سرور رو از URI بیرون بکش ─────────────────────────

  String? _extractServerIp(String uri) {
    try {
      final base = uri.contains('#') ? uri.substring(0, uri.indexOf('#')) : uri;
      final u    = Uri.parse(base);
      final host = u.host;
      // فقط IP خالص (نه domain)
      final ipRegex = RegExp(r'^\d+\.\d+\.\d+\.\d+$');
      return ipRegex.hasMatch(host) ? host : null;
    } catch (_) {
      return null;
    }
  }

  // ── Connect ───────────────────────────────────────────────

  Future<VpnConnectResult> connect({
    required String configUri,
    required String remark,
    bool bypassIran        = true,
    List<String>? blockedApps,
  }) async {
    if (!_initialized) await initialize();

    try {
      _emit(VpnConnectionStatus.connecting);

      final cleanUri = _cleanUri(configUri);
      final parser   = FlutterV2ray.parseFromURL(cleanUri);

      // permission
      final permitted = await _v2ray.requestPermission();
      if (!permitted) {
        _emit(VpnConnectionStatus.error);
        return VpnConnectResult(success: false, error: 'دسترسی VPN رد شد');
      }

      // bypass subnets — IP سرور رو حذف می‌کنیم تا ترافیک VPN bypass نشه
      List<String>? bypassList;
      if (bypassIran) {
        final serverIp = _extractServerIp(cleanUri);
        bypassList = serverIp != null
            ? _subnetsWithoutServer(serverIp)
            : kBypassIranSubnets;
      }

      await _v2ray.startV2Ray(
        remark:        remark,
        config:        parser.getFullConfiguration(),
        blockedApps:   blockedApps,
        bypassSubnets: bypassList,
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

  // ── Ping ─────────────────────────────────────────────────

  Future<int> ping(String configUri) async {
    if (!_initialized) await initialize();
    try {
      final parser = FlutterV2ray.parseFromURL(_cleanUri(configUri));
      return await _v2ray
          .getServerDelay(config: parser.getFullConfiguration())
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return 9999;
    }
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
