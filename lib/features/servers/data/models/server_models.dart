enum ServerBadge { none, b, premium, ipv6 }

class ServerLocation {
  final String id;
  final String name;
  final String flagEmoji;
  final int ping;
  final bool isOnline;
  final ServerBadge badge;

  const ServerLocation({
    required this.id,
    required this.name,
    required this.flagEmoji,
    required this.ping,
    this.isOnline = true,
    this.badge = ServerBadge.none,
  });

  ServerLocation copyWith({int? ping, bool? isOnline}) {
    return ServerLocation(
      id:       id,
      name:     name,
      flagEmoji: flagEmoji,
      ping:     ping ?? this.ping,
      isOnline: isOnline ?? this.isOnline,
      badge:    badge,
    );
  }
}

class ServerGroup {
  final String id;
  final String country;
  final String flagEmoji;
  final List<ServerLocation> locations;
  final bool isSpecial; // e.g. مناطق خاص

  const ServerGroup({
    required this.id,
    required this.country,
    required this.flagEmoji,
    required this.locations,
    this.isSpecial = false,
  });

  int get minPing =>
      locations.isEmpty ? 999 : locations.map((l) => l.ping).reduce((a, b) => a < b ? a : b);

  ServerGroup copyWith({List<ServerLocation>? locations}) {
    return ServerGroup(
      id:        id,
      country:   country,
      flagEmoji: flagEmoji,
      locations: locations ?? this.locations,
      isSpecial: isSpecial,
    );
  }
}

class SmartServer {
  final String name;
  final String subtitle;
  const SmartServer({required this.name, required this.subtitle});
}

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
    bool? isLoading,
    List<ServerGroup>? groups,
    String? selectedServerId,
    String? expandedGroupId,
    String? errorMessage,
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
