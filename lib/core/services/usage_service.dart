import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'vpn_service.dart';

// ── Keys ──────────────────────────────────────────────────────────────────────

const _kLastReportedUsed    = 'usage_last_reported_used_gb';
const _kPendingBytes        = 'usage_pending_bytes';         // تسک ۳: persist pending
const _kLastReportTime      = 'usage_last_report';

// ── UsageService ──────────────────────────────────────────────────────────────

class UsageService {
  static final UsageService _instance = UsageService._internal();
  factory UsageService() => _instance;
  UsageService._internal();

  final _api = ApiService();

  Timer? _timer;

  int _lastUpload   = 0;
  int _lastDownload = 0;
  int _pendingBytes = 0;

  bool _reporting = false;

  double _limitGb = 0;
  double _usedGb  = 0;

  VoidCallback? onLimitReached;

  // ── Start — async تا data race نباشه ─────────────────────

  // تسک ۱: start رو async کردیم تا lastReported رو await کنه
  // قبلاً: .then() همیشه توسط خط بعدی `_usedGb = usedGb` overwrite می‌شد
  Future<void> start({
    required double limitGb,
    required double usedGb,
    required VoidCallback onLimitReached,
  }) async {
    _limitGb            = limitGb;
    this.onLimitReached = onLimitReached;
    _lastUpload         = 0;
    _lastDownload       = 0;
    _reporting          = false;

    // تسک ۱: await کن تا lastReported درست لود بشه
    final prefs        = await SharedPreferences.getInstance();
    final lastReported = prefs.getDouble(_kLastReportedUsed) ?? 0.0;

    // تسک ۳: pending bytes از session قبلی رو restore کن
    final savedPending = prefs.getInt(_kPendingBytes) ?? 0;

    // usedGb باید حداقل برابر آخرین مقدار ارسالی به API باشه
    _usedGb = [usedGb, lastReported].reduce((a, b) => a > b ? a : b);

    // pending bytes از کرش قبلی رو اضافه کن
    _pendingBytes = savedPending;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _tick());
  }

  // ── Stop + flush فوری ────────────────────────────────────

  // تسک ۳: موقع disconnect، pending bytes رو فوری flush کن
  Future<void> stop({bool flush = false}) async {
    _timer?.cancel();
    _timer   = null;

    if (flush && _pendingBytes > 0) {
      await _tick(force: true);
    }

    // pending bytes رو persist کن (اگه flush ناموفق بود)
    if (_pendingBytes > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kPendingBytes, _pendingBytes);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPendingBytes);
    }
  }

  // ── updateStats ───────────────────────────────────────────

  void updateStats(VpnStats stats) {
    final deltaUp   = (stats.upload   - _lastUpload).clamp(0, double.maxFinite).toInt();
    final deltaDown = (stats.download - _lastDownload).clamp(0, double.maxFinite).toInt();
    _lastUpload   = stats.upload;
    _lastDownload = stats.download;
    _pendingBytes += deltaUp + deltaDown;

    // تسک ۳: هر ۱۰ ثانیه یه بار pending رو persist کن
    // (جلوگیری از از دست رفتن bytes در صورت crash)
    _maybePersistPending();
  }

  int _persistCounter = 0;
  void _maybePersistPending() {
    _persistCounter++;
    if (_persistCounter % 10 == 0) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt(_kPendingBytes, _pendingBytes);
      });
    }
  }

  void updateLimit({required double limitGb, required double usedGb}) {
    _limitGb = limitGb;
    // فقط اگه مقدار جدید بیشتره update کن (جلوگیری از رفتن به عقب)
    if (usedGb > _usedGb) _usedGb = usedGb;
  }

  // ── getter برای تسک ۲ ────────────────────────────────────

  /// مقدار دقیق used_gb که UsageService داره — شامل pending session
  double get currentUsedGb {
    final pendingGb = _pendingBytes / (1024 * 1024 * 1024);
    return _usedGb + pendingGb;
  }

  bool get isQuotaExceeded =>
      _limitGb > 0 && currentUsedGb >= _limitGb;

  // ── Tick ─────────────────────────────────────────────────

  Future<void> _tick({bool force = false}) async {
    if (_pendingBytes <= 0 && !force) return;
    if (_reporting) return;
    _reporting = true;

    try {
      final pendingGb = _pendingBytes / (1024 * 1024 * 1024);
      final newUsedGb = _usedGb + pendingGb;

      await _reportToApi(usedGb: newUsedGb);

      _usedGb       = newUsedGb;
      _pendingBytes = 0;

      // پاک کردن pending از SharedPreferences بعد از flush موفق
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPendingBytes);

      // چک سقف
      if (_limitGb > 0 && _usedGb >= _limitGb) {
        onLimitReached?.call();
      }
    } catch (_) {
      // سایلنت fail — دوباره در tick بعدی
    } finally {
      _reporting = false;
    }
  }

  // ── گزارش به API ──────────────────────────────────────────

  Future<void> _reportToApi({required double usedGb}) async {
    final prefs        = await SharedPreferences.getInstance();
    final lastReported = prefs.getDouble(_kLastReportedUsed) ?? 0.0;

    // مطمئن شو used_gb هرگز کاهش پیدا نمی‌کنه
    final safeUsedGb  = usedGb < lastReported ? lastReported : usedGb;
    final remainingGb = (_limitGb - safeUsedGb).clamp(0.0, double.maxFinite);

    await _api.patch(
      '/api/users/me/usage',
      {
        'used_gb':      double.parse(safeUsedGb.toStringAsFixed(4)),
        'remaining_gb': double.parse(remainingGb.toStringAsFixed(4)),
      },
      auth: true,
    );

    await prefs.setDouble(_kLastReportedUsed, safeUsedGb);
    await prefs.setInt(_kLastReportTime, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<double> getLocalUsedGb() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kLastReportedUsed) ?? 0.0;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final usageServiceProvider = Provider<UsageService>((_) => UsageService());
