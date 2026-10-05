/// بج سرور — با مقادیر badge بک‌اند سینک شده
enum ServerBadge { none, b, premium, ipv6 }

ServerBadge _parseBadge(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'b':
      return ServerBadge.b;
    case 'premium':
      return ServerBadge.premium;
    case 'ipv6':
      return ServerBadge.ipv6;
    default:
      return ServerBadge.none;
  }
}

// ─────────────────────────────────────────────────────────────
// ServerItem — یک سرور تکی از API
// ─────────────────────────────────────────────────────────────

class ServerItem {
  final String id;
  final String country;
  final String city;
  final String flag;
  final String host;
  final int port;
  final ServerBadge badge;
  final String emoji;
  final bool isPro;
  final String configUri;
  final int ping;

  const ServerItem({
    required this.id,
    required this.country,
    required this.city,
    required this.flag,
    required this.host,
    required this.port,
    this.badge = ServerBadge.none,
    this.emoji = '',
    this.isPro = false,
    this.configUri = '',
    this.ping = 50,
  });

  factory ServerItem.fromJson(Map<String, dynamic> j) {
    return ServerItem(
      id:        j['id']         as String,
      country:   j['country']    as String,
      city:      j['city']       as String,
      flag:      j['flag']       as String,
      host:      j['host']       as String,
      port:      j['port']       as int,
      badge:     _parseBadge(j['badge'] as String?),
      emoji:     (j['emoji']     as String?) ?? '',
      isPro:     (j['is_pro']    as bool?)   ?? false,
      configUri: (j['config_uri'] as String?) ?? '',
      ping:      (j['ping']      as int?)    ?? 50,
    );
  }

  /// نام نمایشی کامل (مثلاً «انگلیس — لندن»)
  String get displayName => '$country — $city';

  // ── Backward-compatibility aliases (برای home_screen که از ServerLocation استفاده می‌کند) ──
  String get name => displayName;
  String get flagEmoji => flag;
  bool get isOnline => true;
}

/// Type alias برای سازگاری با کدهای قدیمی که ServerLocation استفاده می‌کردند
typedef ServerLocation = ServerItem;

// ─────────────────────────────────────────────────────────────
// ServerGroup — گروه‌بندی سرورها بر اساس کشور (برای UI)
// ─────────────────────────────────────────────────────────────

class ServerGroup {
  final String id;          // معمولاً country
  final String country;
  final String flagEmoji;
  final List<ServerItem> locations;
  final bool isSpecial;

  const ServerGroup({
    required this.id,
    required this.country,
    required this.flagEmoji,
    required this.locations,
    this.isSpecial = false,
  });

  int get minPing =>
      locations.isEmpty ? 999 : locations.map((l) => l.ping).reduce((a, b) => a < b ? a : b);

  ServerGroup copyWith({List<ServerItem>? locations}) {
    return ServerGroup(
      id:        id,
      country:   country,
      flagEmoji: flagEmoji,
      locations: locations ?? this.locations,
      isSpecial: isSpecial,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ServersState
// ─────────────────────────────────────────────────────────────

class ServersState {
  final bool isLoading;
  final List<ServerGroup> groups;
  final String? selectedServerId;
  final String? expandedGroupId;
  final String? errorMessage;

  const ServersState({
    this.isLoading = false,
    this.groups = const [],
    this.selectedServerId,
    this.expandedGroupId,
    this.errorMessage,
  });

  int get totalServers =>
      groups.fold(0, (sum, g) => sum + g.locations.length);

  ServersState copyWith({
    bool?              isLoading,
    List<ServerGroup>? groups,
    String?            selectedServerId,
    String?            expandedGroupId,
    String?            errorMessage,
  }) {
    return ServersState(
      isLoading:        isLoading        ?? this.isLoading,
      groups:           groups           ?? this.groups,
      selectedServerId: selectedServerId ?? this.selectedServerId,
      expandedGroupId:  expandedGroupId  ?? this.expandedGroupId,
      errorMessage:     errorMessage,
    );
  }
}
