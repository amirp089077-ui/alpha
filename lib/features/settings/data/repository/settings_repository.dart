import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/app_service.dart';
import '../models/settings_models.dart';

/// Repository واقعی — تنظیمات رو از SharedPreferences می‌خونه/می‌نویسه
/// و لیست برنامه‌ها رو از AppService (Method Channel) می‌گیره
class SettingsRepository {
  static const _keyTheme        = 'theme_mode';
  static const _keyBypassIran   = 'bypass_iran';
  static const _keyAdBlock      = 'ad_block';
  static const _keyWhitelist    = 'whitelisted_apps';

  final AppService _appService;

  SettingsRepository({AppService? appService})
      : _appService = appService ?? AppService();

  // ── Load ──────────────────────────────────────────────────

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_keyTheme) ?? 0;
    final bypassIran = prefs.getBool(_keyBypassIran) ?? true;
    final adBlock    = prefs.getBool(_keyAdBlock) ?? false;
    final whitelist  = prefs.getStringList(_keyWhitelist) ?? [];

    return AppSettings(
      themeMode:       ThemeMode2.values[themeIndex.clamp(0, 2)],
      bypassIranSites: bypassIran,
      adBlock:         adBlock,
      whitelistedApps: Set.from(whitelist),
    );
  }

  // ── Save ──────────────────────────────────────────────────

  Future<void> saveSettings(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, s.themeMode.index);
    await prefs.setBool(_keyBypassIran, s.bypassIranSites);
    await prefs.setBool(_keyAdBlock, s.adBlock);
    await prefs.setStringList(_keyWhitelist, s.whitelistedApps.toList());
  }

  // ── Installed apps — از گوشی واقعی ───────────────────────

  Future<List<AppInfo>> fetchInstalledApps() async {
    final apps = await _appService.getInstalledApps();
    return apps.map((a) => AppInfo(
      packageName: a.packageName,
      appName:     a.appName,
      isSystem:    a.isSystem,
      iconBytes:   a.iconBytes,
    )).toList();
  }
}
