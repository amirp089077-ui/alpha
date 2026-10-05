import '../models/auth_models.dart';

class MockAuthRepository {
  static const _validUsername = 'mehdi06';
  static const _validPassword = '1234';
  // ignore: prefer_final_fields
  static bool _simulateError = false;

  static const _mockUser = UserModel(
    username:   'mehdi06',
    deviceId:   '3696',
    deviceName: 'poco i',
  );

  Future<UserModel> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (_simulateError) throw Exception('Network error');
    if (username == _validUsername && password == _validPassword) {
      return _mockUser;
    }
    throw Exception('invalid_credentials');
  }

  Future<UserModel?> getStoredUser() async {
    await Future.delayed(const Duration(milliseconds: 400));
    // In real app, read from SharedPreferences / secure storage
    return null;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
