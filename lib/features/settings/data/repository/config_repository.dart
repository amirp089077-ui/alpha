import '../../../../core/services/api_service.dart';
import '../models/app_config_models.dart';

class ConfigRepository {
  final ApiService _api;
  ConfigRepository({ApiService? api}) : _api = api ?? ApiService();

  /// GET /api/config — بدون نیاز به توکن
  Future<AppConfigModel> fetchConfig() async {
    final json = await _api.get('/api/config', auth: false);
    return AppConfigModel.fromJson(json);
  }
}
