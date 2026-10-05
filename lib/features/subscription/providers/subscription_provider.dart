import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../data/models/subscription_models.dart';
import '../data/repository/subscription_repository.dart';

// ── Repository provider ────────────────────────────────────

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (_) => SubscriptionRepository(),
);

// ── Notifier ───────────────────────────────────────────────

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionRepository _repo;

  SubscriptionNotifier(this._repo) : super(const SubscriptionState()) {
    load();
  }

  // ── Load / Refresh ───────────────────────────────────────

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final sub = await _repo.fetchSubscription();
      state = state.copyWith(isLoading: false, subscription: sub);
    } on UnauthorizedException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'لطفاً دوباره وارد شوید',
      );
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در دریافت اطلاعات اشتراک',
      );
    }
  }

  Future<void> refresh() => load();

  // ── Gift code ────────────────────────────────────────────

  void toggleGiftCode() {
    state = state.copyWith(
      giftCodeExpanded: !state.giftCodeExpanded,
      giftCodeResult: null,
    );
  }

  Future<void> redeemGiftCode(String code) async {
    if (code.trim().isEmpty) return;
    state = state.copyWith(giftCodeLoading: true, giftCodeResult: null);
    try {
      await _repo.redeemGiftCode(code);
      state = state.copyWith(
        giftCodeLoading: false,
        giftCodeResult: 'success',
        giftCodeExpanded: false,
      );
      // داده‌ها رو بعد از redeem موفق دوباره بگیر
      await load();
    } on ApiException catch (e) {
      state = state.copyWith(
        giftCodeLoading: false,
        giftCodeResult: 'error:${e.message}',
      );
    } on NetworkException catch (e) {
      state = state.copyWith(
        giftCodeLoading: false,
        giftCodeResult: 'error:${e.message}',
      );
    } catch (_) {
      state = state.copyWith(
        giftCodeLoading: false,
        giftCodeResult: 'error:کد هدیه نامعتبر است',
      );
    }
  }

  // ── Report usage ─────────────────────────────────────────

  Future<void> reportUsage({
    required double usedGb,
    required double remainingGb,
  }) async {
    try {
      await _repo.reportUsage(usedGb: usedGb, remainingGb: remainingGb);
      // state رو local آپدیت کن بدون round-trip
      final current = state.subscription;
      if (current != null) {
        state = state.copyWith(
          subscription: current.copyWith(
            usedGb: usedGb,
            remainingGb: remainingGb,
          ),
        );
      }
    } catch (_) {
      // گزارش usage سایلنت fail می‌شه
    }
  }
}

// ── Provider ───────────────────────────────────────────────

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(ref.watch(subscriptionRepositoryProvider));
});
