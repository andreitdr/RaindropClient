import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/e2ee_api.dart';
import '../../../core/network/event_stream.dart';
import '../../servers/controllers/live_sync.dart';
import '../../servers/controllers/servers_controller.dart';
import '../../servers/controllers/session_controller.dart';

/// The devices waiting to be added to the person's account on one server
/// without an authenticator code — somebody who has the recovery words said
/// they lost the authenticator. Read once the session opens and followed
/// through `e2ee.recovery.changed`, so a device signed in here hears of a
/// wait the moment it starts, and can stop it.
///
/// Empty on a server too old to have recovery waits, and while signed out.
final pendingRecoveriesProvider =
    AsyncNotifierProvider.family<RecoveryWatch, List<PendingRecovery>, String>(
      RecoveryWatch.new,
    );

class RecoveryWatch extends FamilyAsyncNotifier<List<PendingRecovery>, String> {
  @override
  Future<List<PendingRecovery>> build(String serverId) async {
    final session = await ref.watch(serverSessionProvider(serverId).future);
    if (session == null) return const [];

    LiveSync(
      ref,
      serverId: serverId,
      onEvent: (event) {
        if (event.type != ServerEventTypes.recoveryChanged) return;
        state = AsyncData([
          for (final recovery in event.proto.recoveryChanged.recoveries)
            PendingRecovery.fromProto(recovery),
        ]);
      },
      resync: () async => state = AsyncData(await _read(session)),
    );
    return _read(session);
  }

  Future<List<PendingRecovery>> _read(ServerSession session) async {
    try {
      return await session.e2eeApi.recoveries(session.token);
    } on ApiException catch (e) {
      // An older server, or a session that is not bound yet: nothing to show.
      debugPrint(
        'recovery: could not read waits on ${session.profile.host}: $e',
      );
      return const [];
    }
  }

  /// Cancels every wait on this server, for good.
  Future<void> cancelAll() async {
    final session = ref.read(serverSessionProvider(arg)).valueOrNull;
    if (session == null) return;
    await session.e2eeApi.cancelRecoveries(session.token);
    state = const AsyncData([]);
  }
}

/// One wait, with the server it is on.
typedef ServerRecovery = ({ServerProfile server, PendingRecovery recovery});

/// The waits on every server this device has a session open with, soonest
/// first. Servers it is not signed in to are left alone rather than signed in
/// to just to ask — that would show the person online everywhere — and the
/// one on screen always has a session, so a wait there is always heard of.
List<ServerRecovery> watchKnownRecoveries(WidgetRef ref) {
  final all = <ServerRecovery>[
    for (final server in ref.watch(serversControllerProvider))
      if (ref.exists(serverSessionProvider(server.id)))
        for (final recovery
            in ref.watch(pendingRecoveriesProvider(server.id)).valueOrNull ??
                const <PendingRecovery>[])
          (server: server, recovery: recovery),
  ];
  return all
    ..sort((a, b) => a.recovery.eligibleAt.compareTo(b.recovery.eligibleAt));
}

/// Cancels the waits on every server this device has a session open with.
/// Returns how many servers could not be reached, which the person should
/// hear about.
Future<int> cancelAllRecoveries(WidgetRef ref) async {
  var failed = 0;
  for (final server in ref.read(serversControllerProvider)) {
    if (!ref.exists(serverSessionProvider(server.id))) continue;
    try {
      final waits = await ref.read(pendingRecoveriesProvider(server.id).future);
      if (waits.isEmpty) continue;
      await ref.read(pendingRecoveriesProvider(server.id).notifier).cancelAll();
    } on ApiException {
      failed++;
    }
  }
  return failed;
}

/// The key a wait is remembered by once the person said it was theirs.
String recoveryKey(ServerRecovery entry) =>
    '${entry.server.id}/${entry.recovery.deviceId}';
