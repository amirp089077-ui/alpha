class UserModel {
  final String username;
  final String deviceId;
  final String deviceName;

  const UserModel({
    required this.username,
    required this.deviceId,
    required this.deviceName,
  });

  UserModel copyWith({String? username, String? deviceId, String? deviceName}) {
    return UserModel(
      username:   username   ?? this.username,
      deviceId:   deviceId   ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
    );
  }
}

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({AuthStatus? status, UserModel? user, String? errorMessage}) {
    return AuthState(
      status:       status       ?? this.status,
      user:         user         ?? this.user,
      errorMessage: errorMessage,
    );
  }
}
