import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/services/api_service.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final ApiService _api;
  static const _storage = FlutterSecureStorage();
  static const _userCacheKey = 'alpha_vpn_cached_user';

  AuthRepository({ApiService? api}) : _api = api ?? ApiService();

  // ── Cache management ──────────────────────────────────────

  Future<void> saveCachedUser(UserModel user) async {
    try {
      await _storage.write(
        key: _userCacheKey,
        value: jsonEncode(user.toJson()),
      );
    } catch (_) {}
  }

  Future<UserModel?> getCachedUser() async {
    try {
      final raw = await _storage.read(key: _userCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final j = jsonDecode(raw);
        if (j is Map<String, dynamic>) {
          return UserModel.fromJson(j);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> deleteCachedUser() async {
    try {
      await _storage.delete(key: _userCacheKey);
    } catch (_) {}
  }

  // ── Login ─────────────────────────────────────────────────

  /// ورود به بک‌اند — توکن را ذخیره می‌کند و UserModel برمی‌گرداند
  Future<UserModel> login(String username, String password) async {
    final json = await _api.post(
      '/api/auth/login',
      {'username': username, 'password': password},
      auth: false,
    );
    final user = UserModel.fromLoginJson(json);
    await _api.saveToken(user.token);
    await saveCachedUser(user);
    return user;
  }

  // ── Restore session ───────────────────────────────────────

  /// اگر توکن ذخیره‌شده‌ای وجود دارد پروفایل را می‌گیرد؛ در غیر این صورت null
  Future<UserModel?> restoreSession() async {
    final token = await _api.getToken();
    if (token == null || token.isEmpty) {
      await deleteCachedUser();
      return null;
    }

    try {
      final json = await _api.get('/api/users/me', auth: true);
      final user = UserModel.fromProfileJson(json, token);
      await saveCachedUser(user);
      return user;
    } on UnauthorizedException {
      // فقط زمانی که سرور 401 بدهد یعنی توکن باطل است — پاک می‌کنیم
      await _api.deleteToken();
      await deleteCachedUser();
      return null;
    } catch (_) {
      // در صورت هرگونه خطای شبکه، قطعی اینترنت، تایم‌اوت یا خطای موقت سرور:
      // کاربر به هیچ وجه نباید از حساب خارج شود! اطلاعات ذخیره‌شده محلی را برمی‌گردانیم.
      final cached = await getCachedUser();
      if (cached != null) {
        return cached;
      }
      return UserModel(
        username: 'کاربر',
        token: token,
        planType: 'SINGLE_USER',
        status: 'ACTIVE',
        remainingGb: 0,
        usedGb: 0,
        totalQuotaGb: 0,
        remainingDays: 0,
        totalDays: 0,
        expiryDate: '',
        maxDevices: 1,
        activeDevices: 0,
      );
    }
  }

  // ── Logout ────────────────────────────────────────────────

  /// از بک‌اند خارج می‌شود و توکن محلی را حذف می‌کند
  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout', {}, auth: true);
    } catch (_) {
      // حتی اگر بک‌اند جواب نداد، توکن محلی را پاک می‌کنیم
    } finally {
      await _api.deleteToken();
      await deleteCachedUser();
    }
  }
}

