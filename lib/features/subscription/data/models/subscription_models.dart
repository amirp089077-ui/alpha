class SubscriptionModel {
  final double usedGb;
  final double totalGb;
  final int usedDays;
  final int totalDays;
  final DateTime expiryDate;

  const SubscriptionModel({
    required this.usedGb,
    required this.totalGb,
    required this.usedDays,
    required this.totalDays,
    required this.expiryDate,
  });

  double get remainingGb => (totalGb - usedGb).clamp(0, totalGb);
  int get remainingDays => (totalDays - usedDays).clamp(0, totalDays);
  double get volumeProgress => totalGb > 0 ? remainingGb / totalGb : 0;
  double get timeProgress => totalDays > 0 ? remainingDays / totalDays : 0;

  bool get isLowVolume => volumeProgress < 0.15;
  bool get isLowTime   => timeProgress   < 0.15;
}

class SubscriptionState {
  final bool isLoading;
  final SubscriptionModel? subscription;
  final String? errorMessage;
  final bool giftCodeExpanded;
  final bool giftCodeLoading;
  final String? giftCodeResult;

  const SubscriptionState({
    this.isLoading = false,
    this.subscription,
    this.errorMessage,
    this.giftCodeExpanded = false,
    this.giftCodeLoading = false,
    this.giftCodeResult,
  });

  SubscriptionState copyWith({
    bool? isLoading,
    SubscriptionModel? subscription,
    String? errorMessage,
    bool? giftCodeExpanded,
    bool? giftCodeLoading,
    String? giftCodeResult,
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
