/// تنظیمات اپ از GET /api/config
class AppConfigModel {
  final String telegramSupport;
  final String channelUrl;
  final String announcement;
  final String appVersion;
  final bool forceUpdate;

  const AppConfigModel({
    required this.telegramSupport,
    required this.channelUrl,
    required this.announcement,
    required this.appVersion,
    required this.forceUpdate,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> j) {
    return AppConfigModel(
      telegramSupport: (j['telegram_support'] as String?) ?? '',
      channelUrl:      (j['channel_url']       as String?) ?? '',
      announcement:    (j['announcement']       as String?) ?? '',
      appVersion:      (j['app_version']        as String?) ?? '1.0.0',
      forceUpdate:     (j['force_update']        as bool?)  ?? false,
    );
  }

  /// مقدار پیش‌فرض تا زمان دریافت از سرور
  static const AppConfigModel defaultConfig = AppConfigModel(
    telegramSupport: 'AlphaSupport_ir',
    channelUrl:      'https://t.me/AlphaSupport_ir',
    announcement:    '',
    appVersion:      '1.0.0',
    forceUpdate:     false,
  );
}

// ─────────────────────────────────────────────────────────────

enum AppConfigStatus { initial, loading, loaded, error }

class AppConfigState {
  final AppConfigStatus status;
  final AppConfigModel config;
  final String? errorMessage;

  const AppConfigState({
    this.status = AppConfigStatus.initial,
    this.config = AppConfigModel.defaultConfig,
    this.errorMessage,
  });

  AppConfigState copyWith({
    AppConfigStatus? status,
    AppConfigModel?  config,
    String?          errorMessage,
  }) {
    return AppConfigState(
      status:       status       ?? this.status,
      config:       config       ?? this.config,
      errorMessage: errorMessage,
    );
  }
}
