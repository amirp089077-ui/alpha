import '../models/subscription_models.dart';

class MockSubscriptionRepository {
  Future<SubscriptionModel> fetchSubscription() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return SubscriptionModel(
      usedGb:     23.9,
      totalGb:    58.0,
      usedDays:   123,
      totalDays:  140,
      expiryDate: DateTime(2026, 10, 20), // 29 مهر ۱۴۰۵
    );
  }

  Future<bool> redeemGiftCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // Simulate success only for 'ALPHA2025'
    if (code.toUpperCase() == 'ALPHA2025') return true;
    throw Exception('invalid_code');
  }
}
