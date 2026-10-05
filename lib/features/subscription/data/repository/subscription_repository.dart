import '../../../../core/services/api_service.dart';
import '../models/subscription_models.dart';

class SubscriptionRepository {
  final ApiService _api;
  SubscriptionRepository({ApiService? api}) : _api = api ?? ApiService();

  // ── Fetch profile ─────────────────────────────────────────

  /// GET /api/users/me — اطلاعات اشتراک کاربر
  Future<SubscriptionModel> fetchSubscription() async {
    final json = await _api.get('/api/users/me', auth: true);
    return SubscriptionModel.fromJson(json);
  }

  // ── Redeem gift code ──────────────────────────────────────

  /// POST /api/giftcodes/redeem — کد هدیه را اعمال می‌کند
  /// در صورت موفقیت GiftCodeResult برمی‌گرداند؛ در غیر این صورت exception
  Future<GiftCodeResult> redeemGiftCode(String code) async {
    final json = await _api.post(
      '/api/giftcodes/redeem',
      {'code': code.trim().toUpperCase()},
      auth: true,
    );
    return GiftCodeResult.fromJson(json);
  }

  // ── Report usage ──────────────────────────────────────────

  /// PATCH /api/users/me/usage — مصرف واقعی را گزارش می‌دهد
  Future<void> reportUsage({
    required double usedGb,
    required double remainingGb,
  }) async {
    await _api.patch(
      '/api/users/me/usage',
      {'used_gb': usedGb, 'remaining_gb': remainingGb},
      auth: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// نتیجه redeem کد هدیه
// ─────────────────────────────────────────────────────────────

class GiftCodeResult {
  final String code;
  final double bonusGb;
  final int bonusDays;
  final String description;

  const GiftCodeResult({
    required this.code,
    required this.bonusGb,
    required this.bonusDays,
    required this.description,
  });

  factory GiftCodeResult.fromJson(Map<String, dynamic> j) {
    return GiftCodeResult(
      code:        j['code']        as String,
      bonusGb:     (j['bonus_gb']   as num).toDouble(),
      bonusDays:   j['bonus_days']  as int,
      description: j['description'] as String,
    );
  }
}
