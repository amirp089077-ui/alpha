/// مدل کامل کاربر — فیلدها با LoginResponse و UserProfile بک‌اند سینک شده
class UserModel {
  final String username;
  final String token;
  final String planType;
  final String status;
  final double remainingGb;
  final double usedGb;
  final double totalQuotaGb;
  final int remainingDays;
  final int totalDays;
  final String expiryDate;
  final int maxDevices;
  final int activeDevices;

  // ── فیلدهای محلی (از بک‌اند نمی‌آیند) ─────────────────────
  /// نام دستگاه فعلی (از DeviceInfo یا مقدار پیش‌فرض)
  final String deviceName;
  /// شناسه دستگاه (می‌تواند آخر ۴ رقم token یا ID دستگاه باشد)
  final String deviceId;

  const UserModel({
    required this.username,
    required this.token,
    required this.planType,
    required this.status,
    required this.remainingGb,
    required this.usedGb,
    required this.totalQuotaGb,
    required this.remainingDays,
    required this.totalDays,
    required this.expiryDate,
    required this.maxDevices,
    required this.activeDevices,
    this.deviceName = 'این دستگاه',
    this.deviceId   = '',
  });

  /// از پاسخ login (LoginResponse) می‌سازد
  factory UserModel.fromLoginJson(Map<String, dynamic> j) {
    final token = j['token'] as String;
    return UserModel(
      username:       j['username']        as String,
      token:          token,
      planType:       j['plan_type']       as String,
      status:         j['status']          as String,
      remainingGb:    (j['remaining_gb']   as num).toDouble(),
      usedGb:         (j['used_gb']        as num).toDouble(),
      totalQuotaGb:   (j['total_quota_gb'] as num).toDouble(),
      remainingDays:  j['remaining_days']  as int,
      totalDays:      j['total_days']      as int,
      expiryDate:     j['expiry_date']     as String,
      maxDevices:     j['max_devices']     as int,
      activeDevices:  j['active_devices']  as int,
      // آخر ۴ کاراکتر توکن به عنوان device ID نمایشی
      deviceId: token.length >= 4 ? token.substring(token.length - 4) : token,
    );
  }

  /// از پاسخ GET /api/users/me (UserProfile) می‌سازد
  factory UserModel.fromProfileJson(Map<String, dynamic> j, String token) {
    return UserModel(
      username:       j['username']        as String,
      token:          token,
      planType:       j['plan_type']       as String,
      status:         j['status']          as String,
      remainingGb:    (j['remaining_gb']   as num).toDouble(),
      usedGb:         (j['used_gb']        as num).toDouble(),
      totalQuotaGb:   (j['total_quota_gb'] as num).toDouble(),
      remainingDays:  j['remaining_days']  as int,
      totalDays:      j['total_days']      as int,
      expiryDate:     j['expiry_date']     as String,
      maxDevices:     j['max_devices']     as int,
      activeDevices:  j['active_devices']  as int,
      deviceId: token.length >= 4 ? token.substring(token.length - 4) : token,
    );
  }

  UserModel copyWith({
    String?  username,
    String?  token,
    String?  planType,
    String?  status,
    double?  remainingGb,
    double?  usedGb,
    double?  totalQuotaGb,
    int?     remainingDays,
    int?     totalDays,
    String?  expiryDate,
    int?     maxDevices,
    int?     activeDevices,
    String?  deviceName,
    String?  deviceId,
  }) {
    return UserModel(
      username:      username      ?? this.username,
      token:         token         ?? this.token,
      planType:      planType      ?? this.planType,
      status:        status        ?? this.status,
      remainingGb:   remainingGb   ?? this.remainingGb,
      usedGb:        usedGb        ?? this.usedGb,
      totalQuotaGb:  totalQuotaGb  ?? this.totalQuotaGb,
      remainingDays: remainingDays ?? this.remainingDays,
      totalDays:     totalDays     ?? this.totalDays,
      expiryDate:    expiryDate    ?? this.expiryDate,
      maxDevices:    maxDevices    ?? this.maxDevices,
      activeDevices: activeDevices ?? this.activeDevices,
      deviceName:    deviceName    ?? this.deviceName,
      deviceId:      deviceId      ?? this.deviceId,
    );
  }

  /// آیا اشتراک فعال است؟
  bool get isActive => status == 'ACTIVE';

  /// درصد حجم باقی‌مانده (0.0 – 1.0)
  double get volumeProgress =>
      totalQuotaGb > 0 ? (remainingGb / totalQuotaGb).clamp(0.0, 1.0) : 0.0;

  /// درصد زمان باقی‌مانده (0.0 – 1.0)
  double get timeProgress =>
      totalDays > 0 ? (remainingDays / totalDays).clamp(0.0, 1.0) : 0.0;
}

// ─────────────────────────────────────────────────────────────

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

  AuthState copyWith({
    AuthStatus? status,
    UserModel?  user,
    String?     errorMessage,
  }) {
    return AuthState(
      status:       status       ?? this.status,
      user:         user         ?? this.user,
      errorMessage: errorMessage,
    );
  }
}
