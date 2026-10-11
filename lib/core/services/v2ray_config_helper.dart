import 'package:flutter_v2ray/flutter_v2ray.dart';

class V2rayConfigHelper {
  /// نرمال‌سازی لینک‌های IPv6 خام بدون براکت (جلوگیری از خطای FormatException در Uri.parse)
  static String normalizeUri(String raw) {
    var url = raw.trim();
    final atIdx = url.indexOf('@');
    if (atIdx != -1) {
      int endIdx = url.indexOf('?', atIdx);
      if (endIdx == -1) endIdx = url.indexOf('#', atIdx);
      if (endIdx == -1) endIdx = url.length;
      final hostPort = url.substring(atIdx + 1, endIdx);
      if (!hostPort.startsWith('[')) {
        final lastColon = hostPort.lastIndexOf(':');
        if (lastColon != -1) {
          final hostPart = hostPort.substring(0, lastColon);
          final portPart = hostPort.substring(lastColon + 1);
          if (hostPart.contains(':')) {
            url = '${url.substring(0, atIdx + 1)}[$hostPart]:$portPart${url.substring(endIdx)}';
          }
        }
      }
    }
    return url;
  }

  /// پارس استاندارد کانفیگ بر طبق مستندات رسمی flutter_v2ray
  static V2RayURL parseConfig(String configUri) {
    final normalized = normalizeUri(configUri);
    final parser = FlutterV2ray.parseFromURL(normalized);

    // طبق بخش Edit Configuration در مستندات رسمی:
    // ۱. اصلاح هدر Host در وب‌سوکت اگر خالی باشد (ضروری برای اتصال سرورهای Cloudflare و Fastly)
    if (parser.streamSetting['wsSettings'] != null) {
      final wsHeaders = parser.streamSetting['wsSettings']['headers'];
      if (wsHeaders is Map &&
          (wsHeaders['Host'] == null || wsHeaders['Host'].toString().trim().isEmpty)) {
        final sni = parser.streamSetting['tlsSettings']?['serverName'] ??
                    parser.streamSetting['realitySettings']?['serverName'] ??
                    parser.address;
        if (sni != null && sni.toString().isNotEmpty) {
          wsHeaders['Host'] = sni.toString();
        }
      }
    }

    // ۲. تنظیم DNS با IPهای معتبر برای سازگاری کامل با VpnService در اندروید
    parser.dns = {
      "servers": ["1.1.1.1", "8.8.8.8"]
    };

    return parser;
  }

  /// استخراج آدرس سرور، پورت و ریمارک
  static ({String address, int port, String remark}) parseEndpoint(String configUri) {
    try {
      final parser = parseConfig(configUri);
      return (
        address: parser.address,
        port: parser.port,
        remark: parser.remark,
      );
    } catch (_) {
      return (address: '', port: 443, remark: '');
    }
  }

  /// ساخت کانفیگ کامل جیسون بر اساس مستندات رسمی flutter_v2ray
  static String buildV2rayConfig(String configUri, {String? customRemark}) {
    try {
      final parser = parseConfig(configUri);
      return parser.getFullConfiguration();
    } catch (_) {
      final parser = FlutterV2ray.parseFromURL(configUri);
      return parser.getFullConfiguration();
    }
  }
}
