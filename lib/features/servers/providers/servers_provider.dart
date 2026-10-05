import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock/mock_servers_repository.dart';
import '../data/models/server_models.dart';

final serversRepositoryProvider = Provider((_) => MockServersRepository());

class ServersNotifier extends StateNotifier<ServersState> {
  final MockServersRepository _repo;
  ServersNotifier(this._repo) : super(const ServersState()) {
    loadServers();
  }

  Future<void> loadServers() async {
    state = state.copyWith(isLoading: true);
    try {
      final groups = await _repo.fetchServers();
      state = state.copyWith(isLoading: false, groups: groups);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.refreshPings();
      final groups = await _repo.fetchServers();
      state = state.copyWith(isLoading: false, groups: groups);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

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

final serversProvider = StateNotifierProvider<ServersNotifier, ServersState>((ref) {
  return ServersNotifier(ref.watch(serversRepositoryProvider));
});
