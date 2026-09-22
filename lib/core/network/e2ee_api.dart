/// Dart mirror of the C# records in `RaindropServer/E2ee/Contracts.cs`: the
/// server side of end-to-end encryption identities. Everything here is public
/// keys and opaque blobs; the private keys never leave `core/crypto/`.
///
/// Byte fields travel as base64 in JSON.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'api_client.dart';

/// Wire names of the events this surface publishes.
abstract final class E2eeEventTypes {
  static const deviceAdded = 'e2ee.device.added';
  static const deviceRevoked = 'e2ee.device.revoked';
  static const identityReset = 'e2ee.identity.reset';

  /// A commit was accepted: `{channelId, epoch, message}`.
  static const handshake = 'e2ee.handshake';

  /// A Welcome waits for one of this user's devices: `{channelId, deviceId}`.
  static const welcome = 'e2ee.welcome';

  /// Who belongs in a group may have changed: `{channelId}`. Compare the
  /// tree with [E2eeApi.roster] and commit the difference.
  static const groupReconcile = 'e2ee.group.reconcile';

  /// A device is running low on key packages: `{deviceId, remaining}`.
  static const keyPackagesLow = 'e2ee.keypackages.low';
}

/// The server's `capabilities` entry for identities and devices.
const e2eeDevicesCapability = 'e2ee.devices.v1';

/// The server's `capabilities` entry for the MLS delivery service.
const e2eeDeliveryCapability = 'e2ee.delivery.v1';

/// The server's `capabilities` entry for end-to-end encrypted calls: every
/// client in a call on this server is expected to encrypt its media with a
/// key from the voice channel's group, so a client refuses to join a call it
/// cannot encrypt.
const e2eeVoiceCapability = 'e2ee.voice.v1';

/// One device, by owner and id.
class DeviceRef {
  const DeviceRef({required this.userId, required this.deviceId});

  final String userId;
  final String deviceId;

  Map<String, dynamic> toJson() => {'userId': userId, 'deviceId': deviceId};

  factory DeviceRef.fromJson(Map<String, dynamic> j) => DeviceRef(
    userId: j['userId'] as String,
    deviceId: j['deviceId'] as String,
  );

  @override
  bool operator ==(Object other) =>
      other is DeviceRef &&
      other.userId == userId &&
      other.deviceId == deviceId;

  @override
  int get hashCode => Object.hash(userId, deviceId);
}

/// A channel group as the delivery service tracks it.
class GroupState {
  const GroupState({
    required this.epoch,
    required this.groupInfo,
    required this.groupInfoEpoch,
  });

  /// The epoch the next commit must be made in.
  final int epoch;

  /// The latest published group info, for joining by external commit.
  final Uint8List? groupInfo;
  final int groupInfoEpoch;

  factory GroupState.fromJson(Map<String, dynamic> j) => GroupState(
    epoch: (j['epoch'] as num).toInt(),
    groupInfo: _bytes(j['groupInfo']),
    groupInfoEpoch: (j['groupInfoEpoch'] as num).toInt(),
  );
}

/// What a device needs to catch up on a group.
class GroupSync {
  const GroupSync({
    required this.epoch,
    required this.commits,
    required this.resyncRequired,
  });

  final int epoch;

  /// Oldest first; each made in its `epoch`.
  final List<({int epoch, Uint8List message})> commits;

  /// Commits this device needs were pruned: rejoin by external commit.
  final bool resyncRequired;
}

class PendingWelcome {
  const PendingWelcome({
    required this.welcomeId,
    required this.channelId,
    required this.epoch,
    required this.welcome,
  });

  final String welcomeId;
  final String channelId;
  final int epoch;
  final Uint8List welcome;
}

class DeviceSummary {
  const DeviceSummary({
    required this.deviceId,
    required this.certificate,
    required this.createdAtUtc,
  });

  final String deviceId;

  /// Exactly as uploaded. The server's word is not trusted: check it with the
  /// crypto engine before believing it.
  final Uint8List certificate;
  final DateTime createdAtUtc;

  factory DeviceSummary.fromJson(Map<String, dynamic> j) => DeviceSummary(
    deviceId: j['deviceId'] as String,
    certificate: base64.decode(j['certificate'] as String),
    createdAtUtc: DateTime.parse(j['createdAtUtc'] as String).toUtc(),
  );
}

class UserDevices {
  const UserDevices({
    required this.userId,
    required this.identityKey,
    required this.devices,
  });

  final String userId;

  /// Null before the user's first device is registered.
  final Uint8List? identityKey;
  final List<DeviceSummary> devices;

  factory UserDevices.fromJson(Map<String, dynamic> j) => UserDevices(
    userId: j['userId'] as String,
    identityKey: _bytes(j['identityKey']),
    devices: [
      for (final d in j['devices'] as List? ?? const [])
        DeviceSummary.fromJson(Map<String, dynamic>.from(d as Map)),
    ],
  );
}

/// Typed wrapper over `/api/e2ee/*`. One instance per connected server.
class E2eeApi {
  E2eeApi(this._client);

  final ApiClient _client;

  // ── Devices ──

  /// Registers this device. The first device of a user establishes their
  /// identity key; a certificate signed by any other key is refused with
  /// `identity_mismatch`. Registering the same certificate again is a no-op.
  Future<DeviceSummary> registerDevice(
    String token,
    Uint8List certificate,
  ) async => DeviceSummary.fromJson(
    await _client.post(
      '/api/e2ee/devices/register',
      body: {'certificate': base64.encode(certificate)},
      token: token,
    ),
  );

  Future<List<UserDevices>> listDevices(
    String token,
    List<String> userIds,
  ) async {
    final body = await _client.post(
      '/api/e2ee/devices/list',
      body: {'userIds': userIds},
      token: token,
    );
    return [
      for (final u in body['users'] as List? ?? const [])
        UserDevices.fromJson(Map<String, dynamic>.from(u as Map)),
    ];
  }

  /// Revokes one of this user's devices. Needs a bound session unless it is
  /// this session's own device.
  Future<void> revokeDevice(String token, String deviceId) => _client.post(
    '/api/e2ee/devices/revoke',
    body: {'deviceId': deviceId},
    token: token,
  );

  /// Forgets this user's identity key and backup and revokes every device.
  Future<void> resetIdentity(String token, String password) => _client.post(
    '/api/e2ee/identity/reset',
    body: {'password': password},
    token: token,
  );

  // ── Session binding ──

  Future<Uint8List> sessionChallenge(String token) async {
    final body = await _client.post(
      '/api/e2ee/session/challenge',
      token: token,
    );
    return base64.decode(body['nonce'] as String);
  }

  Future<void> bindSession(
    String token, {
    required String deviceId,
    required Uint8List signature,
  }) => _client.post(
    '/api/e2ee/session/bind',
    body: {'deviceId': deviceId, 'signature': base64.encode(signature)},
    token: token,
  );

  // ── Key backup ──

  /// The sealed backup, or null when the user has none.
  Future<Uint8List?> getBackup(String token) async =>
      _bytes((await _client.get('/api/e2ee/backup', token: token))['blob']);

  /// Replaces the sealed backup. Needs a bound session.
  Future<void> putBackup(String token, Uint8List blob) => _client.post(
    '/api/e2ee/backup/put',
    body: {'blob': base64.encode(blob)},
    token: token,
  );

  // ── Groups (the MLS delivery service) ──

  Future<GroupState> createGroup(
    String token,
    String channelId,
    Uint8List groupInfo,
  ) async => GroupState.fromJson(
    await _client.post(
      '/api/e2ee/groups/create',
      body: {'channelId': channelId, 'groupInfo': base64.encode(groupInfo)},
      token: token,
    ),
  );

  /// Throws `group_not_found` while the channel has no group yet.
  Future<GroupState> groupState(String token, String channelId) async =>
      GroupState.fromJson(
        await _client.post(
          '/api/e2ee/groups/state',
          body: {'channelId': channelId},
          token: token,
        ),
      );

  /// Submits a commit made in the group's current epoch. Returns the new
  /// epoch; throws `epoch_conflict` when another commit won.
  Future<int> submitCommit(
    String token,
    String channelId,
    Uint8List commit, {
    Uint8List? welcome,
    List<DeviceRef> welcomeRecipients = const [],
  }) async {
    final body = await _client.post(
      '/api/e2ee/groups/commit',
      body: {
        'channelId': channelId,
        'commit': base64.encode(commit),
        'welcome': ?(welcome == null ? null : base64.encode(welcome)),
        'welcomeRecipients': [for (final r in welcomeRecipients) r.toJson()],
      },
      token: token,
    );
    return (body['epoch'] as num).toInt();
  }

  Future<GroupState> putGroupInfo(
    String token,
    String channelId,
    Uint8List groupInfo,
  ) async => GroupState.fromJson(
    await _client.post(
      '/api/e2ee/groups/info',
      body: {'channelId': channelId, 'groupInfo': base64.encode(groupInfo)},
      token: token,
    ),
  );

  Future<GroupSync> syncGroup(
    String token,
    String channelId,
    int fromEpoch,
  ) async {
    final body = await _client.post(
      '/api/e2ee/groups/sync',
      body: {'channelId': channelId, 'fromEpoch': fromEpoch},
      token: token,
    );
    return GroupSync(
      epoch: (body['epoch'] as num).toInt(),
      commits: [
        for (final c in body['commits'] as List? ?? const [])
          (
            epoch: ((c as Map)['epoch'] as num).toInt(),
            message: base64.decode(c['message'] as String),
          ),
      ],
      resyncRequired: body['resyncRequired'] as bool? ?? false,
    );
  }

  /// Every device that should be in the channel's group right now.
  Future<List<DeviceRef>> roster(String token, String channelId) async {
    final body = await _client.post(
      '/api/e2ee/groups/roster',
      body: {'channelId': channelId},
      token: token,
    );
    return [
      for (final d in body['devices'] as List? ?? const [])
        DeviceRef.fromJson(Map<String, dynamic>.from(d as Map)),
    ];
  }

  // ── Key packages ──

  /// Stores key packages for this session's device; returns how many
  /// one-time packages it now has.
  Future<int> uploadKeyPackages(
    String token,
    List<Uint8List> keyPackages, {
    Uint8List? lastResort,
  }) async {
    final body = await _client.post(
      '/api/e2ee/keypackages/upload',
      body: {
        'keyPackages': [for (final k in keyPackages) base64.encode(k)],
        'lastResort': ?(lastResort == null ? null : base64.encode(lastResort)),
      },
      token: token,
    );
    return (body['oneTime'] as num).toInt();
  }

  Future<int> keyPackageCount(String token) async =>
      ((await _client.get(
                '/api/e2ee/keypackages/count',
                token: token,
              ))['oneTime']
              as num)
          .toInt();

  /// One key package per device that has one, for adding them to the
  /// channel's group.
  Future<Map<DeviceRef, Uint8List>> claimKeyPackages(
    String token,
    String channelId,
    List<DeviceRef> devices,
  ) async {
    final body = await _client.post(
      '/api/e2ee/keypackages/claim',
      body: {
        'channelId': channelId,
        'devices': [for (final d in devices) d.toJson()],
      },
      token: token,
    );
    return {
      for (final k in body['keyPackages'] as List? ?? const [])
        DeviceRef(
          userId: (k as Map)['userId'] as String,
          deviceId: k['deviceId'] as String,
        ): base64.decode(
          k['keyPackage'] as String,
        ),
    };
  }

  // ── Welcomes ──

  Future<List<PendingWelcome>> welcomes(String token) async {
    final body = await _client.get('/api/e2ee/welcomes', token: token);
    return [
      for (final w in body['welcomes'] as List? ?? const [])
        PendingWelcome(
          welcomeId: (w as Map)['welcomeId'] as String,
          channelId: w['channelId'] as String,
          epoch: (w['epoch'] as num).toInt(),
          welcome: base64.decode(w['welcome'] as String),
        ),
    ];
  }

  Future<void> ackWelcomes(String token, List<String> welcomeIds) =>
      _client.post(
        '/api/e2ee/welcomes/ack',
        body: {'welcomeIds': welcomeIds},
        token: token,
      );

  // ── Device linking ──

  /// New device: opens a link. Returns the link id for the link code.
  Future<String> startLink(String token, Uint8List offer) async {
    final body = await _client.post(
      '/api/e2ee/device-link/start',
      body: {'offer': base64.encode(offer)},
      token: token,
    );
    return body['linkId'] as String;
  }

  /// Existing device: the new device's offer, to check against the code.
  Future<Uint8List> linkOffer(String token, String linkId) async =>
      base64.decode(
        (await _client.post(
              '/api/e2ee/device-link/offer',
              body: {'linkId': linkId},
              token: token,
            ))['offer']
            as String,
      );

  Future<void> approveLink(String token, String linkId, Uint8List approval) =>
      _client.post(
        '/api/e2ee/device-link/approve',
        body: {'linkId': linkId, 'approval': base64.encode(approval)},
        token: token,
      );

  /// New device: the approval once an existing device has given it, else
  /// null. Delivered once.
  Future<Uint8List?> takeLinkApproval(String token, String linkId) async =>
      _bytes(
        (await _client.post(
          '/api/e2ee/device-link/approval',
          body: {'linkId': linkId},
          token: token,
        ))['approval'],
      );
}

Uint8List? _bytes(Object? value) =>
    value is String ? base64.decode(value) : null;
