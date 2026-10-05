import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../data/models/server_models.dart';
import '../data/repository/servers_repository.dart';

// ── Repository provider ────────────────────────────────────

final serversRepositoryProvider = Provider<ServersRepository>(
  (_) => ServersRepository(),
);

// ── Notifier ───────────────────────────────────────────────

class ServersNotifier extends StateNotifier<ServersState> {
  final ServersRepository _repo;

  ServersNotifier(this._repo) : super(const ServersState()) {
    loadServers();
  }

  Future<void> loadServers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final groups = await _repo.fetchServers();
      state = state.copyWith(isLoading: false, groups: groups);
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در دریافت سرورها',
      );
    }
  }

  Future<void> refresh() => loadServers();

  void toggleGroup(String groupId) {
    final current = state.expandedGroupId;
    state = state.copyWith(
      expandedGroupId: current == groupId ? null : groupId,
    );
  }

  void selectServer(String serverId) {
    state = state.copyWith(selectedServerId: serverId);
  }

  void selectSmart() {
    state = state.copyWith(selectedServerId: 'smart');
  }
}

// ── Provider ───────────────────────────────────────────────

final serversProvider =
    StateNotifierProvider<ServersNotifier, ServersState>((ref) {
  return ServersNotifier(ref.watch(serversRepositoryProvider));
});

/// سرور انتخاب‌شده فعلی
final selectedServerProvider = Provider<ServerItem?>((ref) {
  final state = ref.watch(serversProvider);
  final id = state.selectedServerId;
  if (id == null || id == 'smart') return null;
  for (final group in state.groups) {
    try {
      return group.locations.firstWhere((s) => s.id == id);
    } catch (_) {}
  }
  return null;
});
