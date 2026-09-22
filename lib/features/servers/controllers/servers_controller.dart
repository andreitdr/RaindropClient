import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/crypto/crypto_store.dart';
import '../../../core/storage/secure_store.dart';
import '../../security/controllers/device_setup_controller.dart';
import '../../../core/theme/theme_controller.dart';

/// The list of servers this install has connected to, persisted locally.
/// Raindrop has no central directory, so this *is* the user's server list —
/// nothing here is fetched from anywhere.
final serversControllerProvider =
    NotifierProvider<ServersController, List<ServerProfile>>(
      ServersController.new,
    );

class ServersController extends Notifier<List<ServerProfile>> {
  @override
  List<ServerProfile> build() {
    final stored = ref.read(appPrefsProvider).serverProfilesJson;
    return stored.map(ServerProfile.fromJson).toList(growable: false);
  }

  void add(ServerProfile server) {
    if (state.any((s) => s.id == server.id)) return;
    state = [...state, server];
    _persist();
  }

  void rename(String serverId, String displayName) {
    state = [
      for (final s in state)
        if (s.id == serverId) s.copyWith(displayName: displayName) else s,
    ];
    _persist();
  }

  Future<void> remove(String serverId) async {
    state = state.where((s) => s.id != serverId).toList(growable: false);
    _persist();
    // Private keys, groups and decrypted messages for this server go with it.
    // The store is closed first, if it was open.
    if (ref.exists(cryptoEngineProvider(serverId))) {
      (await ref.read(cryptoEngineProvider(serverId).future)).dispose();
      ref.invalidate(cryptoEngineProvider(serverId));
    }
    await const CryptoStores().delete(serverId);
    await const SecureStore().forgetServer(serverId);
  }

  void _persist() => ref
      .read(appPrefsProvider)
      .setServerProfilesJson(state.map((s) => s.toJson()).toList());
}

/// Which connected server the three-pane shell is currently showing.
final activeServerIdProvider =
    NotifierProvider<ActiveServerIdController, String?>(
      ActiveServerIdController.new,
    );

class ActiveServerIdController extends Notifier<String?> {
  @override
  String? build() {
    final servers = ref.watch(serversControllerProvider);
    final lastId = ref.read(appPrefsProvider).lastServerId;
    if (lastId != null && servers.any((s) => s.id == lastId)) return lastId;
    return servers.isEmpty ? null : servers.first.id;
  }

  void select(String serverId) {
    state = serverId;
    ref.read(appPrefsProvider).setLastServerId(serverId);
  }
}
