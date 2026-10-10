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

  String _currentUsername = '';
  int _lastUpload   = 0;
  int _lastDownload = 0;
  int _pendingBytes = 0;

  bool _reporting = false;

  double _limitGb = 0;
  double _usedGb  = 0;

  VoidCallback? onLimitReached;

  String _lastReportedKey(String username) =>
      username.isNotEmpty ? 'usage_last_reported_${username}_gb' : _kLastReportedUsed;
  String _pendingBytesKey(String username) =>
      username.isNotEmpty ? 'usage_pending_bytes_$username' : _kPendingBytes;
  String _lastReportTimeKey(String username) =>
      username.isNotEmpty ? 'usage_last_report_$username' : _kLastReportTime;

  /// پاک‌سازی کامل وضعیت سرویس در زمان خروج یا تغییر اکانت
  void reset({String? newUsername}) {
    _timer?.cancel();
    _timer = null;
    _currentUsername = newUsername ?? '';
    _lastUpload = 0;
    _lastDownload = 0;
    _pendingBytes = 0;
    _reporting = false;
    _limitGb = 0;
    _usedGb = 0;
    onLimitReached = null;
  }

  // ── Start ────────────────────────────────────────────────
  Future<void> start({
    required double limitGb,
    required double usedGb,
    required VoidCallback onLimitReached,
    String? username,
  }) async {
    if (username != null && username.isNotEmpty && _currentUsername != username) {
      reset(newUsername: username);
    } else if (username != null && username.isNotEmpty) {
      _currentUsername = username;
    }

    _limitGb            = limitGb;
    this.onLimitReached = onLimitReached;
    _lastUpload         = 0;
    _lastDownload       = 0;
    _reporting          = false;

    final prefs        = await SharedPreferences.getInstance();
    final lastReported = prefs.getDouble(_lastReportedKey(_currentUsername)) ?? 0.0;
    final savedPending = prefs.getInt(_pendingBytesKey(_currentUsername)) ?? 0;

    // usedGb برای همین کاربر
    _usedGb = [usedGb, lastReported].reduce((a, b) => a > b ? a : b);
    _pendingBytes = savedPending;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _tick());
  }

  // ── Stop + flush فوری ────────────────────────────────────
  Future<void> stop({bool flush = false}) async {
    _timer?.cancel();
    _timer = null;

    if (flush && _pendingBytes > 0) {
      await _tick(force: true);
    }

    final prefs = await SharedPreferences.getInstance();
    final pendingKey = _pendingBytesKey(_currentUsername);
    if (_pendingBytes > 0) {
      await prefs.setInt(pendingKey, _pendingBytes);
    } else {
      await prefs.remove(pendingKey);
    }
  }

  // ── updateStats ───────────────────────────────────────────
  void updateStats(VpnStats stats) {
    final deltaUp   = (stats.upload   - _lastUpload).clamp(0, double.maxFinite).toInt();
    final deltaDown = (stats.download - _lastDownload).clamp(0, double.maxFinite).toInt();
    _lastUpload   = stats.upload;
    _lastDownload = stats.download;
    _pendingBytes += deltaUp + deltaDown;

    _maybePersistPending();
  }

  int _persistCounter = 0;
  void _maybePersistPending() {
    _persistCounter++;
    if (_persistCounter % 10 == 0) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt(_pendingBytesKey(_currentUsername), _pendingBytes);
      });
    }
  }

  void updateLimit({required double limitGb, required double usedGb, String? username}) {
    if (username != null && username.isNotEmpty && _currentUsername != username) {
      reset(newUsername: username);
    } else if (username != null && username.isNotEmpty) {
      _currentUsername = username;
    }
    _limitGb = limitGb;
    _usedGb = usedGb;
  }

  // ── getters ──────────────────────────────────────────────
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

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingBytesKey(_currentUsername));

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
    final lastReported = prefs.getDouble(_lastReportedKey(_currentUsername)) ?? 0.0;

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

    await prefs.setDouble(_lastReportedKey(_currentUsername), safeUsedGb);
    await prefs.setInt(_lastReportTimeKey(_currentUsername), DateTime.now().millisecondsSinceEpoch);
  }

  static Future<double> getLocalUsedGb([String? username]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = (username != null && username.isNotEmpty)
        ? 'usage_last_reported_${username}_gb'
        : 'usage_last_reported_used_gb';
    return prefs.getDouble(key) ?? 0.0;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final usageServiceProvider = Provider<UsageService>((_) => UsageService());
