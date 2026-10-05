import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../data/models/app_config_models.dart';
import '../data/repository/config_repository.dart';

// ── Repository provider ────────────────────────────────────

final configRepositoryProvider = Provider<ConfigRepository>(
  (_) => ConfigRepository(),
);

// ── Notifier ───────────────────────────────────────────────

class AppConfigNotifier extends StateNotifier<AppConfigState> {
  final ConfigRepository _repo;

  AppConfigNotifier(this._repo) : super(const AppConfigState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(status: AppConfigStatus.loading);
    try {
      final config = await _repo.fetchConfig();
      state = state.copyWith(status: AppConfigStatus.loaded, config: config);
    } on NetworkException catch (e) {
      // سایلنت fail — از default config استفاده می‌شه
      state = state.copyWith(
        status: AppConfigStatus.error,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(status: AppConfigStatus.error);
    }
  }
}

// ── Provider ───────────────────────────────────────────────

final appConfigProvider =
    StateNotifierProvider<AppConfigNotifier, AppConfigState>((ref) {
  return AppConfigNotifier(ref.watch(configRepositoryProvider));
});

/// shorthand برای دسترسی مستقیم به config
final configProvider = Provider<AppConfigModel>((ref) {
  return ref.watch(appConfigProvider).config;
});
