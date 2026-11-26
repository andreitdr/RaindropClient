import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/crypto/mls_crypto_engine.dart' as crypto;
import '../../../core/network/api_exception.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../servers/controllers/session_controller.dart';
import 'channel_groups.dart';
import 'device_setup_controller.dart';

/// The changed identity keys on one server that wait for the person's
/// decision: read from the core's encrypted store, so a change met before the
/// app was closed is listed again after it opens, and kept current by
/// [ChannelGroups.identityChanges] (a new one met, a held message read again).
///
/// Nothing here accepts a key by itself. [PendingIdentityChanges.accept] runs
/// only when the person says so, from the confirmation dialog.
///
/// Empty while this device has no channel groups on the server (not set up, or
/// the server does not offer end-to-end encryption).
final pendingIdentityChangesProvider =
    AsyncNotifierProvider.family<
      PendingIdentityChanges,
      List<PendingIdentityChange>,
      String
    >(PendingIdentityChanges.new);

class PendingIdentityChanges
    extends FamilyAsyncNotifier<List<PendingIdentityChange>, String> {
  bool _disposed = false;
  bool _reading = false;
  bool _readAgain = false;

  @override
  Future<List<PendingIdentityChange>> build(String serverId) async {
    // Riverpod reuses this instance on rebuild: per-build fields start over.
    _disposed = false;
    _reading = false;
    _readAgain = false;
    ref.onDispose(() => _disposed = true);

    final groups = await ref.watch(channelGroupsProvider(serverId).future);
    if (groups == null) return const [];

    // Subscribed before the first read, so a change met meanwhile is not
    // missed.
    final subscription = groups.identityChanges.listen(
      (_) => unawaited(refresh()),
    );
    ref.onDispose(() => unawaited(subscription.cancel()));
    return groups.pendingIdentityChanges();
  }

  /// Reads the list again. Calls that arrive while one is running are folded
  /// into a single further read: a channel with many held messages reports
  /// the same change once per message.
  Future<void> refresh() async {
    if (_reading) {
      _readAgain = true;
      return;
    }
    _reading = true;
    try {
      do {
        _readAgain = false;
        final groups = ref.read(channelGroupsProvider(arg)).valueOrNull;
        if (groups == null || _disposed) return;
        final list = await groups.pendingIdentityChanges();
        if (_disposed) return;
        if (!listEquals(state.valueOrNull, list)) state = AsyncData(list);
      } while (_readAgain);
    } on Object catch (e) {
      debugPrint('identity changes: could not read them: $e');
    } finally {
      _reading = false;
    }
  }

  /// The person accepts [change]'s key: the core pins it and releases the held
  /// messages, the channels it took this device out of are joined again, and
  /// every channel it touches is read again so the released messages show.
  Future<void> accept(PendingIdentityChange change) async {
    final groups = await ref.read(channelGroupsProvider(arg).future);
    if (groups == null) return;
    await groups.acceptChangedIdentity(change.userId, change.presentedKey);
    await refresh();
    for (final channelId in change.channelIds) {
      ref.invalidate(chatProvider((serverId: arg, channelId: channelId)));
    }
  }
}

/// What the confirmation shows besides the change itself: the two safety
/// numbers, and the key the server lists for the user.
@immutable
class IdentityEvidence {
  const IdentityEvidence({
    required this.presentedSafetyNumber,
    this.pinnedSafetyNumber,
    this.registeredKey,
    this.registeredLookupFailed = false,
  });

  /// The 60-digit number the person and the user would read to each other
  /// with the key this device trusted until now (null if it had none), and
  /// with the key now presented.
  final String? pinnedSafetyNumber;
  final String presentedSafetyNumber;

  /// The identity key the server currently lists for the user, or null when it
  /// lists none or could not be asked ([registeredLookupFailed]). The server
  /// is the party the check protects against, so this is a second opinion that
  /// can only ever raise an alarm, never settle the question.
  final Uint8List? registeredKey;
  final bool registeredLookupFailed;
}

/// Computes a safety number; replaced in tests, since the real one runs in the
/// Rust core.
typedef SafetyNumberFn = String Function({
  required String userA,
  required Uint8List keyA,
  required String userB,
  required Uint8List keyB,
});

final safetyNumberFnProvider = Provider<SafetyNumberFn>(
  (ref) => crypto.safetyNumber,
);

/// The evidence for one pending change on one server.
final identityEvidenceProvider = FutureProvider.autoDispose
    .family<
      IdentityEvidence,
      ({String serverId, PendingIdentityChange change})
    >((ref, arg) async {
      final setup = await ref.watch(deviceSetupProvider(arg.serverId).future);
      if (setup is! DeviceSetupReady) {
        throw StateError('This device is not set up on this server.');
      }
      final own = setup.device;
      final change = arg.change;
      final safetyNumber = ref.watch(safetyNumberFnProvider);

      String numberFor(Uint8List key) => safetyNumber(
        userA: own.userId,
        keyA: own.userIdentityKey,
        userB: change.userId,
        keyB: key,
      );

      Uint8List? registered;
      var failed = false;
      final session = await ref.watch(
        serverSessionProvider(arg.serverId).future,
      );
      if (session == null) {
        failed = true;
      } else {
        try {
          final users = await session.e2eeApi.listDevices(session.token, [
            change.userId,
          ]);
          registered = users
              .where((user) => user.userId == change.userId)
              .firstOrNull
              ?.identityKey;
        } on ApiException catch (e) {
          debugPrint('identity changes: could not ask the server: $e');
          failed = true;
        }
      }

      final pinned = change.pinnedKey;
      return IdentityEvidence(
        pinnedSafetyNumber: pinned == null ? null : numberFor(pinned),
        presentedSafetyNumber: numberFor(change.presentedKey),
        registeredKey: registered,
        registeredLookupFailed: failed,
      );
    });
