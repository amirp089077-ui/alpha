import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock/mock_settings_repository.dart';
import '../data/models/settings_models.dart';

final settingsRepositoryProvider = Provider((_) => MockSettingsRepository());

class SettingsNotifier extends StateNotifier<AppSettings> {
  final MockSettingsRepository _repo;
  SettingsNotifier(this._repo) : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final s = await _repo.loadSettings();
    state = s;
  }

  void setTheme(ThemeMode2 mode) {
    state = state.copyWith(themeMode: mode);
    _repo.saveSettings(state);
  }

  void toggleBypassIran(bool value) {
    state = state.copyWith(bypassIranSites: value);
    _repo.saveSettings(state);
  }

  void toggleAdBlock(bool value) {
    state = state.copyWith(adBlock: value);
    _repo.saveSettings(state);
  }

  void toggleWhitelistApp(String packageName) {
    final apps = Set<String>.from(state.whitelistedApps);
    if (apps.contains(packageName)) {
      apps.remove(packageName);
    } else {
      apps.add(packageName);
    }
    state = state.copyWith(whitelistedApps: apps);
    _repo.saveSettings(state);
  }

  void selectAllApps(List<String> packages) {
    state = state.copyWith(whitelistedApps: Set.from(packages));
    _repo.saveSettings(state);
  }

  void deselectAllApps() {
    state = state.copyWith(whitelistedApps: {});
    _repo.saveSettings(state);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

/// Derived provider that maps ThemeMode2 → Flutter ThemeMode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(settingsProvider).themeMode;
  switch (mode) {
    case ThemeMode2.light: return ThemeMode.light;
    case ThemeMode2.dark:  return ThemeMode.dark;
    case ThemeMode2.auto:  return ThemeMode.system;
  }
});

final whitelistAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.fetchInstalledApps();
});
