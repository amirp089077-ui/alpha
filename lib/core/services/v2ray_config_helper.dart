import 'dart:convert';
import 'package:flutter_v2ray/flutter_v2ray.dart';

/// سازنده و نرمال‌ساز کانفیگ‌های V2Ray / Xray برای پشتیبانی کامل از انواع پروتکل‌ها
/// رفع باگ‌های عدم اتصال و پینگ ناموفق سرورها:
/// ۱. رفع باگ IPv6 بدون براکت (Crash در پارس URI)
/// ۲. پر کردن خودکار Header Host در وب‌سوکت از روی SNI یا آدرس سرور (جلوگیری از خطای 400 Bad Request کلودفلر)
/// ۳. اصلاح تنظیمات REALITY و جلوگیری از افزودن فیلدهای نامعتبر مثل allowInsecure به realitySettings
/// ۴. تنظیم domainStrategy به "AsIs" برای جلوگیری از دی‌ان‌اس پویزنینگ (DNS Poisoning) در ایران
/// ۵. بازنویسی بدون وابستگی ناقص به لایه پارسر اولیه flutter_v2ray
class V2rayConfigHelper {
  /// نرمال‌سازی لینک سرور و رفع باگ‌های IPv6 بدون براکت
  static String normalizeUri(String raw) {
    var uri = raw.trim();
    if (uri.isEmpty) return uri;

    // تشخیص و اصلاح آدرس‌های IPv6 فاقد براکت مانند:
    // vless://uuid@2606:4700:...:443?... -> vless://uuid@[2606:4700:...]:443?...
    final atIdx = uri.indexOf('@');
    final qIdx = uri.indexOf('?');
    final hashIdx = uri.indexOf('#');
    final endIdx = qIdx != -1 ? qIdx : (hashIdx != -1 ? hashIdx : uri.length);

    if (atIdx != -1 && endIdx > atIdx) {
      final hostPort = uri.substring(atIdx + 1, endIdx);
      if (!hostPort.startsWith('[')) {
        final lastColon = hostPort.lastIndexOf(':');
        if (lastColon != -1) {
          final hostPart = hostPort.substring(0, lastColon);
          final portPart = hostPort.substring(lastColon + 1);
          // اگر بخش هاست دارای چند دونقطه باشد، این یک IPv6 خام است
          if (hostPart.contains(':')) {
            uri =
                '${uri.substring(0, atIdx + 1)}[$hostPart]:$portPart${uri.substring(endIdx)}';
          }
        }
      }
    }
    return uri;
  }

  /// استخراج آدرس سرور، پورت و ریمارک
  static ({String address, int port, String remark}) parseEndpoint(String configUri) {
    try {
      final normalized = normalizeUri(configUri);
      if (normalized.startsWith('vmess://')) {
        final b64 = normalized.substring('vmess://'.length).trim();
        final normalizedB64 = base64.normalize(b64);
        final decoded = utf8.decode(base64.decode(normalizedB64));
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final addr = (json['add'] ?? json['host'] ?? '') as String;
        final port = int.tryParse(json['port']?.toString() ?? '443') ?? 443;
        final ps = (json['ps'] ?? '') as String;
        return (address: addr, port: port, remark: ps);
      }

      final uri = Uri.tryParse(normalized);
      if (uri != null) {
        final remark = uri.fragment.isNotEmpty
            ? Uri.decodeFull(uri.fragment.replaceAll('+', '%20'))
            : '';
        return (
          address: uri.host.replaceAll('[', '').replaceAll(']', ''),
          port: uri.hasPort ? uri.port : 443,
          remark: remark,
        );
      }
    } catch (_) {}
    return (address: '', port: 443, remark: '');
  }

  /// ساخت ساختار کامل JSON کانفیگ V2Ray بر پایه هسته رسمی v2rayNG
  static String buildV2rayConfig(String configUri, {String? customRemark}) {
    final normalized = normalizeUri(configUri);

    try {
      if (normalized.startsWith('vless://') || normalized.startsWith('trojan://')) {
        return _buildVlessOrTrojanConfig(normalized, customRemark: customRemark);
      } else if (normalized.startsWith('vmess://')) {
        return _buildVmessConfig(normalized, customRemark: customRemark);
      }
    } catch (_) {}

    // در صورت بروز هر خطای غیرمنتظره، فال‌بک به کتابخانه داخلی
    try {
      final v2rayURL = FlutterV2ray.parseFromURL(normalized);
      return v2rayURL.getFullConfiguration();
    } catch (_) {
      final v2rayURL = FlutterV2ray.parseFromURL(configUri);
      return v2rayURL.getFullConfiguration();
    }
  }

  static String _buildVlessOrTrojanConfig(String normalized, {String? customRemark}) {
    final uri = Uri.parse(normalized);
    final scheme = uri.scheme.toLowerCase();
    final query = uri.queryParameters;

    final address = uri.host.replaceAll('[', '').replaceAll(']', '');
    final port = uri.hasPort ? uri.port : 443;
    final uuid = uri.userInfo;
    final remark = (customRemark != null && customRemark.isNotEmpty)
        ? customRemark
        : (uri.fragment.isNotEmpty
            ? Uri.decodeFull(uri.fragment.replaceAll('+', '%20'))
            : address);

    final transport = (query['type'] ?? 'tcp').toLowerCase();
    final rawSecurity = (query['security'] ?? '').toLowerCase();
    final security = (rawSecurity == 'none' || rawSecurity == '') ? '' : rawSecurity;

    // تمیزکاری و استخراج SNI و Host Header
    var rawHost = (query['host'] ?? '').trim();
    if (rawHost.endsWith('.')) {
      rawHost = rawHost.substring(0, rawHost.length - 1);
    }
    final rawSni = (query['sni'] ?? '').trim();

    // کلیدی: در وب‌سوکت اگر host خالی باشد، باید به sni وگرنه به address فال‌بک کند (نه خالی)
    final wsHost = rawHost.isNotEmpty
        ? rawHost
        : (rawSni.isNotEmpty ? rawSni : (isDomain(address) ? address : ''));

    final sni = rawSni.isNotEmpty
        ? rawSni
        : (rawHost.isNotEmpty ? rawHost : (isDomain(address) ? address : ''));

    final Map<String, dynamic> streamSettings = {
      'network': transport,
      'security': security.isNotEmpty ? security : 'none',
    };

    if (transport == 'ws') {
      var path = query['path'] ?? '/';
      if (!path.startsWith('/')) path = '/$path';

      final Map<String, dynamic> wsSettings = {
        'path': path,
      };
      if (wsHost.isNotEmpty) {
        wsSettings['headers'] = {'Host': wsHost};
      }
      streamSettings['wsSettings'] = wsSettings;
    } else if (transport == 'tcp') {
      final headerType = query['headerType'] ?? 'none';
      if (headerType == 'http') {
        streamSettings['tcpSettings'] = {
          'header': {
            'type': 'http',
            'request': {
              'version': '1.1',
              'method': 'GET',
              'path': ['/'],
              'headers': {
                'Host': [wsHost.isNotEmpty ? wsHost : address],
                'User-Agent': [
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                ],
              }
            }
          }
        };
      } else {
        streamSettings['tcpSettings'] = {
          'header': {'type': 'none'}
        };
      }
    } else if (transport == 'grpc') {
      streamSettings['grpcSettings'] = {
        'serviceName': query['serviceName'] ?? '',
        'multiMode': query['mode'] == 'multi',
      };
    } else if (transport == 'h2' || transport == 'http') {
      streamSettings['network'] = 'h2';
      streamSettings['httpSettings'] = {
        'host': [wsHost.isNotEmpty ? wsHost : address],
        'path': query['path'] ?? '/',
      };
    }

    if (security == 'tls') {
      final alpnStr = query['alpn'] ?? '';
      final alpnList = alpnStr.isNotEmpty
          ? alpnStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
          : ['h2', 'http/1.1'];

      final Map<String, dynamic> tlsSettings = {
        'allowInsecure': true,
        'serverName': sni,
      };
      if (alpnList.isNotEmpty) tlsSettings['alpn'] = alpnList;
      if ((query['fp'] ?? '').isNotEmpty) tlsSettings['fingerprint'] = query['fp'];

      streamSettings['tlsSettings'] = tlsSettings;
    } else if (security == 'reality') {
      // تنظیمات استاندارد REALITY در هسته Xray (بدون allowInsecure)
      final Map<String, dynamic> realitySettings = {
        'show': false,
        'serverName': sni,
        'publicKey': query['pbk'] ?? '',
        'shortId': query['sid'] ?? '',
        'spiderX': query['spx'] ?? '/',
      };
      if ((query['fp'] ?? '').isNotEmpty) {
        realitySettings['fingerprint'] = query['fp'];
      }
      streamSettings['realitySettings'] = realitySettings;
    }

    final Map<String, dynamic> outboundProxy = {
      'tag': 'proxy',
      'protocol': scheme,
      'settings': {},
      'streamSettings': streamSettings,
      'mux': {'enabled': false, 'concurrency': -1},
    };

    if (scheme == 'vless') {
      outboundProxy['settings'] = {
        'vnext': [
          {
            'address': address,
            'port': port,
            'users': [
              {
                'id': uuid,
                'encryption': query['encryption'] ?? 'none',
                'flow': query['flow'] ?? '',
                'level': 8,
              }
            ]
          }
        ]
      };
    } else if (scheme == 'trojan') {
      outboundProxy['settings'] = {
        'servers': [
          {
            'address': address,
            'port': port,
            'password': uuid,
            'level': 8,
          }
        ]
      };
    }

    return _wrapFullConfig(outboundProxy, remark);
  }

  static String _buildVmessConfig(String normalized, {String? customRemark}) {
    final b64 = normalized.substring('vmess://'.length).trim();
    final normalizedB64 = base64.normalize(b64);
    final decoded = utf8.decode(base64.decode(normalizedB64));
    final json = jsonDecode(decoded) as Map<String, dynamic>;

    final address = (json['add'] ?? json['host'] ?? '') as String;
    final port = int.tryParse(json['port']?.toString() ?? '443') ?? 443;
    final uuid = (json['id'] ?? '') as String;
    final aid = int.tryParse(json['aid']?.toString() ?? '0') ?? 0;
    final transport = ((json['net'] ?? 'tcp') as String).toLowerCase();
    final rawSecurity = ((json['tls'] ?? '') as String).toLowerCase();
    final security = (rawSecurity == 'tls') ? 'tls' : 'none';
    final host = (json['host'] ?? '') as String;
    final sni = (json['sni'] ?? host) as String;
    final path = (json['path'] ?? '/') as String;
    final remark = customRemark ?? (json['ps'] ?? address) as String;

    final Map<String, dynamic> streamSettings = {
      'network': transport,
      'security': security,
    };

    if (transport == 'ws') {
      streamSettings['wsSettings'] = {
        'path': path,
        if (host.isNotEmpty) 'headers': {'Host': host},
      };
    }

    if (security == 'tls') {
      streamSettings['tlsSettings'] = {
        'allowInsecure': true,
        'serverName': sni.isNotEmpty ? sni : address,
      };
    }

    final Map<String, dynamic> outboundProxy = {
      'tag': 'proxy',
      'protocol': 'vmess',
      'settings': {
        'vnext': [
          {
            'address': address,
            'port': port,
            'users': [
              {
                'id': uuid,
                'alterId': aid,
                'security': (json['scy'] ?? 'auto') as String,
                'level': 8,
              }
            ]
          }
        ]
      },
      'streamSettings': streamSettings,
      'mux': {'enabled': false, 'concurrency': -1},
    };

    return _wrapFullConfig(outboundProxy, remark);
  }

  static String _wrapFullConfig(Map<String, dynamic> outboundProxy, String remark) {
    final Map<String, dynamic> fullConfig = {
      'log': {'loglevel': 'warning'},
      'inbounds': [
        {
          'tag': 'in_proxy',
          'port': 10808,
          'listen': '127.0.0.1',
          'protocol': 'socks',
          'settings': {
            'auth': 'noauth',
            'udp': true,
            'userLevel': 8,
          },
          'sniffing': {
            'enabled': true,
            'destOverride': ['http', 'tls', 'quic'],
            'metadataOnly': false,
          }
        },
        {
          'tag': 'in_http',
          'port': 10809,
          'listen': '127.0.0.1',
          'protocol': 'http',
          'settings': {
            'userLevel': 8,
          }
        }
      ],
      'outbounds': [
        outboundProxy,
        {
          'tag': 'direct',
          'protocol': 'freedom',
          'settings': {
            'domainStrategy': 'UseIP',
          }
        },
        {
          'tag': 'block',
          'protocol': 'blackhole',
          'settings': {
            'response': {'type': 'http'}
          }
        }
      ],
      'routing': {
        // domainStrategy = AsIs کلید حل اتصال و پینگ در اینترنت مسدود ایران:
        // جلوگیری از ارسال کوئری DNS توسط کلاینت به سرورهای فیلترشده داخل ایران
        'domainStrategy': 'AsIs',
        'rules': []
      },
      'dns': {
        'servers': ['1.1.1.1', '8.8.8.8', 'localhost']
      }
    };

    return const JsonEncoder.withIndent('  ').convert(fullConfig);
  }

  static bool isDomain(String s) {
    if (s.isEmpty) return false;
    return !RegExp(r'^[\d.:]+$').hasMatch(s);
  }
}
