import '../../../../core/services/api_service.dart';
import '../models/server_models.dart';

class ServersRepository {
  final ApiService _api;
  ServersRepository({ApiService? api}) : _api = api ?? ApiService();

  /// GET /api/servers — نیاز به توکن دارد
  Future<List<ServerGroup>> fetchServers() async {
    final json = await _api.get('/api/servers', auth: true);

    // بک‌اند ممکنه { servers: [...] } یا { data: [...] } یا مستقیم [] بفرسته
    List<dynamic> rawList;
    if (json.containsKey('servers')) {
      rawList = json['servers'] as List<dynamic>;
    } else if (json.containsKey('data') && json['data'] is List) {
      rawList = json['data'] as List<dynamic>;
    } else if (json.containsKey('items') && json['items'] is List) {
      rawList = json['items'] as List<dynamic>;
    } else {
      // fallback: اگه خود json یه Map از سرورها بود
      rawList = [];
    }

    final items = rawList
        .map((e) => ServerItem.fromJson(e as Map<String, dynamic>))
        .where((s) => s.configUri.isNotEmpty) // فقط سرورهایی که config دارن
        .toList();

    return _groupByCountry(items);
  }

  /// سرورها را بر اساس پرچم (flag emoji) گروه‌بندی می‌کند
  /// مثلاً «Germany» و «Germany 2» هر دو 🇩🇪 دارن → یه گروه
  List<ServerGroup> _groupByCountry(List<ServerItem> items) {
    // ترتیب ورود سرورها رو حفظ می‌کنیم
    final Map<String, List<ServerItem>> map = {};
    final Map<String, String> flagToCountry = {};

    for (final item in items) {
      final key = item.flag; // کلید = emoji پرچم
      map.putIfAbsent(key, () => []).add(item);
      // اولین اسم کشور با این پرچم رو نگه دار
      flagToCountry.putIfAbsent(key, () => _baseCountryName(item.country));
    }

    return map.entries.map((entry) {
      final flag     = entry.key;
      final servers  = entry.value;
      final country  = flagToCountry[flag]!;
      return ServerGroup(
        id:        flag,
        country:   country,
        flagEmoji: flag,
        locations: servers,
        isSpecial: flag == '🌐',
      );
    }).toList();
  }

  /// پاک کردن شماره از آخر اسم کشور: «Germany 2» → «Germany»
  String _baseCountryName(String name) {
    return name.replaceAll(RegExp(r'\s+\d+$'), '').trim();
  }
}
