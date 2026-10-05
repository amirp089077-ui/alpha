import '../models/settings_models.dart';

class MockSettingsRepository {
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  Future<AppSettings> loadSettings() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _settings;
  }

  Future<void> saveSettings(AppSettings s) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _settings = s;
  }

  Future<List<AppInfo>> fetchInstalledApps() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockApps;
  }

  static final _mockApps = [
    const AppInfo(packageName: 'com.instagram.android',  appName: 'اینستاگرام'),
    const AppInfo(packageName: 'org.telegram.messenger',  appName: 'تلگرام'),
    const AppInfo(packageName: 'com.whatsapp',            appName: 'واتساپ'),
    const AppInfo(packageName: 'com.twitter.android',     appName: 'توییتر'),
    const AppInfo(packageName: 'com.google.android.youtube', appName: 'یوتیوب'),
    const AppInfo(packageName: 'com.spotify.music',       appName: 'اسپاتیفای'),
    const AppInfo(packageName: 'com.netflix.mediaclient', appName: 'نتفلیکس'),
    const AppInfo(packageName: 'com.skype.raider',        appName: 'اسکایپ'),
    const AppInfo(packageName: 'com.discord',             appName: 'دیسکورد'),
    const AppInfo(packageName: 'com.snapchat.android',    appName: 'اسنپ‌چت'),
    const AppInfo(packageName: 'com.linkedin.android',    appName: 'لینکدین'),
    const AppInfo(packageName: 'com.pinterest',           appName: 'پینترست'),
    const AppInfo(packageName: 'com.tiktok.android',      appName: 'تیک‌تاک'),
    const AppInfo(packageName: 'com.amazon.mShop',        appName: 'آمازون'),
    const AppInfo(packageName: 'com.facebook.katana',     appName: 'فیسبوک'),
  ];
}
