/// مدل اشتراک — از UserProfile بک‌اند ساخته می‌شود
class SubscriptionModel {
  final double remainingGb;
  final double usedGb;
  final double totalQuotaGb;
  final int remainingDays;
  final int totalDays;
  final DateTime expiryDate;   // تبدیل‌شده به DateTime برای formatJalaliDate
  final String expiryDateStr;  // رشته خام از بک‌اند (مثلاً «1404-07-29»)
  final String planType;
  final String status;
  final int maxDevices;
  final int activeDevices;

  const SubscriptionModel({
    required this.remainingGb,
    required this.usedGb,
    required this.totalQuotaGb,
    required this.remainingDays,
    required this.totalDays,
    required this.expiryDate,
    required this.expiryDateStr,
    required this.planType,
    required this.status,
    required this.maxDevices,
    required this.activeDevices,
  });

  /// از پاسخ GET /api/users/me (UserProfile)
  factory SubscriptionModel.fromJson(Map<String, dynamic> j) {
    final dateStr = j['expiry_date'] as String? ?? '';
    return SubscriptionModel(
      remainingGb:   (j['remaining_gb']   as num).toDouble(),
      usedGb:        (j['used_gb']        as num).toDouble(),
      totalQuotaGb:  (j['total_quota_gb'] as num).toDouble(),
      remainingDays: j['remaining_days']  as int,
      totalDays:     j['total_days']      as int,
      expiryDate:    _parseDate(dateStr),
      expiryDateStr: dateStr,
      planType:      j['plan_type']       as String,
      status:        j['status']          as String,
      maxDevices:    j['max_devices']     as int,
      activeDevices: j['active_devices']  as int,
    );
  }

  /// تبدیل رشته تاریخ میلادی (YYYY-MM-DD) به DateTime
  static DateTime _parseDate(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.now().add(const Duration(days: 30));
    }
  }

  // ── Backward-compat alias ──────────────────────────────────
  /// alias برای totalQuotaGb — برای سازگاری با کدهای قدیمی
  double get totalGb => totalQuotaGb;

  // ── Computed ───────────────────────────────────────────────

  /// درصد حجم باقی‌مانده (0.0 – 1.0)
  double get volumeProgress =>
      totalQuotaGb > 0 ? (remainingGb / totalQuotaGb).clamp(0.0, 1.0) : 0.0;

  /// درصد زمان باقی‌مانده (0.0 – 1.0)
  double get timeProgress =>
      totalDays > 0 ? (remainingDays / totalDays).clamp(0.0, 1.0) : 0.0;

  bool get isLowVolume => volumeProgress < 0.15;
  bool get isLowTime   => timeProgress   < 0.15;
  bool get isActive    => status == 'ACTIVE';

  SubscriptionModel copyWith({
    double? remainingGb,
    double? usedGb,
    double? totalQuotaGb,
    int?    remainingDays,
    int?    totalDays,
    DateTime? expiryDate,
    String? expiryDateStr,
    String? planType,
    String? status,
    int?    maxDevices,
    int?    activeDevices,
  }) {
    return SubscriptionModel(
      remainingGb:   remainingGb   ?? this.remainingGb,
      usedGb:        usedGb        ?? this.usedGb,
      totalQuotaGb:  totalQuotaGb  ?? this.totalQuotaGb,
      remainingDays: remainingDays ?? this.remainingDays,
      totalDays:     totalDays     ?? this.totalDays,
      expiryDate:    expiryDate    ?? this.expiryDate,
      expiryDateStr: expiryDateStr ?? this.expiryDateStr,
      planType:      planType      ?? this.planType,
      status:        status        ?? this.status,
      maxDevices:    maxDevices    ?? this.maxDevices,
      activeDevices: activeDevices ?? this.activeDevices,
    );
  }
}

// ─────────────────────────────────────────────────────────────

class SubscriptionState {
  final bool isLoading;
  final SubscriptionModel? subscription;
  final String? errorMessage;
  final bool giftCodeExpanded;
  final bool giftCodeLoading;
  final String? giftCodeResult; // 'success' | 'error' | null

  const SubscriptionState({
    this.isLoading = false,
    this.subscription,
    this.errorMessage,
    this.giftCodeExpanded = false,
    this.giftCodeLoading = false,
    this.giftCodeResult,
  });

  SubscriptionState copyWith({
    bool?               isLoading,
    SubscriptionModel?  subscription,
    String?             errorMessage,
    bool?               giftCodeExpanded,
    bool?               giftCodeLoading,
    String?             giftCodeResult,
  }) {
    return SubscriptionState(
      isLoading:        isLoading        ?? this.isLoading,
      subscription:     subscription     ?? this.subscription,
      errorMessage:     errorMessage,
      giftCodeExpanded: giftCodeExpanded ?? this.giftCodeExpanded,
      giftCodeLoading:  giftCodeLoading  ?? this.giftCodeLoading,
      giftCodeResult:   giftCodeResult,
    );
  }
}
