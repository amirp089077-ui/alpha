import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'vpn_service.dart';

// ── Keys ──────────────────────────────────────────────────────────────────────

const _kUsedBytes        = 'usage_used_bytes';
const _kLastReportTime   = 'usage_last_report';
const _kLastReportedUsed = 'usage_last_reported_used_gb'; // آخرین used_gb که به API فرستادیم

// ── UsageService ──────────────────────────────────────────────────────────────

/// سرویس ردیابی حجم مصرفی:
/// - هر ۶۰ ثانیه آمار VPN رو جمع می‌کنه
/// - به API گزارش می‌فرسته
/// - اگه به سقف رسید VPN رو قطع می‌کنه
class UsageService {
  static final UsageService _instance = UsageService._internal();
  factory UsageService() => _instance;
  UsageService._internal();

  final _api = ApiService();

  Timer? _timer;

  // آخرین مقدار bytes که از VpnStats خوندیم
  int _lastUpload   = 0;
  int _lastDownload = 0;

  // کل bytes این session که هنوز گزارش ندادیم
  int _pendingBytes = 0;

  // آیا در حال گزارش دادن هستیم (از overlap جلوگیری کن)
  bool _reporting = false;

  // سقف حجم (bytes) — از auth/subscription میاد
  double _limitGb    = 0;  // 0 = بی‌نهایت
  double _usedGb     = 0;

  // callback برای قطع VPN وقتی سقف رسید
  VoidCallback? onLimitReached;

  // ── Start / Stop ──────────────────────────────────────────

  void start({
    required double limitGb,
    required double usedGb,
    required VoidCallback onLimitReached,
  }) {
    _limitGb            = limitGb;
    // usedGb باید حداقل برابر آخرین مقداری باشه که به API فرستادیم
    // این جلوگیری می‌کنه از اینکه بعد از restart مقدار به عقب برگرده
    _loadLastReportedUsed().then((lastReported) {
      _usedGb = usedGb > lastReported ? usedGb : lastReported;
    });
    _usedGb             = usedGb;
    this.onLimitReached = onLimitReached;
    _lastUpload         = 0;
    _lastDownload       = 0;
    _pendingBytes       = 0;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _tick());
  }

  Future<double> _loadLastReportedUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kLastReportedUsed) ?? 0.0;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// آپدیت stats از VpnStats stream
  void updateStats(VpnStats stats) {
    final deltaUp   = (stats.upload   - _lastUpload).clamp(0, double.maxFinite).toInt();
    final deltaDown = (stats.download - _lastDownload).clamp(0, double.maxFinite).toInt();

    _lastUpload   = stats.upload;
    _lastDownload = stats.download;
    _pendingBytes += deltaUp + deltaDown;
  }

  /// آپدیت سقف و مقدار مصرف‌شده (از auth refresh)
  void updateLimit({required double limitGb, required double usedGb}) {
    _limitGb = limitGb;
    _usedGb  = usedGb;
  }

  // ── Tick هر ۶۰ ثانیه ─────────────────────────────────────

  Future<void> _tick() async {
    if (_pendingBytes <= 0) return;
    if (_reporting) return;
    _reporting = true;

    try {
      final pendingGb  = _pendingBytes / (1024 * 1024 * 1024);
      final newUsedGb  = _usedGb + pendingGb;

      // گزارش به API
      await _reportToApi(usedGb: newUsedGb);

      // ذخیره local
      await _saveLocal(usedGb: newUsedGb);

      _usedGb       = newUsedGb;
      _pendingBytes = 0;

      // چک سقف
      if (_limitGb > 0 && _usedGb >= _limitGb) {
        onLimitReached?.call();
      }
    } catch (_) {
      // سایلنت fail — دوباره در tick بعدی تلاش می‌کنیم
    } finally {
      _reporting = false;
    }
  }

  // ── گزارش به API ──────────────────────────────────────────

  Future<void> _reportToApi({required double usedGb}) async {
    try {
      // خوندن آخرین used_gb که به API فرستادیم
      final prefs = await SharedPreferences.getInstance();
      final lastReported = prefs.getDouble(_kLastReportedUsed) ?? 0.0;

      // validation: used_gb هرگز نباید از آخرین مقدار ارسالی کمتر بشه
      // اگه کوچکتر بود یعنی چیزی اشتباه شده — مقدار قدیمی رو نگه دار
      final safeUsedGb = usedGb < lastReported ? lastReported : usedGb;
      final remainingGb = (_limitGb - safeUsedGb).clamp(0.0, double.maxFinite);

      await _api.patch(
        '/api/users/me/usage',
        {
          'used_gb':      double.parse(safeUsedGb.toStringAsFixed(4)),
          'remaining_gb': double.parse(remainingGb.toStringAsFixed(4)),
        },
        auth: true,
      );

      // ذخیره آخرین مقدار ارسالی
      await prefs.setDouble(_kLastReportedUsed, safeUsedGb);
      await prefs.setInt(_kLastReportTime, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // سایلنت fail — دوباره در tick بعدی تلاش می‌کنیم
    }
  }

  // ── ذخیره local ───────────────────────────────────────────

  Future<void> _saveLocal({required double usedGb}) async {
    final prefs = await SharedPreferences.getInstance();
    // ذخیره به صورت bytes برای دقت بیشتر
    final usedBytes = (usedGb * 1024 * 1024 * 1024).toInt();
    await prefs.setInt(_kUsedBytes, usedBytes);
  }

  // ── چک سقف قبل از اتصال ──────────────────────────────────

  /// true = حجم کافی داره، false = تموم شده
  Future<bool> checkQuota({
    required double limitGb,
    required double usedGb,
  }) async {
    if (limitGb <= 0) return true; // بی‌نهایت
    return usedGb < limitGb;
  }

  // ── گرفتن آخرین مقدار مصرف local ────────────────────────

  static Future<double> getLocalUsedGb() async {
    final prefs = await SharedPreferences.getInstance();
    final bytes = prefs.getInt(_kUsedBytes) ?? 0;
    return bytes / (1024 * 1024 * 1024);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final usageServiceProvider = Provider<UsageService>((_) => UsageService());
