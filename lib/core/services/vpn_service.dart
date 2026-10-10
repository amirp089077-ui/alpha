import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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

  // ── Delay — بر اساس استاندارد هسته v2rayNG ─────────────────

  /// پینگ واقعی یک سرور از داخل تونل V2Ray به آدرس generate_204
  /// دقیقاً منطبق بر الگوریتم startRealPing در سورس v2rayNG:
  /// ۱. پیش‌بررسی سریع اتصال TCP با سقف ۱.۲ ثانیه برای فیلتر کردن فوری سرورهای قطع/بلاک
  /// ۲. تست تأخیر واقعی از هسته با آدرس https://www.gstatic.com/generate_204
  /// ۳. در صورت عدم موفقیت، تست ثانویه با https://www.google.com/generate_204
  /// ۴. اگر هسته جواب ندهد مقدار -1 (بدون fallback به TCP تقلبی) برگردانده می‌شود.
  Future<int> getDelay(String configUri, {String? host, int? port}) async {
    if (configUri.isEmpty) return -1;
    if (!_initialized) await initialize();

    // استخراج هاست و پورت سرور در صورت نیاز
    String? targetHost = host;
    int? targetPort = port;
    if (targetHost == null || targetHost.isEmpty || targetPort == null || targetPort <= 0) {
      final parsed = _extractHostPort(configUri);
      if (parsed != null) {
        targetHost = parsed.host;
        targetPort = parsed.port;
      }
    }

    // ۱. پیش‌بررسی سوکت TCP با تایم‌اوت ۱.۲ ثانیه (دقیقاً مثل SpeedtestManager.socketConnectTime در v2rayNG)
    if (targetHost != null && targetHost.isNotEmpty && targetPort != null && targetPort > 0) {
      final isAlive = await _quickTcpCheck(targetHost, targetPort);
      if (!isAlive) {
        return -1; // سرور در دسترس نیست؛ هسته سنگین V2Ray بیهوده اجرا نمی‌شود
      }
    }

    // ۲. اندازه‌گیری Real Delay واقعی توسط Libv2ray.measureOutboundDelay
    try {
      final V2RayURL v2rayURL = FlutterV2ray.parseFromURL(configUri);
      final config = v2rayURL.getFullConfiguration();

      // تست اول با gstatic (پیش‌فرض رسمی v2rayNG: DELAY_TEST_URL)
      final ping1 = await _flutterV2ray
          .getServerDelay(
            config: config,
            url: 'https://www.gstatic.com/generate_204',
          )
          .timeout(const Duration(milliseconds: 3500), onTimeout: () => -1);

      if (ping1 > 0) return ping1;

      // تست دوم با google (پیش‌فرض ثانویه v2rayNG: DELAY_TEST_URL2)
      final ping2 = await _flutterV2ray
          .getServerDelay(
            config: config,
            url: 'https://www.google.com/generate_204',
          )
          .timeout(const Duration(milliseconds: 2500), onTimeout: () => -1);

      if (ping2 > 0) return ping2;

      // تست سوم با cloudflare در صورت اختلال گوگل
      final ping3 = await _flutterV2ray
          .getServerDelay(
            config: config,
            url: 'https://cp.cloudflare.com/generate_204',
          )
          .timeout(const Duration(milliseconds: 2500), onTimeout: () => -1);

      if (ping3 > 0) return ping3;
    } catch (_) {}

    return -1;
  }

  /// پینگ سرور متصل فعلی از داخل تونل فعال
  Future<int> getConnectedDelay() async {
    if (!_initialized) return -1;

    try {
      final ping1 = await _flutterV2ray
          .getConnectedServerDelay(url: 'https://www.gstatic.com/generate_204')
          .timeout(const Duration(milliseconds: 3000), onTimeout: () => -1);
      if (ping1 > 0) return ping1;

      final ping2 = await _flutterV2ray
          .getConnectedServerDelay(url: 'https://www.google.com/generate_204')
          .timeout(const Duration(milliseconds: 2500), onTimeout: () => -1);
      if (ping2 > 0) return ping2;
    } catch (_) {}

    // تست تکمیلی HTTP مستقیم از داخل تونل فعال
    try {
      final sw = Stopwatch()..start();
      final client = http.Client();
      final res = await client
          .get(Uri.parse('https://cp.cloudflare.com/generate_204'))
          .timeout(const Duration(milliseconds: 2500));
      sw.stop();
      client.close();
      if (res.statusCode == 204 || res.statusCode == 200) {
        return sw.elapsedMilliseconds;
      }
    } catch (_) {}

    return -1;
  }

  Future<bool> _quickTcpCheck(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(milliseconds: 1200),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// استخراج هاست و پورت از انواع لینک‌های کانفیگ
  ({String host, int port})? _extractHostPort(String configUri) {
    try {
      if (configUri.startsWith('vmess://')) {
        final b64 = configUri.substring('vmess://'.length).trim();
        final normalized = base64.normalize(b64);
        final decoded = utf8.decode(base64.decode(normalized));
        final json = jsonDecode(decoded);
        final h = (json['add'] ?? json['host'] ?? '') as String;
        final p = int.tryParse(json['port']?.toString() ?? '443') ?? 443;
        if (h.isNotEmpty) return (host: h, port: p);
      }

      final uri = Uri.tryParse(configUri);
      if (uri != null && uri.host.isNotEmpty) {
        return (host: uri.host, port: uri.hasPort ? uri.port : 443);
      }

      final atIdx = configUri.indexOf('@');
      if (atIdx != -1) {
        final afterAt = configUri.substring(atIdx + 1);
        final colonIdx = afterAt.indexOf(':');
        if (colonIdx != -1) {
          final h = afterAt.substring(0, colonIdx);
          final rest = afterAt.substring(colonIdx + 1);
          final endIdx = rest.indexOf(RegExp(r'[/?#]'));
          final portStr = endIdx == -1 ? rest : rest.substring(0, endIdx);
          final p = int.tryParse(portStr) ?? 443;
          if (h.isNotEmpty) return (host: h, port: p);
        }
      }
    } catch (_) {}
    return null;
  }



  /// پینگ دسته‌ای سرورها با کنترل همزمانی
  Future<Map<String, int>> pingAll(Map<String, String> serverConfigs) async {
    if (!_initialized) await initialize();
    final Map<String, int> results = {};
    final entries = serverConfigs.entries.toList();

    const batchSize = 3;
    for (int i = 0; i < entries.length; i += batchSize) {
      final batch = entries.sublist(
        i,
        i + batchSize > entries.length ? entries.length : i + batchSize,
      );
      final batchResults = await Future.wait(
        batch.map((e) async {
          final ping = await getDelay(e.value);
          return MapEntry(e.key, ping);
        }),
      );
      results.addEntries(batchResults);
    }
    return results;
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
