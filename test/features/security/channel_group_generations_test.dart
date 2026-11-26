// ChannelGroups recovering a channel group nobody can follow: a commit no
// member can process makes a device rejoin once, then report it, and the
// channel moves to a new generation of its group. Against a fake delivery
// service that keeps generations the way the server does (one reset per
// generation, a report must name a logged commit or the group info) and fake
// engines whose bytes say what they are, so several devices can share it.

import 'package:crypto/crypto.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/crypto_engine.dart';
import 'package:raindrop_client/core/network/api_exception.dart';
import 'package:raindrop_client/core/network/e2ee_api.dart';
import 'package:raindrop_client/core/network/event_stream.dart';
import 'package:raindrop_client/core/network/grpc/protocol.dart' as pb;
import 'package:raindrop_client/features/security/controllers/channel_groups.dart';

const _channel = '6f1c2d3e-4a5b-4c6d-8e7f-001122334455';

Uint8List _group(int generation) => groupIdForChannel(_channel, generation);

/// A commit: `[0xC0, generation, epoch, tag]`. Tag [_broken] is one nobody
/// can process — garbage, as far as any member can tell.
Uint8List _commit(int generation, int epoch, int tag) =>
    Uint8List.fromList([0xC0, generation, epoch, tag]);
const _broken = 0xBA;

/// An application message with real MLS framing (the client reads its group
/// id the way the server does): version, wire format private_message, the
/// group id, an epoch of 0, content type application, then the payload.
Uint8List _message(int generation, List<int> payload) {
  final id = _group(generation);
  const header = [0, 1, 0, 2];
  final epochAndType = [...List.filled(8, 0), 1];
  return Uint8List.fromList([
    ...header,
    id.length,
    ...id,
    ...epochAndType,
    ...payload,
  ]);
}

/// A group info: `[0x61, generation, epoch]`.
Uint8List _info(int generation, int epoch) =>
    Uint8List.fromList([0x61, generation, epoch]);

ApiException _refusal(String code) => ApiException(0, code, code);

/// The delivery service for one channel, keeping generations as the server
/// does.
class _Server {
  int generation = 0;

  /// The current generation's group: null until it is created.
  int? epoch;
  Uint8List? info;
  int infoEpoch = 0;
  final log = <({int epoch, Uint8List message})>[];

  /// Who reset the current generation; only they may create it.
  String? reservedFor;

  /// Every reset asked for, accepted or not.
  final resetCalls = <({String token, int generation, int epoch})>[];
  int resets = 0;

  /// The answer to every reset after the first, if any.
  String? refuseLaterResets;

  /// Whether a broken commit lands in every new generation as soon as it is
  /// created: an attacker who keeps at it.
  bool breakEveryGeneration = false;

  void create(int generation, int epoch) {
    this.generation = generation;
    this.epoch = epoch;
    info = _info(generation, epoch);
    infoEpoch = epoch;
    log.clear();
  }

  /// A member's commit nobody can process, at the current epoch.
  void breakGroup({int? generation}) {
    final at = epoch!;
    log.add((
      epoch: at,
      message: _commit(generation ?? this.generation, at, _broken),
    ));
    epoch = at + 1;
  }
}

/// One device's view of the server.
class _Api implements E2eeApi {
  _Api(this.server, this.name);

  final _Server server;
  final String name;
  int syncs = 0;

  @override
  Future<int> groupGeneration(String token, String channelId) async =>
      server.generation;

  @override
  Future<GroupState> groupState(String token, String channelId) async {
    final epoch = server.epoch;
    if (epoch == null) throw _refusal('group_not_found');
    return GroupState(
      epoch: epoch,
      groupInfo: server.info,
      groupInfoEpoch: server.infoEpoch,
      generation: server.generation,
    );
  }

  @override
  Future<GroupState> createGroup(
    String token,
    String channelId,
    Uint8List groupInfo,
  ) async {
    if (groupInfo[1] != server.generation) throw _refusal('wrong_group');
    if (server.epoch != null) throw _refusal('group_exists');
    final reserved = server.reservedFor;
    if (reserved != null && reserved != name) {
      throw _refusal('group_reserved');
    }
    server.create(groupInfo[1], groupInfo[2]);
    if (server.breakEveryGeneration) server.breakGroup();
    return groupState(token, channelId);
  }

  @override
  Future<int> submitCommit(
    String token,
    String channelId,
    Uint8List commit, {
    Uint8List? welcome,
    List<DeviceRef> welcomeRecipients = const [],
  }) async {
    final epoch = server.epoch;
    if (epoch == null) throw _refusal('group_not_found');
    if (commit[1] != server.generation) throw _refusal('wrong_group');
    if (commit[2] != epoch) throw _refusal('epoch_conflict');
    server.log.add((epoch: epoch, message: commit));
    server.epoch = epoch + 1;
    return epoch + 1;
  }

  @override
  Future<GroupState> putGroupInfo(
    String token,
    String channelId,
    Uint8List groupInfo,
  ) async {
    if (groupInfo[1] != server.generation || groupInfo[2] != server.epoch) {
      throw _refusal('epoch_conflict');
    }
    server
      ..info = groupInfo
      ..infoEpoch = groupInfo[2];
    return groupState(token, channelId);
  }

  @override
  Future<GroupSync> syncGroup(
    String token,
    String channelId,
    int fromEpoch, {
    int generation = 0,
  }) async {
    // Never loop forever, whatever the code under test does.
    if (++syncs > 40) throw StateError('$name synced $syncs times');
    if (generation != server.generation) {
      return GroupSync(
        epoch: server.epoch ?? 0,
        commits: const [],
        resyncRequired: true,
        generation: server.generation,
      );
    }
    final epoch = server.epoch;
    if (epoch == null) throw _refusal('group_not_found');
    return GroupSync(
      epoch: epoch,
      commits: [
        for (final c in server.log)
          if (c.epoch >= fromEpoch) c,
      ],
      resyncRequired: false,
      generation: server.generation,
    );
  }

  @override
  Future<({int generation, bool reset})> resetGroup(
    String token,
    String channelId, {
    required int generation,
    int reportedEpoch = 0,
    Uint8List? reportedSha256,
  }) async {
    server.resetCalls.add((
      token: name,
      generation: generation,
      epoch: reportedEpoch,
    ));
    if (generation < server.generation) {
      return (generation: server.generation, reset: false);
    }
    final refusal = server.refuseLaterResets;
    if (refusal != null && server.resets > 0) throw _refusal(refusal);
    bool matches(Uint8List bytes) =>
        listEquals(sha256.convert(bytes).bytes, reportedSha256);
    final reported =
        server.log.any((c) => c.epoch == reportedEpoch && matches(c.message)) ||
        (server.infoEpoch == reportedEpoch &&
            server.info != null &&
            matches(server.info!));
    if (!reported) throw _refusal('report_mismatch');
    server
      ..resets += 1
      ..generation += 1
      ..epoch = null
      ..info = null
      ..infoEpoch = 0
      ..reservedFor = name
      ..log.clear();
    return (generation: server.generation, reset: true);
  }

  @override
  Future<List<PendingWelcome>> welcomes(String token) async => const [];

  @override
  Future<List<DeviceRef>> roster(String token, String channelId) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A device's groups, by generation: each at an epoch. A broken commit is
/// refused and leaves the group as it was, as the core does with a commit it
/// cannot decrypt.
class _Engine implements CryptoEngine {
  /// Generation → epoch, for every group this device holds.
  final held = <int, int>{};
  final pending = <int, Uint8List>{};
  final resets = <int>[];
  final deletes = <int>[];
  int created = 0;
  int externalJoins = 0;

  int _generationOf(Uint8List groupId) {
    for (var g = 0; g < 16; g++) {
      if (listEquals(groupId, _group(g))) return g;
    }
    throw StateError('not this channel: $groupId');
  }

  @override
  Future<bool> hasGroup(Uint8List groupId) async =>
      held.containsKey(_generationOf(groupId));

  @override
  Future<int> epoch(Uint8List groupId) async {
    final epoch = held[_generationOf(groupId)];
    if (epoch == null) {
      throw const CryptoException(CryptoErrorKind.notFound, 'group');
    }
    return epoch;
  }

  @override
  Future<GroupEvent> process(Uint8List message) async {
    final generation = message[1];
    final epoch = held[generation];
    if (epoch == null) {
      throw const CryptoException(CryptoErrorKind.notFound, 'group');
    }
    if (message[3] == _broken) {
      throw const CryptoException(CryptoErrorKind.other, 'mls error: decrypt');
    }
    if (listEquals(pending[generation], message)) pending.remove(generation);
    held[generation] = epoch + 1;
    return GroupMembershipChanged(
      _group(generation),
      epoch + 1,
      added: const [],
      removed: const [],
      removedSelf: false,
    );
  }

  @override
  Future<void> createGroup(Uint8List groupId) async {
    created++;
    held[_generationOf(groupId)] = 0;
  }

  @override
  Future<Uint8List> groupInfo(Uint8List groupId) async {
    final generation = _generationOf(groupId);
    return _info(generation, held[generation]!);
  }

  @override
  Future<({Uint8List groupId, GroupCommit commit})> joinByExternalCommit(
    Uint8List expectedGroupId,
    Uint8List groupInfo,
  ) async {
    final generation = _generationOf(expectedGroupId);
    if (groupInfo[1] != generation) {
      throw const CryptoException(
        CryptoErrorKind.verification,
        'another group',
      );
    }
    externalJoins++;
    final epoch = groupInfo[2];
    // The core merges an external join as it builds it.
    held[generation] = epoch + 1;
    return (
      groupId: expectedGroupId,
      commit: GroupCommit(
        commit: _commit(generation, epoch, 0x01),
        welcome: null,
        epochAfter: epoch + 1,
      ),
    );
  }

  @override
  Future<int> mergePendingCommit(Uint8List groupId) async {
    final generation = _generationOf(groupId);
    if (pending.remove(generation) != null) {
      held[generation] = held[generation]! + 1;
    }
    return held[generation]!;
  }

  @override
  Future<void> discardPendingCommit(Uint8List groupId) async =>
      pending.remove(_generationOf(groupId));

  @override
  Future<GroupCommit> selfUpdate(Uint8List groupId) async {
    final generation = _generationOf(groupId);
    final epoch = held[generation]!;
    final commit = _commit(generation, epoch, 0x02);
    pending[generation] = commit;
    return GroupCommit(commit: commit, welcome: null, epochAfter: epoch + 1);
  }

  @override
  Future<List<GroupMemberInfo>> members(Uint8List groupId) async => const [];

  @override
  Future<void> resetGroup(Uint8List groupId) async {
    final generation = _generationOf(groupId);
    if (held.remove(generation) != null) resets.add(generation);
    pending.remove(generation);
  }

  @override
  Future<void> deleteGroup(Uint8List groupId) async {
    final generation = _generationOf(groupId);
    held.remove(generation);
    deletes.add(generation);
  }

  @override
  Future<Uint8List> encrypt(Uint8List groupId, Uint8List payload) async {
    final generation = _generationOf(groupId);
    if (!held.containsKey(generation)) {
      throw const CryptoException(CryptoErrorKind.notFound, 'group');
    }
    return _message(generation, payload);
  }

  /// Reads a message of any group this device holds — a fake has no epochs'
  /// keys to lose.
  @override
  Future<DecryptedMessage?> receiveMessage({
    required String messageId,
    required DateTime sentAt,
    required Uint8List message,
  }) async {
    final id = message.sublist(5, 5 + message[4]);
    final generation = _generationOf(id);
    if (!held.containsKey(generation)) {
      throw const CryptoException(CryptoErrorKind.other, 'not a member');
    }
    return DecryptedMessage(
      groupId: id,
      messageId: messageId,
      senderUserId: 'alice',
      senderDeviceId: 'alice-1',
      epoch: 0,
      sentAt: sentAt,
      payload: message.sublist(5 + message[4] + 9),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

ChannelGroups _device(
  String name,
  _Engine engine,
  _Server server, {
  bool generations = true,
}) => ChannelGroups(
  engine: engine,
  api: _Api(server, name),
  token: name,
  self: DeviceRef(userId: name, deviceId: '$name-1'),
  generations: generations,
);

/// A group in generation 0 at epoch 5 that [engines] are all in, whose next
/// commit — already in the log — nobody can process, and whose group info is
/// still the one for epoch 5, since nobody could publish another.
_Server _brokenServer(List<_Engine> engines) {
  final server = _Server()..create(0, 5);
  for (final engine in engines) {
    engine.held[0] = 5;
  }
  server.breakGroup();
  return server;
}

void main() {
  test('a commit nobody can process: one rejoin, then a report, and this '
      'device starts the next generation, keeping its history', () async {
    final alice = _Engine();
    final server = _brokenServer([alice]);

    await _device('alice', alice, server).catchUp(_channel);

    // It tried to rejoin from the group info first, which could only lose.
    expect(alice.externalJoins, greaterThanOrEqualTo(1));
    // Then reported the very commit it could not process.
    expect(server.resetCalls, [(token: 'alice', generation: 0, epoch: 5)]);
    expect(server.resets, 1);
    expect(server.generation, 1);
    // And created generation 1, the old one dropped — reset, not deleted, so
    // the cached messages are still there.
    expect(alice.created, 1);
    expect(alice.held, {1: 0});
    expect(alice.resets, contains(0));
    expect(alice.deletes, isEmpty);
    expect(server.epoch, 0);
  });

  test(
    'two members who find the same broken commit end in one generation',
    () async {
      final alice = _Engine();
      final bob = _Engine();
      final server = _brokenServer([alice, bob]);
      final aliceGroups = _device('alice', alice, server);
      final bobGroups = _device('bob', bob, server);

      await Future.wait([
        aliceGroups.catchUp(_channel),
        bobGroups.catchUp(_channel),
      ]);
      // Whichever ended first may need to follow the other's join.
      await aliceGroups.ensureJoined(_channel);
      await bobGroups.ensureJoined(_channel);

      // Both reported generation 0; only one reset happened.
      expect(server.resetCalls.map((c) => c.generation), [0, 0]);
      expect(server.resets, 1);
      expect(server.generation, 1);
      expect(alice.created + bob.created, 1);
      expect(alice.held.keys, [1]);
      expect(bob.held.keys, [1]);
      expect(alice.held[1], server.epoch);
      expect(bob.held[1], server.epoch);
    },
  );

  test('a device that only hears of a newer generation drops the old one and '
      'joins it, without reporting anything', () async {
    final alice = _Engine();
    final bob = _Engine();
    final server = _brokenServer([alice, bob]);
    await _device('alice', alice, server).catchUp(_channel);

    final bobGroups = _device('bob', bob, server);
    await bobGroups.ensureJoined(_channel);

    expect(server.resets, 1);
    expect(server.resetCalls.where((c) => c.token == 'bob'), isEmpty);
    expect(bob.held, {1: 1});
    expect(bob.resets, [0]);
    expect(bob.deletes, isEmpty);
  });

  test('a reset event moves a device on, and never back', () async {
    final bob = _Engine()..held[1] = 3;
    final server = _Server()..create(1, 3);
    final bobGroups = _device('bob', bob, server);
    await bobGroups.ensureJoined(_channel);
    expect(bob.held, {1: 3});

    ServerEvent reset(int generation) => ServerEvent(
      pb.ServerEvent(
        groupReset: pb.GroupResetEvent(
          channelId: _channel,
          generation: Int64(generation),
        ),
      ),
    );

    bobGroups.onEvent(reset(0));
    await pumpEventQueue();
    expect(bob.held, {1: 3});

    bobGroups.onEvent(reset(2));
    await pumpEventQueue();
    expect(bob.held, isEmpty);
    expect(bob.resets, [1]);
  });

  test('an attacker who breaks every generation cannot keep a device '
      'resetting: the server\'s refusal ends it', () async {
    final alice = _Engine();
    final server = _brokenServer([alice])
      ..breakEveryGeneration = true
      ..refuseLaterResets = 'rate_limited';
    final groups = _device('alice', alice, server);

    // The first break is recovered from; the new generation is broken at
    // once, and that report is refused.
    await groups.catchUp(_channel);
    await expectLater(
      groups.catchUp(_channel),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'rate_limited'),
      ),
    );
    expect(server.resets, 1);
    expect(server.resetCalls, hasLength(2));
    // Its copy of the broken generation is gone; the next use tries again.
    expect(alice.held, isEmpty);
  });

  test('a group info nobody can join from is reported, and the device creates '
      'the next generation', () async {
    final alice = _Engine();
    final server = _Server()..create(0, 4);
    // The published group info names another generation's group: the core
    // refuses to join from it.
    server.info = _info(7, 4);

    await _device('alice', alice, server).ensureJoined(_channel);

    expect(server.resetCalls, [(token: 'alice', generation: 0, epoch: 4)]);
    expect(server.generation, 1);
    expect(alice.held, {1: 0});
  });

  test('without generations on the server a broken commit is an error, as '
      'it was', () async {
    final alice = _Engine();
    final server = _brokenServer([alice]);

    await expectLater(
      _device('alice', alice, server, generations: false).catchUp(_channel),
      throwsA(
        isA<CryptoException>().having(
          (e) => e.kind,
          'kind',
          CryptoErrorKind.other,
        ),
      ),
    );
    expect(server.resetCalls, isEmpty);
    expect(alice.held, {0: 5});
  });

  test('a message is encrypted in the channel\'s current generation', () async {
    final alice = _Engine()..held[1] = 0;
    final server = _Server()..create(1, 0);
    final groups = _device('alice', alice, server);

    final ciphertext = await groups.encrypt(
      _channel,
      Uint8List.fromList([1, 2]),
    );
    expect(ciphertext, _message(1, [1, 2]));
  });

  test('a message from a generation this device missed makes it follow the '
      'channel there and join before reading it', () async {
    final bob = _Engine()..held[0] = 2;
    final server = _Server()..create(0, 2);
    final groups = _device('bob', bob, server);
    await groups.ensureJoined(_channel);

    // Alice reset the group and wrote in its new generation; bob heard nothing.
    server
      ..generation = 1
      ..create(1, 0);
    final read = await groups.decryptOrHeld(
      channelId: _channel,
      messageId: 'm1',
      sentAt: DateTime.utc(2026),
      ciphertext: _message(1, [7, 7]),
      epoch: 0,
      senderDeviceId: 'alice-1',
    );

    expect(read.payload, [7, 7]);
    expect(bob.held.keys, [1]);
    expect(bob.resets, [0]);

    // A message naming a generation the server does not have moves nothing.
    final bogus = await groups.decryptOrHeld(
      channelId: _channel,
      messageId: 'm2',
      sentAt: DateTime.utc(2026),
      ciphertext: _message(5, [1]),
      epoch: 0,
      senderDeviceId: 'alice-1',
    );
    expect(bogus.payload, isNull);
    expect(bob.held.keys, [1]);
  });
}
