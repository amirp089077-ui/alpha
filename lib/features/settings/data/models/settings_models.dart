import 'dart:typed_data';

enum ThemeMode2 { auto, light, dark }

class AppSettings {
  final ThemeMode2 themeMode;
  final bool bypassIranSites;
  final bool adBlock;
  final Set<String> whitelistedApps; // package names

  const AppSettings({
    this.themeMode = ThemeMode2.auto,
    this.bypassIranSites = true,
    this.adBlock = false,
    this.whitelistedApps = const {},
  });

  AppSettings copyWith({
    ThemeMode2? themeMode,
    bool? bypassIranSites,
    bool? adBlock,
    Set<String>? whitelistedApps,
  }) {
    return AppSettings(
      themeMode:       themeMode       ?? this.themeMode,
      bypassIranSites: bypassIranSites ?? this.bypassIranSites,
      adBlock:         adBlock         ?? this.adBlock,
      whitelistedApps: whitelistedApps ?? this.whitelistedApps,
    );
  }
}

class AppInfo {
  final String packageName;
  final String appName;
  final bool isSystem;

  /// PNG bytes آیکون واقعی از گوشی — null یعنی fallback به حرف اول
  final Uint8List? iconBytes;

  const AppInfo({
    required this.packageName,
    required this.appName,
    this.isSystem = false,
    this.iconBytes,
  });
}
