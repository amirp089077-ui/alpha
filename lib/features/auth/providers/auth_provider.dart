import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock/mock_auth_repository.dart';
import '../data/models/auth_models.dart';

final authRepositoryProvider = Provider((_) => MockAuthRepository());

class AuthNotifier extends StateNotifier<AuthState> {
  final MockAuthRepository _repo;
  AuthNotifier(this._repo) : super(const AuthState());

  Future<void> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repo.login(username, password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on Exception catch (e) {
      final msg = e.toString().contains('invalid')
          ? 'نام کاربری یا رمز عبور اشتباه است'
          : 'خطا در اتصال به شبکه';
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
