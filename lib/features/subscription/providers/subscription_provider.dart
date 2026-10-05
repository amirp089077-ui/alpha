import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock/mock_subscription_repository.dart';
import '../data/models/subscription_models.dart';

final subscriptionRepositoryProvider = Provider((_) => MockSubscriptionRepository());

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final MockSubscriptionRepository _repo;
  SubscriptionNotifier(this._repo) : super(const SubscriptionState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final sub = await _repo.fetchSubscription();
      state = state.copyWith(isLoading: false, subscription: sub);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void toggleGiftCode() {
    state = state.copyWith(giftCodeExpanded: !state.giftCodeExpanded);
  }

  Future<void> redeemGiftCode(String code) async {
    state = state.copyWith(giftCodeLoading: true, giftCodeResult: null);
    try {
      final ok = await _repo.redeemGiftCode(code);
      if (ok) {
        state = state.copyWith(
          giftCodeLoading: false,
          giftCodeResult: 'success',
          giftCodeExpanded: false,
        );
        await load();
      }
    } on Exception {
      state = state.copyWith(giftCodeLoading: false, giftCodeResult: 'error');
    }
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(ref.watch(subscriptionRepositoryProvider));
});
