import '../../../../core/services/api_service.dart';
import '../models/server_models.dart';

class ServersRepository {
  final ApiService _api;
  ServersRepository({ApiService? api}) : _api = api ?? ApiService();

  /// GET /api/servers — نیاز به توکن دارد
  Future<List<ServerGroup>> fetchServers() async {
    final json = await _api.get('/api/servers', auth: true);
    final rawList = json['servers'] as List<dynamic>;

    final items = rawList
        .map((e) => ServerItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return _groupByCountry(items);
  }

  /// سرورها را بر اساس کشور گروه‌بندی می‌کند
  List<ServerGroup> _groupByCountry(List<ServerItem> items) {
    final Map<String, List<ServerItem>> map = {};

    for (final item in items) {
      map.putIfAbsent(item.country, () => []).add(item);
    }

    return map.entries.map((entry) {
      final first = entry.value.first;
      return ServerGroup(
        id:        entry.key,
        country:   entry.key,
        flagEmoji: first.flag,
        locations: entry.value,
        isSpecial: first.flag == '🌐',
      );
    }).toList();
  }
}
