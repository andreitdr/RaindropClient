/// The app's view of `raindrop.v1.DeviceService` and `DeliveryService`
/// (RaindropProto's `devices.proto` and `delivery.proto`): the server side of
/// end-to-end encryption. Everything here is public keys and opaque blobs —
/// protobuf `bytes` — and the private keys never leave `core/crypto/`.
library;

import 'dart:typed_data';

import 'grpc/protocol.dart' as pb;
import 'grpc/wire.dart';
import 'raindrop_channel.dart';

/// The names of the events this surface publishes, as `ServerEvent.type`
/// reports them.
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

/// The server's `capabilities` entry for camera video in calls: a member with
/// the `video` permission may turn their camera on, within the server's cap on
/// how many cameras one call carries at once.
///
/// Encryption is the same key and the same guarantee as
/// [e2eeVoiceCapability] — one key per call, covering voice and camera alike.
/// A server without this carries voice only, and the camera button is hidden
/// rather than offered and refused.
const voiceVideoCapability = 'voice.video.v1';

/// The server's `capabilities` entry for screen sharing in calls: a member
/// with the `screen_share` permission may share a screen or a window — and a
/// window's own sound — within the server's cap on how many shares one call
/// carries at once. The same key again. A server without this shows no share
/// button and no shares to watch.
const voiceScreenCapability = 'voice.screen.v1';

/// One device, by owner and id.
class DeviceRef {
  const DeviceRef({required this.userId, required this.deviceId});

  final String userId;
  final String deviceId;

  pb.DeviceRef toProto() => pb.DeviceRef(userId: userId, deviceId: deviceId);

  factory DeviceRef.fromProto(pb.DeviceRef m) =>
      DeviceRef(userId: m.userId, deviceId: m.deviceId);

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

  factory GroupState.fromProto(pb.GroupState m) => GroupState(
    epoch: m.epoch.toInt(),
    groupInfo: Wire.optionalBytes(m.hasGroupInfo(), m.groupInfo),
    groupInfoEpoch: m.groupInfoEpoch.toInt(),
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

  factory DeviceSummary.fromProto(pb.Device m) => DeviceSummary(
    deviceId: m.deviceId,
    certificate: Wire.bytes(m.certificate),
    createdAtUtc: Wire.time(m.createdAt),
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

  factory UserDevices.fromProto(pb.UserDevices m) => UserDevices(
    userId: m.userId,
    identityKey: Wire.optionalBytes(m.hasIdentityKey(), m.identityKey),
    devices: [for (final d in m.devices) DeviceSummary.fromProto(d)],
  );
}

/// `raindrop.v1.DeviceService` and `DeliveryService`. One instance per
/// connected server.
class E2eeApi {
  E2eeApi(this._channel)
    : _devices = pb.DeviceServiceClient(_channel.channel),
      _delivery = pb.DeliveryServiceClient(_channel.channel);

  final RaindropChannel _channel;
  final pb.DeviceServiceClient _devices;
  final pb.DeliveryServiceClient _delivery;

  // ── Devices ──

  /// Registers this device. The first device of a user establishes their
  /// identity key; a certificate signed by any other key is refused with
  /// `identity_mismatch`. Registering the same certificate again is a no-op.
  Future<DeviceSummary> registerDevice(
    String token,
    Uint8List certificate,
  ) async => DeviceSummary.fromProto(
    (await _channel.call(
      (o) => _devices.registerDevice(
        pb.RegisterDeviceRequest(certificate: certificate),
        options: o,
      ),
      token: token,
    )).device,
  );

  Future<List<UserDevices>> listDevices(
    String token,
    List<String> userIds,
  ) async {
    final response = await _channel.call(
      (o) => _devices.listDevices(
        pb.ListDevicesRequest(userIds: userIds),
        options: o,
      ),
      token: token,
    );
    return [for (final u in response.users) UserDevices.fromProto(u)];
  }

  /// Revokes one of this user's devices. Needs a bound session unless it is
  /// this session's own device.
  Future<void> revokeDevice(String token, String deviceId) => _channel.call(
    (o) => _devices.revokeDevice(
      pb.RevokeDeviceRequest(deviceId: deviceId),
      options: o,
    ),
    token: token,
  );

  /// Forgets this user's identity key and backup and revokes every device.
  Future<void> resetIdentity(String token, String password) => _channel.call(
    (o) => _devices.resetIdentity(
      pb.ResetIdentityRequest(password: password),
      options: o,
    ),
    token: token,
  );

  // ── Session binding ──

  Future<Uint8List> sessionChallenge(String token) async => Wire.bytes(
    (await _channel.call(
      (o) => _devices.createSessionChallenge(
        pb.CreateSessionChallengeRequest(),
        options: o,
      ),
      token: token,
    )).nonce,
  );

  Future<void> bindSession(
    String token, {
    required String deviceId,
    required Uint8List signature,
  }) => _channel.call(
    (o) => _devices.bindSession(
      pb.BindSessionRequest(deviceId: deviceId, signature: signature),
      options: o,
    ),
    token: token,
  );

  // ── Key backup ──

  /// The sealed backup, or null when the user has none.
  Future<Uint8List?> getBackup(String token) async {
    final response = await _channel.call(
      (o) => _devices.getKeyBackup(pb.GetKeyBackupRequest(), options: o),
      token: token,
    );
    return Wire.optionalBytes(response.hasBlob(), response.blob);
  }

  /// Replaces the sealed backup. Needs a bound session.
  Future<void> putBackup(String token, Uint8List blob) => _channel.call(
    (o) =>
        _devices.putKeyBackup(pb.PutKeyBackupRequest(blob: blob), options: o),
    token: token,
  );

  // ── Groups (the MLS delivery service) ──

  Future<GroupState> createGroup(
    String token,
    String channelId,
    Uint8List groupInfo,
  ) async => GroupState.fromProto(
    (await _channel.call(
      (o) => _delivery.createGroup(
        pb.CreateGroupRequest(channelId: channelId, groupInfo: groupInfo),
        options: o,
      ),
      token: token,
    )).state,
  );

  /// Throws `group_not_found` while the channel has no group yet.
  Future<GroupState> groupState(String token, String channelId) async =>
      GroupState.fromProto(
        (await _channel.call(
          (o) => _delivery.getGroupState(
            pb.GetGroupStateRequest(channelId: channelId),
            options: o,
          ),
          token: token,
        )).state,
      );

  /// Submits a commit made in the group's current epoch. Returns the new
  /// epoch; throws `epoch_conflict` when another commit won.
  Future<int> submitCommit(
    String token,
    String channelId,
    Uint8List commit, {
    Uint8List? welcome,
    List<DeviceRef> welcomeRecipients = const [],
  }) async => (await _channel.call(
    (o) => _delivery.submitCommit(
      pb.SubmitCommitRequest(
        channelId: channelId,
        commit: commit,
        welcome: welcome,
        welcomeRecipients: [for (final r in welcomeRecipients) r.toProto()],
      ),
      options: o,
    ),
    token: token,
  )).epoch.toInt();

  Future<GroupState> putGroupInfo(
    String token,
    String channelId,
    Uint8List groupInfo,
  ) async => GroupState.fromProto(
    (await _channel.call(
      (o) => _delivery.putGroupInfo(
        pb.PutGroupInfoRequest(channelId: channelId, groupInfo: groupInfo),
        options: o,
      ),
      token: token,
    )).state,
  );

  Future<GroupSync> syncGroup(
    String token,
    String channelId,
    int fromEpoch,
  ) async {
    final response = await _channel.call(
      (o) => _delivery.syncGroup(
        pb.SyncGroupRequest(
          channelId: channelId,
          fromEpoch: Wire.int64(fromEpoch),
        ),
        options: o,
      ),
      token: token,
    );
    return GroupSync(
      epoch: response.epoch.toInt(),
      commits: [
        for (final c in response.commits)
          (epoch: c.epoch.toInt(), message: Wire.bytes(c.message)),
      ],
      resyncRequired: response.resyncRequired,
    );
  }

  /// Every device that should be in the channel's group right now.
  Future<List<DeviceRef>> roster(String token, String channelId) async {
    final response = await _channel.call(
      (o) => _delivery.getGroupRoster(
        pb.GetGroupRosterRequest(channelId: channelId),
        options: o,
      ),
      token: token,
    );
    return [for (final d in response.devices) DeviceRef.fromProto(d)];
  }

  // ── Key packages ──

  /// Stores key packages for this session's device; returns how many
  /// one-time packages it now has.
  Future<int> uploadKeyPackages(
    String token,
    List<Uint8List> keyPackages, {
    Uint8List? lastResort,
  }) async => (await _channel.call(
    (o) => _delivery.uploadKeyPackages(
      pb.UploadKeyPackagesRequest(
        keyPackages: keyPackages,
        lastResort: lastResort,
      ),
      options: o,
    ),
    token: token,
  )).oneTime;

  Future<int> keyPackageCount(String token) async => (await _channel.call(
    (o) => _delivery.getKeyPackageCount(
      pb.GetKeyPackageCountRequest(),
      options: o,
    ),
    token: token,
  )).oneTime;

  /// One key package per device that has one, for adding them to the
  /// channel's group.
  Future<Map<DeviceRef, Uint8List>> claimKeyPackages(
    String token,
    String channelId,
    List<DeviceRef> devices,
  ) async {
    final response = await _channel.call(
      (o) => _delivery.claimKeyPackages(
        pb.ClaimKeyPackagesRequest(
          channelId: channelId,
          devices: [for (final d in devices) d.toProto()],
        ),
        options: o,
      ),
      token: token,
    );
    return {
      for (final k in response.keyPackages)
        DeviceRef(userId: k.userId, deviceId: k.deviceId): Wire.bytes(
          k.keyPackage,
        ),
    };
  }

  // ── Welcomes ──

  Future<List<PendingWelcome>> welcomes(String token) async {
    final response = await _channel.call(
      (o) => _delivery.listWelcomes(pb.ListWelcomesRequest(), options: o),
      token: token,
    );
    return [
      for (final w in response.welcomes)
        PendingWelcome(
          welcomeId: w.welcomeId,
          channelId: w.channelId,
          epoch: w.epoch.toInt(),
          welcome: Wire.bytes(w.welcome),
        ),
    ];
  }

  Future<void> ackWelcomes(String token, List<String> welcomeIds) =>
      _channel.call(
        (o) => _delivery.ackWelcomes(
          pb.AckWelcomesRequest(welcomeIds: welcomeIds),
          options: o,
        ),
        token: token,
      );

  // ── Device linking ──

  /// New device: opens a link. Returns the link id for the link code.
  Future<String> startLink(String token, Uint8List offer) async =>
      (await _channel.call(
        (o) => _devices.startDeviceLink(
          pb.StartDeviceLinkRequest(offer: offer),
          options: o,
        ),
        token: token,
      )).linkId;

  /// Existing device: the new device's offer, to check against the code.
  Future<Uint8List> linkOffer(String token, String linkId) async => Wire.bytes(
    (await _channel.call(
      (o) => _devices.getDeviceLinkOffer(
        pb.GetDeviceLinkOfferRequest(linkId: linkId),
        options: o,
      ),
      token: token,
    )).offer,
  );

  Future<void> approveLink(String token, String linkId, Uint8List approval) =>
      _channel.call(
        (o) => _devices.approveDeviceLink(
          pb.ApproveDeviceLinkRequest(linkId: linkId, approval: approval),
          options: o,
        ),
        token: token,
      );

  /// New device: the approval once an existing device has given it, else
  /// null. Delivered once.
  Future<Uint8List?> takeLinkApproval(String token, String linkId) async {
    final response = await _channel.call(
      (o) => _devices.takeDeviceLinkApproval(
        pb.TakeDeviceLinkApprovalRequest(linkId: linkId),
        options: o,
      ),
      token: token,
    );
    return Wire.optionalBytes(response.hasApproval(), response.approval);
  }
}
