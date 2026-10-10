/// تنظیمات اپ از GET /api/config
class AppConfigModel {
  final String telegramSupport;
  final String channelUrl;
  final String announcement;
  final String appVersion;
  final bool   forceUpdate;
  // ── فیلدهای جدید ─────────────────────────────
  final String  latestVersion;
  final String  updateUrl;
  final String  updateChangelog;
  final bool    maintenanceMode;
  final String  maintenanceMessage;
  final bool    broadcastEnabled;
  final String  broadcastMessage;
  final String  broadcastType;     // info | warning | success | error

  const AppConfigModel({
    required this.telegramSupport,
    required this.channelUrl,
    required this.announcement,
    required this.appVersion,
    required this.forceUpdate,
    this.latestVersion      = '',
    this.updateUrl          = '',
    this.updateChangelog    = '',
    this.maintenanceMode    = false,
    this.maintenanceMessage = '',
    this.broadcastEnabled   = false,
    this.broadcastMessage   = '',
    this.broadcastType      = 'info',
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> j) {
    bool parseBool(dynamic v) {
      if (v is bool)   return v;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    return AppConfigModel(
      telegramSupport:    (j['telegram_support']   as String?) ?? '',
      channelUrl:         (j['channel_url']         as String?) ?? '',
      announcement:       (j['announcement']        as String?) ?? '',
      appVersion:         (j['app_version']         as String?) ?? '1.0.0',
      forceUpdate:        parseBool(j['force_update']),
      latestVersion:      (j['latest_version']      as String?) ?? '',
      updateUrl:          (j['update_url']          as String?) ?? '',
      updateChangelog:    (j['update_changelog']    as String?) ?? '',
      maintenanceMode:    parseBool(j['maintenance_mode']),
      maintenanceMessage: (j['maintenance_message'] as String?) ?? '',
      broadcastEnabled:   parseBool(j['broadcast_enabled']),
      broadcastMessage:   (j['broadcast_message']  as String?) ?? '',
      broadcastType:      (j['broadcast_type']     as String?) ?? 'info',
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
  final AppConfigModel  config;
  final String?         errorMessage;

  const AppConfigState({
    this.status       = AppConfigStatus.initial,
    this.config       = AppConfigModel.defaultConfig,
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
