import '../../../../core/services/api_service.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final ApiService _api;
  AuthRepository({ApiService? api}) : _api = api ?? ApiService();

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
    return user;
  }

  // ── Restore session ───────────────────────────────────────

  /// اگر توکن ذخیره‌شده‌ای وجود دارد پروفایل را می‌گیرد؛ در غیر این صورت null
  Future<UserModel?> restoreSession() async {
    final token = await _api.getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final json = await _api.get('/api/users/me', auth: true);
      return UserModel.fromProfileJson(json, token);
    } on UnauthorizedException {
      // توکن منقضی شده — پاک می‌کنیم
      await _api.deleteToken();
      return null;
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
    }
  }
}
