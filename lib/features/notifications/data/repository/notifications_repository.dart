import '../../../../core/services/api_service.dart';
import '../models/notification_models.dart';

class NotificationsRepository {
  final ApiService _api;
  NotificationsRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<({List<AppNotification> items, int unread})> fetchNotifications() async {
    final json   = await _api.get('/api/config/notifications', auth: false);
    final raw    = json['notifications'];
    final unread = (json['unread'] as int?) ?? 0;
    final items  = raw is List
        ? raw.whereType<Map<String, dynamic>>().map(AppNotification.fromJson).toList()
        : <AppNotification>[];
    return (items: items, unread: unread);
  }
}
