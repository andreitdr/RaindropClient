import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/crypto_engine.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/e2ee_api.dart';
import '../../../core/network/event_stream.dart';
import '../../servers/controllers/server_events.dart';
import '../../servers/controllers/session_controller.dart';
import 'device_setup_controller.dart';

/// The channel groups for one server, once this device is set up there and
/// the server runs the delivery service. Null otherwise — the chat then falls
/// back to what the server allows.
final channelGroupsProvider = FutureProvider.family<ChannelGroups?, String>((
  ref,
  serverId,
) async {
  final setup = await ref.watch(deviceSetupProvider(serverId).future);
  if (setup is! DeviceSetupReady) return null;

  final session = await ref.watch(serverSessionProvider(serverId).future);
  if (session == null) return null;
  final info = await session.usersApi.serverInfo();
  if (!info.capabilities.contains(e2eeDeliveryCapability)) return null;

  final engine = await ref.watch(cryptoEngineProvider(serverId).future);
  final groups = ChannelGroups(
    engine: engine,
    api: session.e2eeApi,
    token: session.token,
    self: DeviceRef(
      userId: setup.device.userId,
      deviceId: setup.device.deviceId,
    ),
  );

  final stream = ref.watch(serverEventsProvider(serverId));
  final subscription = stream?.events.listen(groups.onEvent);
  ref.onDispose(() {
    unawaited(subscription?.cancel());
    groups.dispose();
  });

  unawaited(groups.onConnected());
  return groups;
});

/// Runs this device's side of every channel's MLS group on one server:
/// creating or joining a group, catching up on commits, picking up Welcomes,
/// keeping key packages topped up, and reconciling a group with the server's
/// roster. Encrypting and decrypting channel messages go through it too, so
/// they always happen in an up-to-date group.
///
/// **Every group operation runs one at a time** ([_serial]): MLS state moves
/// from epoch to epoch, and two operations interleaving on it (a commit being
/// processed while a message is encrypted) would each see a different epoch.
///
/// **Reconciling is the safety net for membership.** The server cannot read a
/// commit, so it cannot tell which devices a member added. After catching up,
/// a device compares the group with `groups/roster` — every device that
/// belongs — and commits the difference: removing a device that should not be
/// there (added by a misbehaving member, revoked, or somebody who lost
/// access), and adding devices that should. Every member does this, with a
/// little random delay so they do not all race; the server's one-commit-per-
/// epoch rule settles who wins, and the rest find nothing left to do.
class ChannelGroups {
  ChannelGroups({
    required this.engine,
    required this.api,
    required this.token,
    required this.self,
  });

  final CryptoEngine engine;
  final E2eeApi api;
  final String token;
  final DeviceRef self;

  static const _keyPackageTarget = 50;
  static const _keyPackageLow = 20;
  static const _commitAttempts = 4;

  final _random = Random();
  Future<void> _tail = Future.value();
  bool _disposed = false;

  /// Ciphertexts this device sent whose server echo may arrive before the
  /// plaintext is in the cache: base64 of the ciphertext → payload.
  final _inFlight = <String, Uint8List>{};

  final _epochChanges = StreamController<String>.broadcast();

  /// The channel id of every group whose epoch just changed (a commit
  /// processed or merged, or this device joining). A call follows its
  /// channel's to switch to the new media key.
  Stream<String> get epochChanges => _epochChanges.stream;

  void dispose() {
    _disposed = true;
    unawaited(_epochChanges.close());
  }

  void _epochChanged(String channelId) {
    if (!_epochChanges.isClosed) _epochChanges.add(channelId);
  }

  /// Runs [work] after everything queued before it.
  Future<T> _serial<T>(Future<T> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  // ── Lifecycle ──

  /// On (re)connecting: Welcomes that arrived while away, and key packages.
  Future<void> onConnected() async {
    try {
      await _serial(_processWelcomes);
      await topUpKeyPackages();
    } on Object catch (e) {
      debugPrint('channel groups: $e');
    }
  }

  void onEvent(ServerEvent event) {
    if (_disposed) return;
    final channelId = event.channelId;
    switch (event.type) {
      case ServerEventTypes.ready:
        unawaited(onConnected());
      case E2eeEventTypes.handshake when channelId != null:
        unawaited(_quietly(() => _serial(() => _catchUpIfMember(channelId))));
      case E2eeEventTypes.welcome:
        unawaited(_quietly(() => _serial(_processWelcomes)));
      case E2eeEventTypes.groupReconcile when channelId != null:
        unawaited(_quietly(() => _reconcileLater(channelId)));
      case E2eeEventTypes.keyPackagesLow:
        unawaited(_quietly(topUpKeyPackages));
    }
  }

  Future<void> _quietly(Future<void> Function() work) async {
    try {
      await work();
    } on Object catch (e) {
      debugPrint('channel groups: $e');
    }
  }

  // ── Messages ──

  /// Encrypts [payload] for the channel's group, joining it first if need be.
  Future<Uint8List> encrypt(String channelId, Uint8List payload) =>
      _serial(() async {
        await _ensureJoined(channelId);
        final ciphertext = await engine.encrypt(
          groupIdForChannel(channelId),
          payload,
        );
        _inFlight[base64.encode(ciphertext)] = payload;
        return ciphertext;
      });

  /// Keeps this device's own message in the cache once the server has it.
  Future<void> rememberSent({
    required String channelId,
    required String messageId,
    required DateTime sentAt,
    required Uint8List ciphertext,
  }) async {
    final payload = _inFlight.remove(base64.encode(ciphertext));
    if (payload == null) return;
    await engine.rememberSent(
      groupId: groupIdForChannel(channelId),
      messageId: messageId,
      sentAt: sentAt,
      payload: payload,
    );
  }

  /// Forgets an unsent ciphertext.
  void abandon(Uint8List ciphertext) =>
      _inFlight.remove(base64.encode(ciphertext));

  /// The payload of an encrypted channel message, or null when this device
  /// cannot decrypt it — sent before it joined the group, or corrupt.
  Future<Uint8List?> decrypt({
    required String channelId,
    required String messageId,
    required DateTime sentAt,
    required Uint8List ciphertext,
    required int epoch,
    required String? senderDeviceId,
  }) => _serial(() async {
    final group = groupIdForChannel(channelId);
    if (await engine.hasGroup(group) && await engine.epoch(group) < epoch) {
      await _catchUp(channelId);
    }

    // Looks in the cache first (a message decrypts only once, and after that
    // the cache is the only copy), then decrypts.
    try {
      final message = await engine.receiveMessage(
        messageId: messageId,
        sentAt: sentAt,
        message: ciphertext,
      );
      if (message != null) return message.payload;
    } on CryptoException {
      // Sent before this device joined, or not for it: fall through.
    }

    // Our own message, echoed before the send returned and was cached. A
    // device cannot decrypt what it sent itself.
    if (senderDeviceId == self.deviceId) {
      return _inFlight[base64.encode(ciphertext)];
    }
    return null;
  });

  /// The key a voice call in [channelId] encrypts its media with right now,
  /// and the slot it goes in: exported from the channel's MLS group, so
  /// exactly its current members can derive it — not the server, not the
  /// media server. It changes with every epoch; [epochChanges] says when.
  ///
  /// The slot is the epoch modulo LiveKit's key ring size, so a receiver
  /// still holds the previous key for frames sent just before a change.
  Future<({Uint8List key, int index})> mediaKey(String channelId) =>
      _serial(() async {
        await _ensureJoined(channelId);
        final group = groupIdForChannel(channelId);
        final epoch = await engine.epoch(group);
        final key = await engine.exportSecret(
          group,
          label: mediaKeyLabel,
          context: group,
        );
        return (key: key, index: epoch % mediaKeyRingSize);
      });

  /// Moves the channel's group to a new epoch (a new media key) by rotating
  /// this device's keys. If another commit wins the epoch, that one rotated
  /// the keys just the same.
  Future<void> rotate(String channelId) => _serial(() async {
    await _ensureJoined(channelId);
    final group = groupIdForChannel(channelId);
    try {
      await _submit(channelId, await engine.selfUpdate(group));
    } on _CommitLost {
      await _catchUp(channelId);
    }
  });

  /// What voice media keys are exported under. Distinct from any other use of
  /// the group's exporter, so a media key says nothing about anything else.
  static const mediaKeyLabel = 'raindrop/voice/v1';

  /// Must match the key ring the voice engine gives LiveKit.
  static const mediaKeyRingSize = 16;

  /// Makes sure this device is in the channel's group and caught up.
  Future<void> ensureJoined(String channelId) =>
      _serial(() => _ensureJoined(channelId));

  /// A message was refused as stale: catch up so the next one is current.
  Future<void> catchUp(String channelId) => _serial(() => _catchUp(channelId));

  // ── Joining ──

  Future<void> _ensureJoined(String channelId) async {
    final group = groupIdForChannel(channelId);
    if (await engine.hasGroup(group)) {
      await _catchUp(channelId);
      return;
    }

    await _processWelcomes();
    if (await engine.hasGroup(group)) {
      await _catchUp(channelId);
      return;
    }

    for (var attempt = 0; attempt < _commitAttempts; attempt++) {
      GroupState state;
      try {
        state = await api.groupState(token, channelId);
      } on ApiException catch (e) {
        if (e.code != 'group_not_found') rethrow;
        if (await _createGroup(channelId)) return;
        continue; // Somebody else created it first.
      }

      final info = state.groupInfo;
      if (info == null) {
        throw const ApiException(
          0,
          'group_unavailable',
          'The group has no published state to join from.',
        );
      }

      final join = await engine.joinByExternalCommit(info);
      try {
        await api.submitCommit(token, channelId, join.commit.commit);
      } on ApiException catch (e) {
        await engine.deleteGroup(group);
        if (e.code != 'epoch_conflict') rethrow;
        await _pause();
        continue; // The group moved on; join from its newer state.
      }
      await engine.mergePendingCommit(group);
      _epochChanged(channelId);
      await _publishGroupInfo(channelId);
      await _catchUp(channelId);
      return;
    }
    throw const ApiException(
      0,
      'group_busy',
      'Could not join the channel\'s encryption group; try again.',
    );
  }

  /// Starts the channel's group with this device in it, then adds everyone
  /// else who belongs. False when another device created it first.
  Future<bool> _createGroup(String channelId) async {
    final group = groupIdForChannel(channelId);
    await engine.createGroup(group);
    try {
      await api.createGroup(token, channelId, await engine.groupInfo(group));
    } on ApiException catch (e) {
      await engine.deleteGroup(group);
      if (e.code == 'group_exists') return false;
      rethrow;
    }
    // The group exists either way; adding the others is best-effort here.
    // Whoever is missed is added by the next reconcile, or joins by itself.
    try {
      await _reconcile(channelId);
    } on Object catch (e) {
      debugPrint('channel groups: adding members to a new group: $e');
    }
    return true;
  }

  // ── Catching up ──

  Future<void> _catchUpIfMember(String channelId) async {
    if (await engine.hasGroup(groupIdForChannel(channelId))) {
      await _catchUp(channelId);
    }
  }

  /// Processes every commit this device has missed, in order. A device too
  /// far behind (the server pruned what it needs), or removed from the group,
  /// drops its copy; it rejoins, if still allowed, the next time it needs to.
  Future<void> _catchUp(String channelId) async {
    final group = groupIdForChannel(channelId);
    while (true) {
      final local = await engine.epoch(group);
      final sync = await api.syncGroup(token, channelId, local);
      if (sync.resyncRequired) {
        await engine.deleteGroup(group);
        return;
      }
      if (sync.commits.isEmpty) return;

      for (final commit in sync.commits) {
        if (commit.epoch < await engine.epoch(group)) continue;
        final event = await engine.process(commit.message);
        if (event is GroupMembershipChanged && event.removedSelf) {
          await engine.deleteGroup(group);
          _epochChanged(channelId);
          return;
        }
      }
      _epochChanged(channelId);
      if (await engine.epoch(group) >= sync.epoch) return;
    }
  }

  // ── Reconciling ──

  Future<void> _reconcileLater(String channelId) async {
    // Everyone in the group hears the same event; a random pause keeps most
    // of them from racing to commit the same change.
    await Future<void>.delayed(
      Duration(milliseconds: 200 + _random.nextInt(1800)),
    );
    if (_disposed) return;
    await _serial(() async {
      if (await engine.hasGroup(groupIdForChannel(channelId))) {
        await _catchUp(channelId);
        await _reconcile(channelId);
      }
    });
  }

  /// Commits the difference between the group and the roster.
  Future<void> _reconcile(String channelId) async {
    final group = groupIdForChannel(channelId);
    for (var attempt = 0; attempt < _commitAttempts; attempt++) {
      if (!await engine.hasGroup(group)) return;

      final roster = (await api.roster(token, channelId)).toSet();
      final members = await engine.members(group);
      final present = {
        for (final m in members)
          DeviceRef(userId: m.userId, deviceId: m.deviceId),
      };

      final stale = [
        for (final m in members)
          if (!roster.contains(
                DeviceRef(userId: m.userId, deviceId: m.deviceId),
              ) &&
              m.deviceId != self.deviceId)
            m.leafIndex,
      ];
      final missing = roster
          .where((d) => !present.contains(d) && d != self)
          .toList();

      try {
        if (stale.isNotEmpty) {
          final commit = await engine.removeMembers(group, stale);
          await _submit(channelId, commit);
          continue; // Re-read: the removal may be all that was needed.
        }
        if (missing.isEmpty) return;

        final packages = await api.claimKeyPackages(token, channelId, missing);
        // Devices with no key package left join by themselves when they
        // next open the channel.
        final commit = await _addAll(group, packages);
        if (commit == null) return;
        await _submit(channelId, commit.commit, recipients: commit.recipients);
        return;
      } on _CommitLost {
        await _catchUp(channelId);
      } on ApiException catch (e) {
        // A device we meant to add was revoked, or lost access, between the
        // roster being read and the commit arriving; the server will not
        // welcome it. The commit is already discarded: re-read and retry.
        if (e.code != 'not_allowed_in_group') rethrow;
      }
    }
  }

  /// Commits adding the devices of [packages]. A user whose key package fails
  /// its checks — a changed identity key, most often — is left out, so one
  /// such user does not keep everybody else out of the group; their safety
  /// number change is theirs to resolve.
  Future<({GroupCommit commit, List<DeviceRef> recipients})?> _addAll(
    Uint8List group,
    Map<DeviceRef, Uint8List> packages,
  ) async {
    final candidates = Map.of(packages);
    while (candidates.isNotEmpty) {
      try {
        final commit = await engine.addMembers(
          group,
          candidates.values.toList(),
        );
        return (commit: commit, recipients: candidates.keys.toList());
      } on CryptoException catch (e) {
        debugPrint('channel groups: not adding ${e.userId ?? 'devices'}: $e');
        final userId = e.userId;
        if (userId == null) return null;
        candidates.removeWhere((device, _) => device.userId == userId);
      }
    }
    return null;
  }

  /// Submits [commit]; merges it if accepted, discards it and throws
  /// [_CommitLost] if another commit won the epoch.
  Future<void> _submit(
    String channelId,
    GroupCommit commit, {
    List<DeviceRef> recipients = const [],
  }) async {
    final group = groupIdForChannel(channelId);
    try {
      await api.submitCommit(
        token,
        channelId,
        commit.commit,
        welcome: commit.welcome,
        welcomeRecipients: recipients,
      );
    } on ApiException catch (e) {
      await engine.discardPendingCommit(group);
      if (e.code == 'epoch_conflict') throw const _CommitLost();
      rethrow;
    }
    await engine.mergePendingCommit(group);
    _epochChanged(channelId);
    await _publishGroupInfo(channelId);
  }

  Future<void> _publishGroupInfo(String channelId) async {
    try {
      await api.putGroupInfo(
        token,
        channelId,
        await engine.groupInfo(groupIdForChannel(channelId)),
      );
    } on ApiException catch (e) {
      // Somebody committed again already; their group info will do.
      if (e.code != 'epoch_conflict') rethrow;
    }
  }

  // ── Welcomes and key packages ──

  Future<void> _processWelcomes() async {
    final welcomes = await api.welcomes(token);
    if (welcomes.isEmpty) return;

    final done = <String>[];
    for (final welcome in welcomes) {
      final group = groupIdForChannel(welcome.channelId);
      try {
        if (!await engine.hasGroup(group)) {
          await engine.joinFromWelcome(welcome.welcome);
          await _catchUp(welcome.channelId);
        }
      } on CryptoException catch (e) {
        // A Welcome this device cannot use (its key package was spent, or a
        // member's identity check failed) is dropped; joining by external
        // commit remains.
        debugPrint('channel groups: welcome to ${welcome.channelId}: $e');
      }
      done.add(welcome.welcomeId);
    }
    await api.ackWelcomes(token, done);
  }

  /// Uploads key packages when fewer than [_keyPackageLow] are left, so
  /// others can add this device while it is offline.
  Future<void> topUpKeyPackages() async {
    final count = await api.keyPackageCount(token);
    if (count >= _keyPackageLow) return;
    final fresh = await engine.generateKeyPackages(_keyPackageTarget - count);
    final lastResort = await engine.generateKeyPackages(1, lastResort: true);
    await api.uploadKeyPackages(token, fresh, lastResort: lastResort.single);
  }

  Future<void> _pause() =>
      Future<void>.delayed(Duration(milliseconds: 100 + _random.nextInt(400)));
}

class _CommitLost implements Exception {
  const _CommitLost();
}
