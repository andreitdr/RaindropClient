import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
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
    generations: info.capabilities.contains(e2eeGroupResetCapability),
  );

  final stream = ref.watch(serverEventsProvider(serverId));
  final subscription = stream?.events.listen(groups.onEvent);
  ref.onDispose(() {
    unawaited(subscription?.cancel());
    groups.dispose();
  });

  unawaited(groups.onConnected());
  // A change met before the app was last closed is still waiting for the
  // person's decision: say so again, so whatever shows it picks it up.
  unawaited(groups.announcePendingIdentityChanges());
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
///
/// **A member's changed identity key is the person's decision** ([identityChanges]).
/// A message from them is held by the core, undecryptable here until the
/// change is accepted; a commit from them is refused, and refusing a commit is
/// leaving the group, which the core has already done. The core keeps both in
/// its encrypted store, so [pendingIdentityChanges] lists what is waiting —
/// the presented key, the held messages, the channels left — also after a
/// restart. Once the person accepts the change ([acceptChangedIdentity]) the
/// held messages are in the cache and every channel the change took this
/// device out of is joined again.
///
/// **A group nobody can follow is replaced** ([generations]). The server
/// cannot read a commit, so it accepts one no member can process — garbage,
/// or one adding a device whose certificate does not verify — and every member
/// would be stuck behind it. A device that cannot process a logged commit
/// drops its copy (keeping the cached messages) and tries once to join again
/// from the published group info; if that cannot work either, it reports the
/// commit to the server (`ResetGroup`), which starts a new **generation** of
/// the channel's group: a new MLS group with a new group id
/// ([groupIdForChannel]) that the reporting device creates and everybody else
/// joins — by Welcome or external commit, every member validated as always.
/// A generation is only ever followed forwards, and members who find the same
/// broken commit end up in one new generation: the server resets once per
/// generation and tells the others where everyone went. History decrypted in
/// an earlier generation stays in the cache.
class ChannelGroups {
  ChannelGroups({
    required this.engine,
    required this.api,
    required this.token,
    required this.self,
    this.generations = false,
  });

  final CryptoEngine engine;
  final E2eeApi api;
  final String token;
  final DeviceRef self;

  /// Whether the server keeps group generations ([e2eeGroupResetCapability]).
  /// Without it every group is in generation 0 and a commit nobody can process
  /// is an error, as it always was.
  final bool generations;

  /// How many generations before the one a device learns of on its first
  /// look at a channel it checks for leftover state to drop.
  static const _generationsDropped = 8;

  static const _keyPackageTarget = 50;
  static const _keyPackageLow = 20;
  static const _commitAttempts = 4;

  final _random = Random();
  Future<void> _tail = Future.value();
  bool _disposed = false;

  /// Channels where this device made a commit whose fate it does not know: the
  /// submit failed in a way that does not say whether the server appended it
  /// (a timeout, a dropped connection), and the sync that would tell could not
  /// run either. The core still holds the commit as pending, so its echo merges
  /// if the server did take it, and another commit's merge drops it if not.
  /// The next sync that succeeds ([_catchUp]) settles it: what the server
  /// echoes merges, and if the server has nothing past this device's epoch it
  /// never got the commit, which is then discarded. Only touched inside
  /// [_serial], so it needs no lock of its own.
  final _unsettled = <String>{};

  /// Ciphertexts this device sent whose server echo may arrive before the
  /// plaintext is in the cache: base64 of the ciphertext → the payload, and
  /// the group it was encrypted in (a reset may move the channel on before the
  /// send returns).
  final _inFlight = <String, ({Uint8List payload, Uint8List group})>{};

  /// The generation each channel's group is in, as far as this device knows:
  /// read from the server on first use, then followed from syncs, resets and
  /// `e2ee.group.reset`. Only ever moves forwards ([_moveTo]).
  final _generations = <String, int>{};

  final _epochChanges = StreamController<String>.broadcast();
  final _identityChanges = StreamController<IdentityChange>.broadcast();

  /// The channel id of every group whose epoch just changed (a commit
  /// processed or merged, or this device joining). A call follows its
  /// channel's to switch to the new media key.
  Stream<String> get epochChanges => _epochChanges.stream;

  /// Every time a member's identity key is found not to match the one this
  /// device pinned: the person has to compare the new safety number and
  /// accept it ([acceptChangedIdentity]) or not.
  Stream<IdentityChange> get identityChanges => _identityChanges.stream;

  void dispose() {
    _disposed = true;
    unawaited(_epochChanges.close());
    unawaited(_identityChanges.close());
  }

  /// Notes [error] if it is a changed identity met in [channelId]; returns
  /// whether it was. The core has already written it down (a held message, a
  /// group left), so this only tells whoever is listening.
  bool _noteIdentityChange(
    CryptoException error,
    String channelId, {
    required bool leftGroup,
  }) {
    final userId = error.userId;
    if (error.kind != CryptoErrorKind.identityChanged || userId == null) {
      return false;
    }
    _emitIdentityChange(
      IdentityChange(
        userId: userId,
        channelId: channelId,
        leftGroup: leftGroup,
        pinnedKey: error.pinnedKey,
        presentedKey: error.presentedKey,
      ),
    );
    return true;
  }

  void _emitIdentityChange(IdentityChange change) {
    if (!_identityChanges.isClosed) _identityChanges.add(change);
  }

  /// Every changed identity key waiting for the person's decision, from the
  /// core's encrypted store: complete after a restart, and cleared per key by
  /// [acceptChangedIdentity].
  Future<List<PendingIdentityChange>> pendingIdentityChanges() =>
      engine.pendingIdentityChanges();

  /// Emits an [IdentityChange] for each channel a pending change touches, as
  /// when it was first met. Called when the groups are set up, so a change the
  /// person has not decided on is raised again after a restart.
  Future<void> announcePendingIdentityChanges() => _quietly(() async {
    for (final change in await pendingIdentityChanges()) {
      for (final channelId in change.channelIds) {
        _emitIdentityChange(
          IdentityChange(
            userId: change.userId,
            channelId: channelId,
            leftGroup: change.leftChannelIds.contains(channelId),
            pinnedKey: change.pinnedKey,
            presentedKey: change.presentedKey,
          ),
        );
      }
    }
  });

  /// The person compared the new safety number and accepts [userId]'s changed
  /// [identityKey] (the key they presented: [PendingIdentityChange.presentedKey]).
  /// Their held messages move into the cache (read them again to show them),
  /// and every channel the change took this device out of — as the core
  /// recorded it, so also after a restart — is joined again, each on its own,
  /// so one that still cannot be joined does not keep the others out.
  ///
  /// The channels are read before the core accepts, because accepting clears
  /// their record. A rejoin that does not happen (the app closed in between, or
  /// the server could not be reached) is only postponed: the next use of the
  /// channel joins it, as it does for any channel this device is not in.
  Future<void> acceptChangedIdentity(String userId, Uint8List identityKey) =>
      _serial(() async {
        final channels = {
          for (final change in await engine.pendingIdentityChanges())
            if (change.userId == userId &&
                listEquals(change.presentedKey, identityKey))
              ...change.leftChannelIds,
        };
        await engine.acceptChangedIdentity(userId, identityKey);
        for (final channelId in channels) {
          await _quietly(() => _ensureJoined(channelId));
        }
      });

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
      case E2eeEventTypes.groupReset when channelId != null && generations:
        final generation = event.proto.groupReset.generation.toInt();
        unawaited(
          _quietly(() => _serial(() => _moveTo(channelId, generation))),
        );
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
        final group = await _groupId(channelId);
        final ciphertext = await engine.encrypt(group, payload);
        _inFlight[base64.encode(ciphertext)] = (payload: payload, group: group);
        return ciphertext;
      });

  /// Keeps this device's own message in the cache once the server has it.
  Future<void> rememberSent({
    required String channelId,
    required String messageId,
    required DateTime sentAt,
    required Uint8List ciphertext,
  }) async {
    final sent = _inFlight.remove(base64.encode(ciphertext));
    if (sent == null) return;
    await engine.rememberSent(
      groupId: sent.group,
      messageId: messageId,
      sentAt: sentAt,
      payload: sent.payload,
    );
  }

  /// Forgets an unsent ciphertext.
  void abandon(Uint8List ciphertext) =>
      _inFlight.remove(base64.encode(ciphertext));

  /// The payload of an encrypted channel message, or null when this device
  /// cannot decrypt it — sent before it joined the group, corrupt, or held
  /// for a changed identity ([decryptOrHeld] tells those apart).
  Future<Uint8List?> decrypt({
    required String channelId,
    required String messageId,
    required DateTime sentAt,
    required Uint8List ciphertext,
    required int epoch,
    required String? senderDeviceId,
  }) async => (await decryptOrHeld(
    channelId: channelId,
    messageId: messageId,
    sentAt: sentAt,
    ciphertext: ciphertext,
    epoch: epoch,
    senderDeviceId: senderDeviceId,
  )).payload;

  /// As [decrypt], and says whether the message is **held**: its sender's
  /// identity key changed, so the core keeps its plaintext aside until the
  /// person accepts the new key ([acceptChangedIdentity]). A held message has
  /// no payload yet, but it is not an undecryptable one — it is waiting for
  /// them.
  Future<({Uint8List? payload, bool held})> decryptOrHeld({
    required String channelId,
    required String messageId,
    required DateTime sentAt,
    required Uint8List ciphertext,
    required int epoch,
    required String? senderDeviceId,
  }) => _serial(() async {
    // Without the server (offline, or no longer let into the channel) the
    // generation may be unknown; the cache still answers below.
    Uint8List? group;
    try {
      group = await _groupId(channelId);
    } on ApiException catch (e) {
      debugPrint('channel groups: generation of $channelId unknown: $e');
    }
    if (group != null && await _followNewerGeneration(channelId, ciphertext)) {
      group = await _groupId(channelId);
    }
    if (group != null &&
        await engine.hasGroup(group) &&
        await engine.epoch(group) < epoch) {
      try {
        await _catchUp(channelId);
      } on CryptoException {
        // A refused commit took this device out of the group; the message
        // may still be in the cache.
        if (await engine.hasGroup(await _groupId(channelId))) rethrow;
      }
    }

    // Looks in the cache first (a message decrypts only once, and after that
    // the cache is the only copy), then decrypts.
    try {
      final message = await engine.receiveMessage(
        messageId: messageId,
        sentAt: sentAt,
        message: ciphertext,
      );
      if (message != null) return (payload: message.payload, held: false);
    } on CryptoException catch (e) {
      // From a member whose identity changed: held until the person decides.
      // Otherwise sent before this device joined, or not for it. Either way
      // there is nothing to show yet: fall through.
      if (_noteIdentityChange(e, channelId, leftGroup: false)) {
        return (payload: null, held: true);
      }
    }

    // Our own message, echoed before the send returned and was cached. A
    // device cannot decrypt what it sent itself.
    if (senderDeviceId == self.deviceId) {
      return (
        payload: _inFlight[base64.encode(ciphertext)]?.payload,
        held: false,
      );
    }
    return (payload: null, held: false);
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
        final group = await _groupId(channelId);
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
    final group = await _groupId(channelId);
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

  // ── Generations ──

  /// The generation the channel's group is in: known, or asked of the server
  /// once. Always 0 on a server without generations.
  Future<int> _generation(String channelId) async {
    if (!generations) return 0;
    final known = _generations[channelId];
    if (known != null) return known;
    await _moveTo(channelId, await api.groupGeneration(token, channelId));
    return _generations[channelId]!;
  }

  /// The MLS group id of the channel's group in its current generation.
  Future<Uint8List> _groupId(String channelId) async =>
      groupIdForChannel(channelId, await _generation(channelId));

  /// Follows the channel's group to [generation]. Never backwards — a server
  /// cannot lead this device back into a generation it has left — and the
  /// state of every generation left behind is dropped (reset, so the cached
  /// messages stay): those groups are gone, and their keys are no use.
  Future<void> _moveTo(String channelId, int generation) async {
    final known = _generations[channelId];
    if (known != null && generation <= known) return;
    _generations[channelId] = generation;
    _unsettled.remove(channelId);
    var dropped = false;
    for (
      var old = known ?? max(0, generation - _generationsDropped);
      old < generation;
      old++
    ) {
      final group = groupIdForChannel(channelId, old);
      if (await engine.hasGroup(group)) {
        await engine.resetGroup(group);
        dropped = true;
      }
    }
    if (dropped) _epochChanged(channelId);
  }

  /// The generation of [channelId]'s group that [message] was encrypted in,
  /// read from its cleartext MLS framing as the server reads it, or null when
  /// it is not a private message for this channel's group.
  static int? _messageGeneration(String channelId, Uint8List message) {
    // MLS 1.0, wire format private_message, then the group id as a vector
    // whose one-byte length is under 64.
    if (message.length < 5 ||
        message[0] != 0 ||
        message[1] != 1 ||
        message[2] != 0 ||
        message[3] != 2 ||
        message[4] & 0xc0 != 0) {
      return null;
    }
    final length = message[4];
    if (message.length < 5 + length) return null;
    final id = Uint8List.sublistView(message, 5, 5 + length);
    if (channelIdForGroup(id) != channelId.toLowerCase()) return null;
    var generation = 0;
    for (var i = 16; i < id.length; i++) {
      generation = (generation << 8) | id[i];
    }
    return generation;
  }

  /// A message encrypted in a newer generation than this device follows: it
  /// missed the reset. Asks the server where the channel is (a message is
  /// not taken at its word) and joins the group there first, so the message
  /// can be read. Returns whether the channel moved; a failure leaves the
  /// message to be read as it can.
  Future<bool> _followNewerGeneration(
    String channelId,
    Uint8List message,
  ) async {
    final known = _generations[channelId];
    final sent = generations ? _messageGeneration(channelId, message) : null;
    if (known == null || sent == null || sent <= known) return false;
    try {
      await _moveTo(channelId, await api.groupGeneration(token, channelId));
      if (_generations[channelId] == known) return false;
      await _ensureJoined(channelId);
    } on Object catch (e) {
      debugPrint('channel groups: following $channelId to a newer group: $e');
    }
    return true;
  }

  /// Whether [e], met processing a logged commit or joining from the
  /// published group info, says the commit or group info itself cannot be
  /// processed — not a changed identity (the person's decision), a lost
  /// local store or a group this device does not hold.
  static bool _unprocessable(CryptoException e) => switch (e.kind) {
    CryptoErrorKind.verification ||
    CryptoErrorKind.malformed ||
    CryptoErrorKind.other => true,
    _ => false,
  };

  /// Asks the server to start a new generation of the channel's group, because
  /// [generation]'s cannot get past [reported] (a commit made in [epoch], or
  /// the group info describing it), and follows the channel to the generation
  /// it answers — the new one, or the one another member's report already
  /// started.
  Future<void> _report(
    String channelId,
    int generation,
    int epoch,
    Uint8List reported,
  ) async {
    final result = await api.resetGroup(
      token,
      channelId,
      generation: generation,
      reportedEpoch: epoch,
      reportedSha256: Uint8List.fromList(sha256.convert(reported).bytes),
    );
    debugPrint(
      'channel groups: $channelId ${result.reset ? 'reset to' : 'already in'} '
      'generation ${result.generation}',
    );
    await _moveTo(channelId, result.generation);
  }

  /// The commit of [epoch] in [generation] cannot be processed here. Drops
  /// this device's copy of the group (keeping the cache) and, when [rejoin],
  /// tries once to join again from the published group info: if only this
  /// copy was broken, that is all it takes. If it cannot join either, the
  /// group is broken for everyone: report the commit ([_report]) and, when
  /// [rejoin], create or join the new generation.
  ///
  /// A network failure is not a broken group, and a changed identity is the
  /// person's decision: either stops here without reporting.
  Future<void> _recoverFromBroken(
    String channelId,
    int generation,
    int epoch,
    Uint8List commit, {
    required bool rejoin,
  }) async {
    await engine.resetGroup(groupIdForChannel(channelId, generation));
    _epochChanged(channelId);
    if (rejoin) {
      try {
        await _ensureJoined(channelId, rejoin: false, report: false);
        if (await engine.hasGroup(await _groupId(channelId))) return;
      } on ApiException catch (e) {
        if (e.isNetworkError) rethrow;
        debugPrint('channel groups: rejoining $channelId failed: $e');
      } on CryptoException catch (e) {
        if (e.kind == CryptoErrorKind.identityChanged) rethrow;
        debugPrint('channel groups: rejoining $channelId failed: $e');
      }
    }
    await _report(channelId, generation, epoch, commit);
    if (rejoin) await _ensureJoined(channelId, rejoin: false, report: false);
  }

  // ── Joining ──

  /// [rejoin] is passed on to [_catchUp]; it is false only when this is the
  /// rejoin itself, so a group that falls out of sync again is not rejoined
  /// in a loop. With [rejoin], a group that catching up dropped (the server
  /// asked for a resync, or the channel moved to a new generation) is joined
  /// again straight away.
  ///
  /// [report]: when the published group info cannot be joined from — the core
  /// refuses it, or it is older than the group and every join loses the epoch
  /// — report it ([_report]) and join the new generation. False when the
  /// caller reports what broke itself.
  Future<void> _ensureJoined(
    String channelId, {
    bool rejoin = true,
    bool report = true,
  }) async {
    if (await engine.hasGroup(await _groupId(channelId))) {
      await _catchUp(channelId, rejoin: rejoin);
      if (!rejoin || await engine.hasGroup(await _groupId(channelId))) return;
    } else {
      await _processWelcomes();
      if (await engine.hasGroup(await _groupId(channelId))) {
        await _catchUp(channelId, rejoin: rejoin);
        return;
      }
    }

    GroupState? last;
    for (var attempt = 0; attempt < _commitAttempts; attempt++) {
      final generation = await _generation(channelId);
      final group = groupIdForChannel(channelId, generation);
      GroupState state;
      try {
        state = await api.groupState(token, channelId);
      } on ApiException catch (e) {
        if (e.code != 'group_not_found') rethrow;
        if (await _createGroup(channelId)) return;
        continue; // Somebody else created it first.
      }
      if (generations && state.generation != generation) {
        // The channel moved on since this device last looked.
        await _moveTo(channelId, state.generation);
        continue;
      }
      last = state;

      final info = state.groupInfo;
      if (info == null) {
        throw const ApiException(
          0,
          'group_unavailable',
          'The group has no published state to join from.',
        );
      }

      final ({Uint8List groupId, GroupCommit commit}) join;
      try {
        join = await engine.joinByExternalCommit(group, info);
      } on CryptoException catch (e) {
        // A member's identity changed: joining waits for the person to
        // accept it. The core kept nothing of the attempt.
        _noteIdentityChange(e, channelId, leftGroup: true);
        if (!(report && generations && _unprocessable(e))) rethrow;
        // Nobody can join from this group info: the group needs a new
        // generation.
        await _report(channelId, generation, state.groupInfoEpoch, info);
        return _ensureJoined(channelId, rejoin: rejoin, report: false);
      }
      try {
        await api.submitCommit(token, channelId, join.commit.commit);
      } on ApiException catch (e) {
        // A timeout does not mean a refusal: the server may have appended the
        // join. The group is already merged here, so if the log holds exactly
        // this commit, nothing is wrong and resetting would only throw away the
        // epoch (and the messages sent in it). Anything else, including not
        // being able to ask, is a copy that may have forked: start over.
        if (!(e.isNetworkError && await _serverHolds(channelId, join.commit))) {
          // Keep the cached messages: this device may hold history from an
          // earlier membership, and a join that failed has not lost any of it.
          await engine.resetGroup(group);
          if (e.code != 'epoch_conflict') rethrow;
          await _pause();
          continue; // The group moved on; join from its newer state.
        }
      }
      await engine.mergePendingCommit(group);
      _epochChanged(channelId);
      await _publishGroupInfo(channelId);
      await _catchUp(channelId, rejoin: rejoin);
      return;
    }

    // Every join lost the epoch. With a group info older than the group,
    // nobody is publishing one that could be joined from — a commit nobody can
    // process, most likely — so the group needs a new generation. The server
    // only takes that report once the group info has had time to catch up.
    final stale = last;
    final staleInfo = stale?.groupInfo;
    if (report &&
        generations &&
        stale != null &&
        staleInfo != null &&
        stale.groupInfoEpoch < stale.epoch) {
      await _report(
        channelId,
        stale.generation,
        stale.groupInfoEpoch,
        staleInfo,
      );
      return _ensureJoined(channelId, rejoin: rejoin, report: false);
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
    final group = await _groupId(channelId);
    await engine.createGroup(group);
    try {
      await api.createGroup(token, channelId, await engine.groupInfo(group));
    } on ApiException catch (e) {
      // Reset, not delete: a device that fell out of this group keeps its
      // cached history, and a lost creation race must not erase it.
      await engine.resetGroup(group);
      switch (e.code) {
        case 'group_exists':
          return false;
        case 'group_reserved':
          // Whoever reset the group is creating its new generation; join
          // theirs in a moment.
          await _pause();
          return false;
        case 'wrong_group' when generations:
          // Reset again since this device looked.
          await _moveTo(channelId, await api.groupGeneration(token, channelId));
          return false;
      }
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

  /// Whether the server's log holds exactly [commit] as the commit of the epoch
  /// it was made in. False when the log has another commit there, none, or
  /// cannot be read.
  Future<bool> _serverHolds(String channelId, GroupCommit commit) async {
    final made = commit.epochAfter - 1;
    try {
      final sync = await api.syncGroup(
        token,
        channelId,
        made,
        generation: await _generation(channelId),
      );
      return sync.commits.any(
        (c) => c.epoch == made && listEquals(c.message, commit.commit),
      );
    } on ApiException catch (e) {
      debugPrint('channel groups: could not check $channelId\'s log: $e');
      return false;
    }
  }

  // ── Catching up ──

  Future<void> _catchUpIfMember(String channelId) async {
    if (await engine.hasGroup(await _groupId(channelId))) {
      await _catchUp(channelId);
    }
  }

  /// Processes every commit this device has missed, in order. A device too
  /// far behind (the server pruned what it needs) resets its copy of the group
  /// (keeping its cached messages) and rejoins, if still allowed, the next time
  /// it needs to; one removed from the group deletes the group and its cache.
  ///
  /// A commit that claims to be this device's own but is not the one it holds
  /// ([CryptoErrorKind.resyncRequired] — one it discarded after the server had
  /// taken it, or a forgery) means its copy can no longer follow the server's:
  /// it resets the copy (keeping the cache) and, when [rejoin], joins again by external commit
  /// straight away. A pass that moves the group no further throws
  /// (`group_stalled`) instead of asking for the same commits forever.
  ///
  /// A commit the core refuses for a member's changed identity takes this
  /// device out of the group: the core has already dropped it, keeping its
  /// cached messages, so this does not delete it again, and the error is
  /// rethrown. Joining again checks every member again, so it waits for
  /// [acceptChangedIdentity].
  ///
  /// A commit that cannot be processed at all — it does not decrypt, or a
  /// device it adds does not verify — is a broken group: with [generations]
  /// it is recovered from ([_recoverFromBroken]: rejoin once, else report it
  /// and move to a new generation) and this returns; without, it is rethrown.
  /// A sync that says the channel is in a newer generation drops this
  /// generation's copy and returns.
  ///
  /// A sync that comes back also settles a commit of this device's whose fate
  /// was unknown ([_unsettled]): the commits it brings are processed, which
  /// merges this device's own if it is among them and drops it for another's,
  /// and a log with nothing past this device's epoch proves the server never
  /// got it, so it is discarded.
  ///
  /// Returns whether [ownCommit] was among the commits processed, that is, the
  /// server did take it and this device merged it.
  Future<bool> _catchUp(
    String channelId, {
    bool rejoin = true,
    Uint8List? ownCommit,
  }) async {
    final generation = await _generation(channelId);
    final group = groupIdForChannel(channelId, generation);
    var ownMerged = false;
    while (true) {
      final local = await engine.epoch(group);
      final sync = await api.syncGroup(
        token,
        channelId,
        local,
        generation: generation,
      );
      final unsettled = _unsettled.remove(channelId);
      if (generations && sync.generation > generation) {
        // The group was reset; this generation's log is gone.
        debugPrint('channel groups: $channelId moved to a new generation');
        await _moveTo(channelId, sync.generation);
        return false;
      }
      if (sync.resyncRequired) {
        // The cached messages are the only copy of their plaintext; keep them.
        await engine.resetGroup(group);
        return false;
      }
      if (sync.commits.isEmpty) {
        if (unsettled) await engine.discardPendingCommit(group);
        return ownMerged;
      }

      for (final commit in sync.commits) {
        if (commit.epoch < await engine.epoch(group)) continue;
        final GroupEvent event;
        try {
          event = await engine.process(commit.message);
        } on CryptoException catch (e) {
          if (e.kind != CryptoErrorKind.resyncRequired) {
            if (!await engine.hasGroup(group)) {
              debugPrint('channel groups: left $channelId, commit refused: $e');
              _epochChanged(channelId);
              _noteIdentityChange(e, channelId, leftGroup: true);
            }
            if (!(generations && _unprocessable(e))) rethrow;
            debugPrint(
              'channel groups: $channelId cannot process the commit of '
              'epoch ${commit.epoch}: $e',
            );
            await _recoverFromBroken(
              channelId,
              generation,
              commit.epoch,
              commit.message,
              rejoin: rejoin,
            );
            return false;
          }
          debugPrint('channel groups: $channelId fell out of sync: $e');
          await engine.resetGroup(group);
          _epochChanged(channelId);
          if (rejoin) await _ensureJoined(channelId, rejoin: false);
          return false;
        }
        if (ownCommit != null && listEquals(commit.message, ownCommit)) {
          ownMerged = true;
        }
        if (event is GroupMembershipChanged && event.removedSelf) {
          // Out of the channel's group: its history goes, in every
          // generation this device kept any of.
          for (var old = 0; old <= generation; old++) {
            await engine.deleteGroup(groupIdForChannel(channelId, old));
          }
          _epochChanged(channelId);
          return false;
        }
      }
      _epochChanged(channelId);
      final reached = await engine.epoch(group);
      if (reached >= sync.epoch) return ownMerged;
      if (reached <= local) {
        throw const ApiException(
          0,
          'group_stalled',
          'Catching up on the channel\'s encryption group made no progress.',
        );
      }
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
      if (await engine.hasGroup(await _groupId(channelId))) {
        await _catchUp(channelId);
        await _reconcile(channelId);
      }
    });
  }

  /// Commits the difference between the group and the roster.
  Future<void> _reconcile(String channelId) async {
    for (var attempt = 0; attempt < _commitAttempts; attempt++) {
      final group = await _groupId(channelId);
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
  ///
  /// Any other refusal discards it and is rethrown. A network failure is not a
  /// refusal: the server may have appended the commit before the answer was
  /// lost, and a discarded commit that the server took comes back as an echo
  /// this device can no longer follow (a resync, rejoining and losing the
  /// messages in between). So it stays pending until the log says what became of
  /// it ([_settle]).
  Future<void> _submit(
    String channelId,
    GroupCommit commit, {
    List<DeviceRef> recipients = const [],
  }) async {
    final group = await _groupId(channelId);
    try {
      await api.submitCommit(
        token,
        channelId,
        commit.commit,
        welcome: commit.welcome,
        welcomeRecipients: recipients,
      );
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        await _settle(channelId, commit, e);
        return;
      }
      await engine.discardPendingCommit(group);
      if (e.code == 'epoch_conflict') throw const _CommitLost();
      rethrow;
    }
    await engine.mergePendingCommit(group);
    _epochChanged(channelId);
    await _publishGroupInfo(channelId);
  }

  /// [commit] was submitted and the network failed, so the server may or may
  /// not have it. Syncs, which answers: returns if the server had it and this
  /// device merged it, throws [_CommitLost] if another commit took the epoch
  /// (this device followed it, and its own is gone), and throws [cause] if the
  /// server never got it (the commit is discarded) or the group could not be
  /// checked. When the sync cannot run either, the commit stays pending and
  /// [_unsettled] makes the next successful sync decide.
  ///
  /// No new commit is made on the channel while one is pending and unsettled:
  /// every way to make one syncs first, which settles it or throws.
  Future<void> _settle(
    String channelId,
    GroupCommit commit,
    ApiException cause,
  ) async {
    final group = await _groupId(channelId);
    final before = await engine.epoch(group);
    _unsettled.add(channelId);
    final bool merged;
    try {
      // Not rejoining: a group that cannot follow the log is reset, and the
      // next use joins it again, as it would if this had not happened.
      merged = await _catchUp(
        channelId,
        rejoin: false,
        ownCommit: commit.commit,
      );
    } on ApiException catch (e) {
      debugPrint('channel groups: $channelId commit left pending: $e');
      throw cause;
    }
    if (merged) {
      await _publishGroupInfo(channelId);
      return;
    }
    if (await engine.hasGroup(group) && await engine.epoch(group) > before) {
      throw const _CommitLost();
    }
    throw cause;
  }

  Future<void> _publishGroupInfo(String channelId) async {
    try {
      await api.putGroupInfo(
        token,
        channelId,
        await engine.groupInfo(await _groupId(channelId)),
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
      try {
        final group = await _groupId(welcome.channelId);
        if (!await engine.hasGroup(group)) {
          final joined = await engine.joinFromWelcome(welcome.welcome);
          if (await _isCurrentGroup(welcome.channelId, joined)) {
            await _catchUp(welcome.channelId, rejoin: false);
          } else {
            // Into a generation the channel has left, or another group
            // altogether: not one to stay in.
            debugPrint(
              'channel groups: welcome to ${welcome.channelId} '
              'is not for its current group',
            );
            await engine.resetGroup(joined);
          }
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

  /// Whether [groupId] is the channel's group in its current generation —
  /// asking the server again before saying no, since a Welcome may be the
  /// first this device hears of a new one.
  Future<bool> _isCurrentGroup(String channelId, Uint8List groupId) async {
    if (listEquals(groupId, await _groupId(channelId))) return true;
    if (!generations) return false;
    await _moveTo(channelId, await api.groupGeneration(token, channelId));
    return listEquals(groupId, await _groupId(channelId));
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

/// A member's identity key did not match the one this device pinned for
/// them, met in [channelId]. [leftGroup]: it took this device out of the
/// channel's group (their commit was refused, or joining was), which
/// [ChannelGroups.acceptChangedIdentity] joins again; otherwise a message of
/// theirs is held until then.
@immutable
class IdentityChange {
  const IdentityChange({
    required this.userId,
    required this.channelId,
    required this.leftGroup,
    this.pinnedKey,
    this.presentedKey,
  });

  final String userId;
  final String channelId;
  final bool leftGroup;

  /// The key this device had pinned for them, and the one they presented
  /// (what [ChannelGroups.acceptChangedIdentity] takes). Null when the core
  /// gave none.
  final Uint8List? pinnedKey;
  final Uint8List? presentedKey;
}

class _CommitLost implements Exception {
  const _CommitLost();
}
