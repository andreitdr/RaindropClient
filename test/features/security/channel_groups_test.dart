// ChannelGroups' catching up, against a fake engine and a fake delivery
// service, so the ways it can stop following a group (and come back to it) are
// checked without the Rust core or a server.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/crypto_engine.dart';
import 'package:raindrop_client/core/network/api_exception.dart';
import 'package:raindrop_client/core/network/e2ee_api.dart';
import 'package:raindrop_client/features/security/controllers/channel_groups.dart';
import 'package:raindrop_client/features/security/controllers/identity_changes.dart';

const _channel = '6f1c2d3e-4a5b-4c6d-8e7f-001122334455';
final _group = groupIdForChannel(_channel);

/// One group, its epoch, and what processing a commit does to it.
class _FakeEngine implements CryptoEngine {
  _FakeEngine({required this.onProcess});

  final Future<GroupEvent> Function(_FakeEngine engine) onProcess;
  bool held = true;
  int current = 5;
  int deletes = 0;
  int resets = 0;

  /// How many messages the local cache holds for the group: [deleteGroup]
  /// clears it, [resetGroup] keeps it, as the core's two calls do.
  int cacheSize = 3;
  int externalJoins = 0;
  final accepted = <String>[];

  /// What the core's encrypted store lists as waiting for the person: a
  /// refusal adds to it, accepting that key clears it.
  final pendingChanges = <PendingIdentityChange>[];

  /// When set, [receiveMessage] refuses with it.
  CryptoException? receiveError;

  /// The commit this device made and still holds as pending, and how many
  /// commits it made (each has its own bytes).
  Uint8List? pending;
  int made = 0;
  int discards = 0;

  /// The message [process] was last given.
  Uint8List? lastMessage;

  /// What [receiveMessage] answers: the cached copy of a message.
  DecryptedMessage? cached;

  @override
  Future<void> acceptChangedIdentity(
    String userId,
    Uint8List identityKey,
  ) async {
    accepted.add(userId);
    pendingChanges.removeWhere(
      (c) => c.userId == userId && listEquals(c.presentedKey, identityKey),
    );
  }

  @override
  Future<List<PendingIdentityChange>> pendingIdentityChanges() async =>
      List.of(pendingChanges);

  @override
  Future<DecryptedMessage?> receiveMessage({
    required String messageId,
    required DateTime sentAt,
    required Uint8List message,
  }) async {
    final error = receiveError;
    if (error != null) throw error;
    return cached;
  }

  @override
  Future<bool> hasGroup(Uint8List groupId) async => held;

  @override
  Future<int> epoch(Uint8List groupId) async {
    if (!held) throw const CryptoException(CryptoErrorKind.notFound, 'group');
    return current;
  }

  @override
  Future<GroupEvent> process(Uint8List message) {
    lastMessage = message;
    return onProcess(this);
  }

  @override
  Future<GroupCommit> selfUpdate(Uint8List groupId) async {
    final commit = Uint8List.fromList([9, ++made]);
    pending = commit;
    return GroupCommit(commit: commit, welcome: null, epochAfter: current + 1);
  }

  @override
  Future<void> discardPendingCommit(Uint8List groupId) async {
    pending = null;
    discards++;
  }

  @override
  Future<void> deleteGroup(Uint8List groupId) async {
    held = false;
    deletes++;
    cacheSize = 0;
  }

  @override
  Future<void> resetGroup(Uint8List groupId) async {
    held = false;
    pending = null;
    resets++;
  }

  @override
  Future<({Uint8List groupId, GroupCommit commit})> joinByExternalCommit(
    Uint8List expectedGroupId,
    Uint8List groupInfo,
  ) async {
    externalJoins++;
    held = true;
    current = 7;
    return (
      groupId: expectedGroupId,
      commit: GroupCommit(
        commit: Uint8List.fromList([7]),
        welcome: null,
        epochAfter: 7,
      ),
    );
  }

  @override
  Future<int> mergePendingCommit(Uint8List groupId) async {
    if (pending != null) current++;
    pending = null;
    return current;
  }

  @override
  Future<Uint8List> groupInfo(Uint8List groupId) async => Uint8List(1);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// The delivery service: one commit waiting at epoch 5, the group's state
/// to join from, and nothing after epoch 7.
class _FakeApi implements E2eeApi {
  int syncs = 0;
  final submitted = <Uint8List>[];

  /// The server answers the first sync with "resync required".
  bool resyncRequiredFirst = false;

  /// Reasons the next commit submissions are refused with, in order.
  final submitRefusals = <String>[];

  /// A server with a real log, in place of the canned commit below: the
  /// commits it holds, the first made in epoch [logBase]. A submission it
  /// accepts is appended; [logOnRefusal] says what a refused one leaves behind
  /// (a refusal that is only the answer being lost leaves the commit itself).
  final log = <({int epoch, Uint8List message})>[];
  bool useLog = false;
  int logBase = 5;
  Uint8List? Function(Uint8List commit)? logOnRefusal;

  /// Syncs after this many fail as the network being down.
  int? offlineAfterSyncs;

  void _append(Uint8List message) =>
      log.add((epoch: logBase + log.length, message: message));

  @override
  Future<GroupSync> syncGroup(
    String token,
    String channelId,
    int fromEpoch, {
    int generation = 0,
  }) async {
    // Never loop forever, whatever the code under test does.
    if (++syncs > 5) throw StateError('synced $syncs times');
    final offlineAfter = offlineAfterSyncs;
    if (offlineAfter != null && syncs > offlineAfter) {
      throw const ApiException(0, 'network_error', 'offline');
    }
    if (useLog) {
      return GroupSync(
        epoch: logBase + log.length,
        commits: [
          for (final c in log)
            if (c.epoch >= fromEpoch) c,
        ],
        resyncRequired: false,
      );
    }
    if (resyncRequiredFirst && syncs == 1) {
      return const GroupSync(epoch: 7, commits: [], resyncRequired: true);
    }
    if (fromEpoch >= 7) {
      return const GroupSync(epoch: 7, commits: [], resyncRequired: false);
    }
    return GroupSync(
      epoch: 6,
      commits: [
        (epoch: 5, message: Uint8List.fromList([5])),
      ],
      resyncRequired: false,
    );
  }

  @override
  Future<List<PendingWelcome>> welcomes(String token) async => const [];

  @override
  Future<GroupState> groupState(String token, String channelId) async =>
      GroupState(epoch: 6, groupInfo: Uint8List(1), groupInfoEpoch: 6);

  @override
  Future<int> submitCommit(
    String token,
    String channelId,
    Uint8List commit, {
    Uint8List? welcome,
    List<DeviceRef> welcomeRecipients = const [],
  }) async {
    if (submitRefusals.isNotEmpty) {
      final left = logOnRefusal?.call(commit);
      if (left != null) _append(left);
      throw ApiException(0, submitRefusals.removeAt(0), 'refused');
    }
    submitted.add(commit);
    if (useLog) _append(commit);
    return 7;
  }

  @override
  Future<GroupState> putGroupInfo(
    String token,
    String channelId,
    Uint8List groupInfo,
  ) async => GroupState(epoch: 7, groupInfo: groupInfo, groupInfoEpoch: 7);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// What the core does with a commit from a member whose identity changed:
/// refuses it, and with it the group.
Future<GroupEvent> _refuseForBob(_FakeEngine engine) async {
  engine.held = false;
  // The core writes the refusal down before it returns it.
  engine.pendingChanges
    ..removeWhere((c) => c.userId == 'bob')
    ..add(_bobsChange);
  throw _bobChanged;
}

final _bobsOldKey = Uint8List.fromList([1]);
final _bobsNewKey = Uint8List.fromList([2]);

/// Bob presented a new key and the group was left because of it.
final _bobsChange = PendingIdentityChange(
  userId: 'bob',
  pinnedKey: _bobsOldKey,
  presentedKey: _bobsNewKey,
  leftGroupIds: [_group],
);

final _bobChanged = CryptoException(
  CryptoErrorKind.identityChanged,
  'the identity key of user bob changed',
  userId: 'bob',
  pinnedKey: _bobsOldKey,
  presentedKey: _bobsNewKey,
);

/// What the core does with the log's commits when this device made a commit
/// of its own: its own echo (the very bytes) merges, another's replaces the
/// pending one, and an own commit it does not hold is a resync.
Future<GroupEvent> _followLog(_FakeEngine engine) async {
  final message = engine.lastMessage!;
  final own = message.length == 2 && message[0] == 9;
  if (own && engine.pending != message) {
    throw const CryptoException(CryptoErrorKind.resyncRequired, 'not held');
  }
  engine.pending = null;
  engine.current++;
  return GroupMembershipChanged(
    _group,
    engine.current,
    added: const [],
    removed: const [],
    removedSelf: false,
  );
}

ChannelGroups _groups(CryptoEngine engine, E2eeApi api) => ChannelGroups(
  engine: engine,
  api: api,
  token: 'token',
  self: const DeviceRef(userId: 'alice', deviceId: 'a1'),
);

void main() {
  test('a catch-up pass that moves the group no further stops', () async {
    // A commit that leaves the epoch where it was: before, the same sync
    // was asked for again and again.
    final engine = _FakeEngine(
      onProcess: (e) async => GroupOwnMessage(_group, e.current),
    );
    final api = _FakeApi();

    await expectLater(
      _groups(engine, api).catchUp(_channel),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'group_stalled'),
      ),
    );
    expect(api.syncs, 1);
    expect(engine.deletes, 0);
  });

  test('an own commit this device does not hold rejoins the group', () async {
    final engine = _FakeEngine(
      onProcess: (_) async => throw const CryptoException(
        CryptoErrorKind.resyncRequired,
        'own commit echoed that this device does not hold; rejoin the group',
      ),
    );
    final api = _FakeApi();

    await _groups(engine, api).catchUp(_channel);

    // Reset, not deleted: the cached messages are the only copy of history.
    expect(engine.resets, 1);
    expect(engine.deletes, 0);
    expect(engine.cacheSize, 3);
    expect(engine.externalJoins, 1);
    expect(api.submitted, [
      [7],
    ]);
    expect(engine.held, isTrue);
    expect(engine.current, 7);
  });

  test('a server that demands a resync resets the group and keeps the cache, '
      'and the next use rejoins', () async {
    final engine = _FakeEngine(
      onProcess: (e) async => GroupOwnMessage(_group, 7),
    );
    final api = _FakeApi()..resyncRequiredFirst = true;
    final groups = _groups(engine, api);

    await groups.catchUp(_channel);
    expect(engine.resets, 1);
    expect(engine.deletes, 0);
    expect(engine.held, isFalse);
    expect(engine.cacheSize, 3);

    await groups.ensureJoined(_channel);
    expect(engine.externalJoins, 1);
    expect(engine.held, isTrue);
    expect(engine.cacheSize, 3);
  });

  test(
    'a rejoin refused with epoch_conflict keeps the cache and joins again',
    () async {
      final engine = _FakeEngine(onProcess: _refuseForBob)..held = false;
      final api = _FakeApi()..submitRefusals.add('epoch_conflict');

      await _groups(engine, api).ensureJoined(_channel);

      expect(engine.externalJoins, 2);
      expect(engine.resets, 1);
      expect(engine.deletes, 0);
      expect(engine.cacheSize, 3);
      expect(engine.held, isTrue);
    },
  );

  test('a rejoin refused for another reason also keeps the cache', () async {
    final engine = _FakeEngine(onProcess: _refuseForBob)..held = false;
    final api = _FakeApi()..submitRefusals.add('forbidden');

    await expectLater(
      _groups(engine, api).ensureJoined(_channel),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'forbidden')),
    );
    expect(engine.resets, 1);
    expect(engine.deletes, 0);
    expect(engine.cacheSize, 3);
  });

  test('being removed from the group deletes it with its cache', () async {
    final engine = _FakeEngine(
      onProcess: (e) async => GroupMembershipChanged(
        _group,
        6,
        added: const [],
        removed: const [],
        removedSelf: true,
      ),
    );
    final api = _FakeApi();

    await _groups(engine, api).catchUp(_channel);

    expect(engine.deletes, 1);
    expect(engine.resets, 0);
    expect(engine.cacheSize, 0);
    expect(engine.externalJoins, 0);
  });

  test('a commit refused for a changed identity leaves the group once, '
      'keeping its cache, and accepting the change joins again', () async {
    final engine = _FakeEngine(onProcess: _refuseForBob);
    final api = _FakeApi();
    final groups = _groups(engine, api);
    final changes = <IdentityChange>[];
    groups.identityChanges.listen(changes.add);

    await expectLater(
      groups.catchUp(_channel),
      throwsA(
        isA<CryptoException>()
            .having((e) => e.kind, 'kind', CryptoErrorKind.identityChanged)
            .having((e) => e.userId, 'userId', 'bob'),
      ),
    );
    // The core dropped the group; deleting it here as well would have wiped
    // the cached messages. Nothing is joined before the person decides.
    expect(api.syncs, 1);
    expect(engine.deletes, 0);
    expect(engine.externalJoins, 0);
    expect(engine.held, isFalse);
    await pumpEventQueue();
    expect(changes, hasLength(1));
    expect(changes.single.userId, 'bob');
    expect(changes.single.channelId, _channel);
    expect(changes.single.leftGroup, isTrue);
    // The event carries what the confirmation needs to accept it.
    expect(changes.single.presentedKey, _bobsNewKey);
    expect(changes.single.pinnedKey, _bobsOldKey);
    expect(await groups.pendingIdentityChanges(), [_bobsChange]);

    await groups.acceptChangedIdentity('bob', _bobsNewKey);
    expect(engine.accepted, ['bob']);
    expect(await groups.pendingIdentityChanges(), isEmpty);
    expect(engine.externalJoins, 1);
    expect(api.submitted, [
      [7],
    ]);
    expect(engine.held, isTrue);
    expect(engine.current, 7);
  });

  test(
    'a change left pending when the app closed is raised again on the next '
    'start, does nothing until accepted, and then joins the channel',
    () async {
      // The core recorded the refusal in its store; nothing of the earlier
      // run's memory is left in the new ChannelGroups.
      final engine = _FakeEngine(onProcess: _refuseForBob)
        ..held = false
        ..pendingChanges.add(_bobsChange);
      final api = _FakeApi();
      final restarted = _groups(engine, api);
      final raised = <IdentityChange>[];
      restarted.identityChanges.listen(raised.add);

      await restarted.announcePendingIdentityChanges();
      await pumpEventQueue();
      expect(raised, hasLength(1));
      expect(raised.single.userId, 'bob');
      expect(raised.single.channelId, _channel);
      expect(raised.single.leftGroup, isTrue);
      expect(raised.single.presentedKey, _bobsNewKey);

      // Nothing is accepted or joined by being told.
      expect(engine.accepted, isEmpty);
      expect(engine.externalJoins, 0);
      expect(engine.held, isFalse);
      expect(api.submitted, isEmpty);

      // Accepting a key bob did not present changes nothing, either.
      await restarted.acceptChangedIdentity('bob', Uint8List.fromList([9]));
      expect(engine.externalJoins, 0);
      expect(engine.held, isFalse);

      await restarted.acceptChangedIdentity('bob', _bobsNewKey);
      expect(engine.externalJoins, 1);
      expect(engine.held, isTrue);
      expect(api.submitted, [
        [7],
      ]);
      expect(engine.pendingChanges, isEmpty);
    },
  );

  test('a message held for a changed identity is not an undecryptable one, '
      'and is announced', () async {
    final engine = _FakeEngine(onProcess: _refuseForBob)
      ..receiveError = _bobChanged;
    final groups = _groups(engine, _FakeApi());
    final changes = <IdentityChange>[];
    groups.identityChanges.listen(changes.add);

    Future<({Uint8List? payload, bool held})> read() => groups.decryptOrHeld(
      channelId: _channel,
      messageId: 'm1',
      sentAt: DateTime.utc(2026),
      ciphertext: Uint8List.fromList([9]),
      epoch: 5,
      senderDeviceId: 'b1',
    );

    final held = await read();
    expect(held.held, isTrue);
    expect(held.payload, isNull);
    await pumpEventQueue();
    expect(changes.single.leftGroup, isFalse);
    expect(changes.single.presentedKey, _bobsNewKey);

    // Any other failure is just a message this device cannot read.
    engine.receiveError = const CryptoException(
      CryptoErrorKind.other,
      'not for this device',
    );
    final unreadable = await read();
    expect(unreadable.held, isFalse);
    expect(unreadable.payload, isNull);
  });

  test(
    'a message whose catch-up is refused is still read from the cache',
    () async {
      final engine = _FakeEngine(onProcess: _refuseForBob)
        ..cached = DecryptedMessage(
          groupId: _group,
          messageId: 'm1',
          senderUserId: 'carol',
          senderDeviceId: 'c1',
          epoch: 5,
          sentAt: DateTime.utc(2026),
          payload: Uint8List.fromList([1, 2, 3]),
        );
      final api = _FakeApi();
      final groups = _groups(engine, api);

      final payload = await groups.decrypt(
        channelId: _channel,
        messageId: 'm1',
        sentAt: DateTime.utc(2026),
        ciphertext: Uint8List.fromList([9]),
        epoch: 6,
        senderDeviceId: 'c1',
      );
      expect(payload, [1, 2, 3]);
      expect(api.syncs, 1);

      // The group is gone: a later message does not try to catch up again.
      await groups.decrypt(
        channelId: _channel,
        messageId: 'm2',
        sentAt: DateTime.utc(2026),
        ciphertext: Uint8List.fromList([9]),
        epoch: 6,
        senderDeviceId: 'c1',
      );
      expect(api.syncs, 1);
      expect(engine.externalJoins, 0);
    },
  );

  group('the pending identity changes the person sees', () {
    const server = 'server-1';

    ProviderContainer containerFor(ChannelGroups groups) {
      final container = ProviderContainer(
        overrides: [
          channelGroupsProvider.overrideWith((ref, serverId) async => groups),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('are read from the core after a restart, and accepting one rejoins '
        'the channel it took this device out of', () async {
      final engine = _FakeEngine(onProcess: _refuseForBob)
        ..held = false
        ..pendingChanges.add(_bobsChange);
      final api = _FakeApi();
      final container = containerFor(_groups(engine, api));

      expect(
        await container.read(pendingIdentityChangesProvider(server).future),
        [_bobsChange],
      );
      // Listing them does nothing.
      expect(engine.accepted, isEmpty);
      expect(engine.externalJoins, 0);

      await container
          .read(pendingIdentityChangesProvider(server).notifier)
          .accept(_bobsChange);

      expect(engine.accepted, ['bob']);
      expect(engine.externalJoins, 1);
      expect(engine.held, isTrue);
      expect(
        container.read(pendingIdentityChangesProvider(server)).value,
        isEmpty,
      );
    });

    test('follow a change met while the app is open, and stay until the '
        'person accepts', () async {
      final engine = _FakeEngine(onProcess: _refuseForBob);
      final api = _FakeApi();
      final groups = _groups(engine, api);
      final container = containerFor(groups);
      expect(
        await container.read(pendingIdentityChangesProvider(server).future),
        isEmpty,
      );

      await expectLater(
        groups.catchUp(_channel),
        throwsA(isA<CryptoException>()),
      );
      await pumpEventQueue();

      expect(container.read(pendingIdentityChangesProvider(server)).value, [
        _bobsChange,
      ]);
      expect(engine.accepted, isEmpty);
      expect(engine.externalJoins, 0);

      // Asking again and again (every held message reports it) changes nothing.
      for (var i = 0; i < 3; i++) {
        await container
            .read(pendingIdentityChangesProvider(server).notifier)
            .refresh();
      }
      expect(container.read(pendingIdentityChangesProvider(server)).value, [
        _bobsChange,
      ]);
      expect(engine.accepted, isEmpty);
    });
  });

  group('a commit whose submission failed on the network', () {
    final network = ['network_error'];
    // A server whose log holds what the test says, and a device in sync with
    // it, at epoch 5.
    (_FakeEngine, _FakeApi) setUp() {
      final engine = _FakeEngine(onProcess: _followLog);
      final api = _FakeApi()
        ..useLog = true
        ..submitRefusals.addAll(network);
      return (engine, api);
    }

    test(
      'that the server did take merges from its echo, with no rejoin',
      () async {
        final (engine, api) = setUp();
        api.logOnRefusal = (commit) => commit;

        await _groups(engine, api).rotate(_channel);

        expect(engine.current, 6);
        expect(engine.pending, isNull);
        expect(engine.discards, 0);
        expect(engine.resets, 0);
        expect(engine.externalJoins, 0);
        expect(
          api.syncs,
          2,
        ); // The ensure-joined sync, and the one that settled it.
      },
    );

    test('that the server never got is discarded once a sync proves it, '
        'and the error is rethrown', () async {
      final (engine, api) = setUp();

      await expectLater(
        _groups(engine, api).rotate(_channel),
        throwsA(
          isA<ApiException>().having((e) => e.isNetworkError, 'net', true),
        ),
      );

      expect(engine.current, 5);
      expect(engine.pending, isNull);
      expect(engine.discards, 1);
      expect(engine.resets, 0);
      expect(engine.externalJoins, 0);
    });

    test('that another commit beat to the epoch is dropped for it', () async {
      final (engine, api) = setUp();
      api.logOnRefusal = (_) => Uint8List.fromList([1]);

      await _groups(engine, api).rotate(_channel);

      expect(engine.current, 6);
      expect(engine.pending, isNull);
      expect(engine.resets, 0);
      expect(engine.externalJoins, 0);
    });

    test('with the network still down stays pending, and the next sync that '
        'gets through merges it if the server had it', () async {
      final (engine, api) = setUp();
      api.logOnRefusal = (commit) => commit;
      api.offlineAfterSyncs = 1;
      final groups = _groups(engine, api);

      await expectLater(
        groups.rotate(_channel),
        throwsA(
          isA<ApiException>().having((e) => e.isNetworkError, 'net', true),
        ),
      );
      expect(engine.pending, isNotNull);
      expect(engine.discards, 0);
      expect(engine.current, 5);

      api.offlineAfterSyncs = null;
      await groups.ensureJoined(_channel);

      expect(engine.current, 6);
      expect(engine.pending, isNull);
      expect(engine.discards, 0);
      expect(engine.resets, 0);
      expect(engine.externalJoins, 0);
    });

    test(
      'with the network still down stays pending, and the next use discards '
      'it when the server never had it, before making a new commit',
      () async {
        final (engine, api) = setUp();
        api.offlineAfterSyncs = 1;
        final groups = _groups(engine, api);

        await expectLater(
          groups.rotate(_channel),
          throwsA(
            isA<ApiException>().having((e) => e.isNetworkError, 'net', true),
          ),
        );
        expect(engine.pending, isNotNull);
        expect(engine.discards, 0);

        api.offlineAfterSyncs = null;
        await groups.rotate(_channel);

        expect(engine.discards, 1);
        expect(engine.made, 2);
        expect(api.submitted, [
          [9, 2],
        ]);
        expect(engine.current, 6);
        expect(engine.pending, isNull);
        expect(engine.resets, 0);
        expect(engine.externalJoins, 0);
      },
    );

    test('refused with epoch_conflict is discarded straight away', () async {
      final engine = _FakeEngine(onProcess: _followLog);
      final api = _FakeApi()
        ..useLog = true
        ..submitRefusals.add('epoch_conflict');

      await _groups(engine, api).rotate(_channel);

      expect(engine.discards, 1);
      expect(engine.pending, isNull);
      expect(engine.resets, 0);
      // Ensure-joined and the catch-up after losing: none to settle.
      expect(api.syncs, 2);
    });

    test(
      'a refusal for another reason is discarded straight away too',
      () async {
        final engine = _FakeEngine(onProcess: _followLog);
        final api = _FakeApi()
          ..useLog = true
          ..submitRefusals.add('forbidden');

        await expectLater(
          _groups(engine, api).rotate(_channel),
          throwsA(
            isA<ApiException>().having((e) => e.code, 'code', 'forbidden'),
          ),
        );
        expect(engine.discards, 1);
        expect(engine.pending, isNull);
        expect(api.syncs, 1);
      },
    );
  });

  group('a join commit whose submission failed on the network', () {
    test('that the server did take keeps the group joined', () async {
      final engine = _FakeEngine(onProcess: _followLog)..held = false;
      // The join is made in epoch 6 and lands in 7.
      final api = _FakeApi()
        ..useLog = true
        ..logBase = 6
        ..submitRefusals.add('network_error')
        ..logOnRefusal = (commit) => commit;

      await _groups(engine, api).ensureJoined(_channel);

      expect(engine.externalJoins, 1);
      expect(engine.resets, 0);
      expect(engine.held, isTrue);
      expect(engine.current, 7);
    });

    test('that the server never got resets the group, keeping the cache, '
        'and rethrows', () async {
      final engine = _FakeEngine(onProcess: _followLog)..held = false;
      final api = _FakeApi()
        ..useLog = true
        ..logBase = 6
        ..submitRefusals.add('network_error');

      await expectLater(
        _groups(engine, api).ensureJoined(_channel),
        throwsA(
          isA<ApiException>().having((e) => e.isNetworkError, 'net', true),
        ),
      );
      expect(engine.resets, 1);
      expect(engine.deletes, 0);
      expect(engine.cacheSize, 3);
    });

    test('that cannot be checked resets the group', () async {
      final engine = _FakeEngine(onProcess: _followLog)..held = false;
      final api = _FakeApi()
        ..useLog = true
        ..logBase = 6
        ..submitRefusals.add('network_error')
        ..offlineAfterSyncs = 0
        ..logOnRefusal = (commit) => commit;

      await expectLater(
        _groups(engine, api).ensureJoined(_channel),
        throwsA(
          isA<ApiException>().having((e) => e.isNetworkError, 'net', true),
        ),
      );
      expect(engine.resets, 1);
      expect(engine.cacheSize, 3);
    });
  });
}
