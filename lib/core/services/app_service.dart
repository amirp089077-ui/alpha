import 'package:flutter/services.dart';

/// سرویس ارتباط با Android برای گرفتن لیست برنامه‌های نصب‌شده
class AppService {
  static const _channel = MethodChannel('com.alphavpn/apps');

  static final AppService _instance = AppService._internal();
  factory AppService() => _instance;
  AppService._internal();

  /// لیست برنامه‌های نصب‌شده روی گوشی رو برمیگردونه
  /// هر آیتم شامل: packageName, appName, isSystem, icon (Uint8List)
  Future<List<InstalledApp>> getInstalledApps() async {
    final List<dynamic> result =
        await _channel.invokeMethod('getInstalledApps');

    return result.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return InstalledApp(
        packageName: map['packageName'] as String,
        appName: map['appName'] as String,
        isSystem: map['isSystem'] as bool? ?? false,
        iconBytes: map['icon'] as Uint8List?,
      );
    }).toList();
  }
}

class InstalledApp {
  final String packageName;
  final String appName;
  final bool isSystem;

  /// PNG bytes آیکون — ممکنه null باشه اگه آیکون دریافت نشد
  final Uint8List? iconBytes;

  const InstalledApp({
    required this.packageName,
    required this.appName,
    this.isSystem = false,
    this.iconBytes,
  });
}
