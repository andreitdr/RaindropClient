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

  /// A channel's group started a new generation: `{channelId, generation}`.
  /// Leave the old one and join this one.
  static const groupReset = 'e2ee.group.reset';
}

/// The server's `capabilities` entry for identities and devices.
const e2eeDevicesCapability = 'e2ee.devices.v1';

/// The server's `capabilities` entry for the MLS delivery service.
const e2eeDeliveryCapability = 'e2ee.delivery.v1';

/// The server's `capabilities` entry for group generations: a channel's group
/// that can no longer be followed is reset to a new one
/// ([E2eeApi.resetGroup]), and every commit is attributed to the device that
/// submitted it. Without it every group stays in generation 0.
const e2eeGroupResetCapability = 'e2ee.group-reset.v1';

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
    this.generation = 0,
  });

  /// The epoch the next commit must be made in.
  final int epoch;

  /// The latest published group info, for joining by external commit.
  final Uint8List? groupInfo;
  final int groupInfoEpoch;

  /// The group's generation, which its MLS group id names
  /// (`groupIdForChannel`).
  final int generation;

  factory GroupState.fromProto(pb.GroupState m) => GroupState(
    epoch: m.epoch.toInt(),
    groupInfo: Wire.optionalBytes(m.hasGroupInfo(), m.groupInfo),
    groupInfoEpoch: m.groupInfoEpoch.toInt(),
    generation: m.generation.toInt(),
  );
}

/// What a device needs to catch up on a group.
class GroupSync {
  const GroupSync({
    required this.epoch,
    required this.commits,
    required this.resyncRequired,
    this.generation = 0,
  });

  final int epoch;

  /// Oldest first; each made in its `epoch`.
  final List<({int epoch, Uint8List message})> commits;

  /// Commits this device needs were pruned, or its group is of another
  /// generation than [generation]: rejoin.
  final bool resyncRequired;

  /// The group's current generation.
  final int generation;
}

/// One reset of a channel's group to a new generation, with who asked and
/// whose commit they reported. Channel managers read these.
class GroupReset {
  const GroupReset({
    required this.generation,
    required this.resetAt,
    required this.requestedByUserId,
    required this.requestedByDeviceId,
    required this.reportedKind,
    required this.reportedEpoch,
    required this.reportedSenderUserId,
    required this.reportedSenderDeviceId,
  });

  final int generation;
  final DateTime resetAt;
  final String requestedByUserId;
  final String requestedByDeviceId;

  /// `commit`, `group_info`, or null for a manager's reset without a report.
  /// An open set.
  final String? reportedKind;
  final int reportedEpoch;

  /// For a reported commit: who submitted it, as the server recorded it.
  final String? reportedSenderUserId;
  final String? reportedSenderDeviceId;
}

/// A device ([deviceId]), or every device of an account (null), kept out of
/// a channel's group by its managers.
class GroupBan {
  const GroupBan({
    required this.userId,
    required this.deviceId,
    required this.bannedByUserId,
    required this.bannedAt,
  });

  final String userId;
  final String? deviceId;
  final String bannedByUserId;
  final DateTime bannedAt;
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
/// A device waiting to be added to the account without an authenticator
/// code (`UserService.RequestRecovery`): it gets in at [eligibleAt] unless
/// one of the account's devices cancels it first.
class PendingRecovery {
  const PendingRecovery({
    required this.deviceId,
    required this.requestedAt,
    required this.eligibleAt,
  });

  factory PendingRecovery.fromProto(pb.PendingRecovery p) => PendingRecovery(
    deviceId: p.deviceId,
    requestedAt: Wire.time(p.requestedAt),
    eligibleAt: Wire.time(p.eligibleAt),
  );

  final String deviceId;
  final DateTime requestedAt;
  final DateTime eligibleAt;
}

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

  /// The commits from [fromEpoch] on, for a device whose group is in
  /// [generation]; one in another generation is told to rejoin
  /// ([GroupSync.resyncRequired]) in the current one.
  Future<GroupSync> syncGroup(
    String token,
    String channelId,
    int fromEpoch, {
    int generation = 0,
  }) async {
    final response = await _channel.call(
      (o) => _delivery.syncGroup(
        pb.SyncGroupRequest(
          channelId: channelId,
          fromEpoch: Wire.int64(fromEpoch),
          generation: Wire.int64(generation),
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
      generation: response.generation.toInt(),
    );
  }

  /// The channel group's current generation, whether or not its group has
  /// been created yet.
  Future<int> groupGeneration(String token, String channelId) async =>
      (await _channel.call(
        (o) => _delivery.getGroupGeneration(
          pb.GetGroupGenerationRequest(channelId: channelId),
          options: o,
        ),
        token: token,
      )).generation.toInt();

  /// Starts a new generation of the channel's group because [generation]'s
  /// can no longer be followed, reporting what this device cannot get past:
  /// SHA-256 of the commit made in [reportedEpoch], or of the group info
  /// describing it, exactly as the server holds it. A channel manager may
  /// leave [reportedSha256] out. Answers the current generation, and whether
  /// this call started it — a [generation] already behind is not reset again.
  ///
  /// Refused with `report_mismatch` (the server holds no such commit or group
  /// info), `group_info_pending` (a group info that has not had time to catch
  /// up), `rate_limited` (this member reset the channel a moment ago) or
  /// `missing_permission` (no report, and not a manager).
  Future<({int generation, bool reset})> resetGroup(
    String token,
    String channelId, {
    required int generation,
    int reportedEpoch = 0,
    Uint8List? reportedSha256,
  }) async {
    final response = await _channel.call(
      (o) => _delivery.resetGroup(
        pb.ResetGroupRequest(
          channelId: channelId,
          generation: Wire.int64(generation),
          reportedEpoch: Wire.int64(reportedEpoch),
          reportedSha256: reportedSha256,
        ),
        options: o,
      ),
      token: token,
    );
    return (generation: response.generation.toInt(), reset: response.reset);
  }

  /// Channel managers: the channel group's resets, newest first.
  Future<List<GroupReset>> groupResets(String token, String channelId) async {
    final response = await _channel.call(
      (o) => _delivery.listGroupResets(
        pb.ListGroupResetsRequest(channelId: channelId),
        options: o,
      ),
      token: token,
    );
    return [
      for (final r in response.resets)
        GroupReset(
          generation: r.generation.toInt(),
          resetAt: Wire.time(r.resetAt),
          requestedByUserId: r.requestedByUserId,
          requestedByDeviceId: r.requestedByDeviceId,
          reportedKind: r.reportedKind.isEmpty ? null : r.reportedKind,
          reportedEpoch: r.reportedEpoch.toInt(),
          reportedSenderUserId: r.reportedSenderUserId.isEmpty
              ? null
              : r.reportedSenderUserId,
          reportedSenderDeviceId: r.reportedSenderDeviceId.isEmpty
              ? null
              : r.reportedSenderDeviceId,
        ),
    ];
  }

  /// Channel managers: keeps [deviceId], or every device of [userId] when
  /// null, out of the channel's group. Returns whether anything changed.
  Future<bool> banFromGroup(
    String token,
    String channelId,
    String userId, {
    String? deviceId,
  }) async => (await _channel.call(
    (o) => _delivery.banFromGroup(
      pb.BanFromGroupRequest(
        channelId: channelId,
        userId: userId,
        deviceId: deviceId ?? '',
      ),
      options: o,
    ),
    token: token,
  )).changed;

  /// Channel managers: lifts a ban set by [banFromGroup].
  Future<bool> unbanFromGroup(
    String token,
    String channelId,
    String userId, {
    String? deviceId,
  }) async => (await _channel.call(
    (o) => _delivery.unbanFromGroup(
      pb.UnbanFromGroupRequest(
        channelId: channelId,
        userId: userId,
        deviceId: deviceId ?? '',
      ),
      options: o,
    ),
    token: token,
  )).changed;

  /// Channel managers: the bans on the channel's group.
  Future<List<GroupBan>> groupBans(String token, String channelId) async {
    final response = await _channel.call(
      (o) => _delivery.listGroupBans(
        pb.ListGroupBansRequest(channelId: channelId),
        options: o,
      ),
      token: token,
    );
    return [
      for (final b in response.bans)
        GroupBan(
          userId: b.userId,
          deviceId: b.deviceId.isEmpty ? null : b.deviceId,
          bannedByUserId: b.bannedByUserId,
          bannedAt: Wire.time(b.bannedAt),
        ),
    ];
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

  // ── Identity vault ──

  /// Stores the person's sealed root and vault on this server. Needs a
  /// session bound to a device.
  Future<void> putVault(
    String token, {
    required String lookupId,
    required Uint8List sealedRoot,
    required Uint8List vault,
  }) => _channel.call(
    (o) => _devices.putIdentityVault(
      pb.PutIdentityVaultRequest(
        lookupId: lookupId,
        sealedRoot: sealedRoot,
        vault: vault,
      ),
      options: o,
    ),
    token: token,
  );

  /// The vault stored here, or null when there is none yet.
  Future<({String lookupId, Uint8List vault})?> getVault(String token) async {
    final response = await _channel.call(
      (o) =>
          _devices.getIdentityVault(pb.GetIdentityVaultRequest(), options: o),
      token: token,
    );
    if (!response.hasVault() || !response.hasLookupId()) return null;
    return (lookupId: response.lookupId, vault: Wire.bytes(response.vault));
  }

  /// The sealed root stored under [lookupId], and the vault sealed under it
  /// (null from a server too old to send it) — the one call a device holding
  /// only the recovery words makes before it has an account. Anonymous.
  /// Throws `vault_not_found`.
  Future<({Uint8List sealedRoot, Uint8List? vault})> sealedRoot(
    String lookupId,
  ) async {
    final response = await _channel.call(
      (o) => _devices.getSealedRoot(
        pb.GetSealedRootRequest(lookupId: lookupId),
        options: o,
      ),
    );
    return (
      sealedRoot: Wire.bytes(response.sealedRoot),
      vault: response.vault.isEmpty ? null : Wire.bytes(response.vault),
    );
  }

  // ── Recovery waits ──

  /// The devices waiting to be added to the account without an
  /// authenticator code. Needs a bound session.
  Future<List<PendingRecovery>> recoveries(String token) async =>
      (await _channel.call(
        (o) => _devices.getRecoveryStatus(
          pb.GetRecoveryStatusRequest(),
          options: o,
        ),
        token: token,
      )).recoveries.map(PendingRecovery.fromProto).toList();

  /// Cancels every one of them, for good. Returns how many there were.
  Future<int> cancelRecoveries(String token) async => (await _channel.call(
    (o) => _devices.cancelRecovery(pb.CancelRecoveryRequest(), options: o),
    token: token,
  )).cancelled;

  // ── Authenticator ──

  /// Sets or replaces the account's authenticator. [code] is a current code
  /// from [secret]; any paired device may do this, which is how a lost
  /// authenticator is replaced.
  Future<void> enrollAuthenticator(
    String token, {
    required Uint8List secret,
    required String code,
    List<String> backupCodes = const [],
  }) => _channel.call(
    (o) => _devices.enrollAuthenticator(
      pb.EnrollAuthenticatorRequest(
        secret: secret,
        code: code,
        backupCodes: backupCodes,
      ),
      options: o,
    ),
    token: token,
  );

  Future<void> disableAuthenticator(String token) => _channel.call(
    (o) => _devices.disableAuthenticator(
      pb.DisableAuthenticatorRequest(),
      options: o,
    ),
    token: token,
  );

  Future<({bool enabled, int backupCodesLeft})> authenticatorStatus(
    String token,
  ) async {
    final response = await _channel.call(
      (o) => _devices.getAuthenticatorStatus(
        pb.GetAuthenticatorStatusRequest(),
        options: o,
      ),
      token: token,
    );
    return (
      enabled: response.enabled,
      backupCodesLeft: response.backupCodesLeft,
    );
  }

  // ── Pairing a device that has no account yet ──

  /// New device: posts its pairing offer. Anonymous. [takeToken] comes back
  /// to collect the approval with.
  Future<({String pairingId, String takeToken})> startPairing(
    Uint8List offer,
  ) async {
    final response = await _channel.call(
      (o) => _devices.startPairing(
        pb.StartPairingRequest(offer: offer),
        options: o,
      ),
    );
    return (pairingId: response.pairingId, takeToken: response.takeToken);
  }

  /// Paired device: the new device's offer, to check against the code.
  /// Throws `pairing_not_found`.
  Future<Uint8List> pairingOffer(String token, String pairingId) async =>
      Wire.bytes(
        (await _channel.call(
          (o) => _devices.getPairingOffer(
            pb.GetPairingOfferRequest(pairingId: pairingId),
            options: o,
          ),
          token: token,
        )).offer,
      );

  Future<void> approvePairing(
    String token,
    String pairingId,
    Uint8List approval,
  ) => _channel.call(
    (o) => _devices.approvePairing(
      pb.ApprovePairingRequest(pairingId: pairingId, approval: approval),
      options: o,
    ),
    token: token,
  );

  /// New device: the approval once a paired device has given it, else null.
  /// Delivered once. Anonymous.
  Future<Uint8List?> takePairingApproval(
    String pairingId,
    String takeToken,
  ) async {
    final response = await _channel.call(
      (o) => _devices.takePairingApproval(
        pb.TakePairingApprovalRequest(
          pairingId: pairingId,
          takeToken: takeToken,
        ),
        options: o,
      ),
    );
    return Wire.optionalBytes(response.hasApproval(), response.approval);
  }
}
