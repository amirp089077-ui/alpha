import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../data/models/notification_models.dart';
import '../data/repository/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (_) => NotificationsRepository(),
);

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repo;

  NotificationsNotifier(this._repo) : super(const NotificationsState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(status: NotifStatus.loading);
    try {
      final result = await _repo.fetchNotifications();
      state = state.copyWith(
        status: NotifStatus.loaded,
        items:  result.items,
        unread: result.unread,
      );
    } on NetworkException catch (e) {
      state = state.copyWith(status: NotifStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(status: NotifStatus.error);
    }
  }

  void markAllRead() {
    final updated = state.items.map((n) => n.copyWith(isNew: false)).toList();
    state = state.copyWith(items: updated, unread: 0);
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref.watch(notificationsRepositoryProvider));
});
