import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/usage_service.dart';
import '../../../features/home/providers/home_provider.dart';
import '../data/models/auth_models.dart';
import '../data/repository/auth_repository.dart';

// ── Repository provider ────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(),
);

// ── Notifier ───────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AuthState()) {
    _restoreSession();
  }

  // بررسی توکن ذخیره‌شده هنگام اجرا
  Future<void> _restoreSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repo.restoreSession();
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      // در صورت هرگونه خطا، اگر کاربر ذخیره‌شده‌ای داریم لاگ‌اوت نکن
      final cached = await _repo.getCachedUser();
      if (cached != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: cached);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    }
  }

  // ── Login ────────────────────────────────────────────────

  Future<void> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repo.login(username.trim(), password.trim());
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on ForbiddenException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } on UnauthorizedException {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'نام کاربری یا رمز عبور اشتباه است',
      );
    } on NetworkException {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'اتصال به اینترنت برقرار نیست',
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'خطای ناشناخته‌ای رخ داد',
      );
    }
  }

  // ── Logout ───────────────────────────────────────────────

  Future<void> logout() async {
    // اول VPN رو قطع کن، بعد session رو پاک کن
    try {
      final vpn = _ref.read(vpnServiceProvider);
      vpn.disconnect();
    } catch (_) {}

    try {
      _ref.read(usageServiceProvider).reset();
    } catch (_) {}

    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // ── Refresh profile ──────────────────────────────────────

  /// پروفایل را از سرور دوباره می‌خواند (بعد از redeem کد هدیه و ...)
  Future<void> refreshProfile() async {
    final current = state.user;
    if (current == null) return;
    try {
      final updated = await _repo.restoreSession();
      if (updated != null) {
        state = state.copyWith(user: updated);
      }
    } catch (_) {}
  }

  void clearError() {
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }
}

// ── Provider ───────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

/// shorthand برای دسترسی سریع به UserModel در widget ها
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
