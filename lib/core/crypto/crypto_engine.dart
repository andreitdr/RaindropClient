/// End-to-end encryption for one signed-in server, behind one interface so
/// the rest of the app never names the Rust bridge or MLS types — the same
/// arrangement as `VoiceEngine` for media.
///
/// The engine never touches the network. It turns intentions ("send this",
/// "add these devices") into bytes for the caller to deliver, and delivered
/// bytes into plaintext or group changes. Ordering and delivery are the
/// server's job (its delivery service accepts one commit per epoch); see
/// `docs/crypto.md` for how a commit travels.
library;

import 'package:flutter/foundation.dart';

/// This device's public identity: what the server stores and other users
/// check.
class DeviceKeys {
  const DeviceKeys({
    required this.userId,
    required this.deviceId,
    required this.userIdentityKey,
    required this.deviceSignatureKey,
    required this.certificate,
  });

  final String userId;
  final String deviceId;

  /// The user's Ed25519 identity key — the same on every device of theirs.
  final Uint8List userIdentityKey;

  /// This device's MLS signature key.
  final Uint8List deviceSignatureKey;

  /// The identity key's signature binding [deviceSignatureKey] to this
  /// user and device. Uploaded with the device.
  final Uint8List certificate;
}

/// A group change waiting for the server to accept it. Deliver [commit] to
/// the group and [welcome] (if any) to the devices it adds; then call
/// [CryptoEngine.mergePendingCommit] if the server accepted it, or
/// [CryptoEngine.discardPendingCommit] if another commit won the epoch.
class GroupCommit {
  const GroupCommit({
    required this.commit,
    required this.welcome,
    required this.epochAfter,
  });

  final Uint8List commit;
  final Uint8List? welcome;
  final int epochAfter;
}

/// One device in a group, and who it belongs to (checked against its
/// certificate and the pinned identity key before it gets here).
class GroupMemberInfo {
  const GroupMemberInfo({
    required this.leafIndex,
    required this.userId,
    required this.deviceId,
  });

  final int leafIndex;
  final String userId;
  final String deviceId;
}

/// What a message from a group's delivery stream turned out to be.
sealed class GroupEvent {
  const GroupEvent(this.groupId, this.epoch);

  final Uint8List groupId;
  final int epoch;
}

/// Somebody's application message, decrypted.
class GroupApplicationMessage extends GroupEvent {
  const GroupApplicationMessage(
    super.groupId,
    super.epoch, {
    required this.sender,
    required this.payload,
  });

  final GroupMemberInfo sender;
  final Uint8List payload;
}

/// A commit moved the group to [epoch]. Devices it added or removed are
/// listed so the UI can say "X's device joined encryption".
class GroupMembershipChanged extends GroupEvent {
  const GroupMembershipChanged(
    super.groupId,
    super.epoch, {
    required this.added,
    required this.removed,
    required this.removedSelf,
  });

  final List<GroupMemberInfo> added;
  final List<GroupMemberInfo> removed;

  /// This device is no longer in the group.
  final bool removedSelf;
}

/// A proposal, stored until somebody commits it.
class GroupProposalReceived extends GroupEvent {
  const GroupProposalReceived(Uint8List groupId) : super(groupId, 0);
}

/// This device's own message echoed back; its plaintext is already cached.
class GroupOwnMessage extends GroupEvent {
  const GroupOwnMessage(super.groupId, super.epoch);
}

/// A decrypted message from the local cache. The cache is the only place a
/// message's plaintext exists once its epoch keys are gone.
class DecryptedMessage {
  const DecryptedMessage({
    required this.groupId,
    required this.messageId,
    required this.senderUserId,
    required this.senderDeviceId,
    required this.epoch,
    required this.sentAt,
    required this.payload,
  });

  final Uint8List groupId;
  final String messageId;
  final String senderUserId;
  final String senderDeviceId;
  final int epoch;
  final DateTime sentAt;
  final Uint8List payload;
}

/// Another user's identity key as this device pinned it.
class PinnedUser {
  const PinnedUser({
    required this.userId,
    required this.identityKey,
    required this.verified,
  });

  final String userId;
  final Uint8List identityKey;

  /// The user compared safety numbers rather than trusting on first sight.
  final bool verified;
}

/// A member's changed identity key waiting for the user's decision, as the
/// local store lists it: it comes from the encrypted database, so it is the
/// same after a restart. One per user and key they presented.
@immutable
class PendingIdentityChange {
  const PendingIdentityChange({
    required this.userId,
    required this.presentedKey,
    this.pinnedKey,
    this.heldMessages = 0,
    this.heldGroupIds = const [],
    this.leftGroupIds = const [],
  });

  final String userId;

  /// The key this device trusted for them until now; null if it had none.
  final Uint8List? pinnedKey;

  /// The key they presented — the one to pass to
  /// [CryptoEngine.acceptChangedIdentity].
  final Uint8List presentedKey;

  /// How many of their messages are held, unreadable until the key is
  /// accepted.
  final int heldMessages;

  /// The groups those held messages are in.
  final List<Uint8List> heldGroupIds;

  /// The groups this device is out of because of this change, which accepting
  /// it joins again.
  final List<Uint8List> leftGroupIds;

  /// The channels with held messages, by id (a group is its channel's UUID).
  Set<String> get heldChannelIds => _channels(heldGroupIds);

  /// The channels this device left because of the change.
  Set<String> get leftChannelIds => _channels(leftGroupIds);

  /// Every channel the change touches.
  Set<String> get channelIds => {...heldChannelIds, ...leftChannelIds};

  static Set<String> _channels(List<Uint8List> groups) => {
    for (final group in groups) ?channelIdForGroup(group),
  };

  @override
  bool operator ==(Object other) =>
      other is PendingIdentityChange &&
      other.userId == userId &&
      _same(other.pinnedKey, pinnedKey) &&
      _same(other.presentedKey, presentedKey) &&
      other.heldMessages == heldMessages &&
      _sameAll(other.heldGroupIds, heldGroupIds) &&
      _sameAll(other.leftGroupIds, leftGroupIds);

  @override
  int get hashCode => Object.hash(
    userId,
    Object.hashAll(pinnedKey ?? const <int>[]),
    Object.hashAll(presentedKey),
    heldMessages,
    heldGroupIds.length,
    leftGroupIds.length,
  );

  static bool _same(Uint8List? a, Uint8List? b) =>
      a == null || b == null ? a == b : listEquals(a, b);

  static bool _sameAll(List<Uint8List> a, List<Uint8List> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) listEquals(a[i], b[i])]
          .every((same) => same);
}

/// A sealed key backup for the server to store. [recoveryWords] is set for a
/// recovery-key backup: show it once, then let it go.
class SealedKeyBackup {
  const SealedKeyBackup({required this.blob, this.recoveryWords});

  final Uint8List blob;
  final String? recoveryWords;
}

enum CryptoErrorKind {
  /// The local store's key is wrong or missing.
  storeLocked,

  /// A user's identity key changed — a trust decision for the user, never
  /// resolved silently. See [CryptoException.userId].
  identityChanged,

  /// Wrong recovery words or passphrase.
  backupLocked,

  /// A signature, certificate or credential did not verify.
  verification,
  notFound,
  malformed,

  /// The server delivered a commit claiming to be this device's own that this
  /// device does not hold (it discarded it after the server had in fact taken
  /// it, or another member forged it). The local group can no longer follow
  /// the server's: delete it and rejoin.
  resyncRequired,
  other,
}

class CryptoException implements Exception {
  const CryptoException(
    this.kind,
    this.message, {
    this.userId,
    this.pinnedKey,
    this.presentedKey,
  });

  final CryptoErrorKind kind;
  final String message;

  /// Whose identity changed, for [CryptoErrorKind.identityChanged].
  final String? userId;

  /// For [CryptoErrorKind.identityChanged]: the key this device has pinned
  /// for [userId], if any.
  final Uint8List? pinnedKey;

  /// For [CryptoErrorKind.identityChanged]: the key [userId] presented, which
  /// [CryptoEngine.acceptChangedIdentity] takes to accept the change.
  final Uint8List? presentedKey;

  @override
  String toString() => 'CryptoException($kind): $message';
}

/// One device's end-to-end encryption state on one server. Open one per
/// signed-in server (see `crypto_store.dart`); calls may overlap.
abstract interface class CryptoEngine {
  // ── Identity ──

  /// This device's identity, or null before one was created or restored.
  Future<DeviceKeys?> device();

  /// A new user's identity key and first device, at registration.
  Future<DeviceKeys> createIdentity({
    required String userId,
    required String deviceId,
  });

  /// A new device for a user whose every device is gone, from their backup.
  Future<DeviceKeys> restoreWithRecoveryWords({
    required Uint8List backup,
    required String words,
    required String deviceId,
  });

  Future<DeviceKeys> restoreWithPassphrase({
    required Uint8List backup,
    required String passphrase,
    required String deviceId,
  });

  Future<SealedKeyBackup> sealBackupWithRecoveryKey();

  Future<SealedKeyBackup> sealBackupWithPassphrase(String passphrase);

  /// Signs the server's session-binding challenge with this device's key.
  Future<Uint8List> signSessionChallenge(Uint8List nonce);

  /// Signs a message attestation — this device's statement that it wrote a
  /// message, over [canonical] (see `MessagePayload.attestationBytes`) — so a
  /// recipient can prove it to moderators if they report the message.
  Future<Uint8List> signMessageAttestation(Uint8List canonical);

  /// The same for a message that carries files, whose canonical bytes also
  /// name each file's id and ciphertext hash — signed under its own context
  /// (`raindrop/message-attestation/v2`), so a reporter cannot pair the words
  /// with another file.
  Future<Uint8List> signMessageAttestationV2(Uint8List canonical);

  /// New device, before it has an identity: makes its key and a link offer
  /// for one of the user's existing devices to approve. Upload [offer]; put
  /// [commitment] and [codeSecret] in the [DeviceLinkCode] the user carries
  /// across. The code secret is never uploaded; the store keeps it until
  /// [completeDeviceLink].
  Future<({Uint8List offer, Uint8List commitment, Uint8List codeSecret})>
  beginDeviceLink({required String userId, required String deviceId});

  /// Existing device: checks [offer] against the commitment from the link
  /// code (throws [CryptoErrorKind.verification] if the server swapped it),
  /// and returns the approval to upload, sealed to the code's [codeSecret].
  Future<Uint8List> approveDeviceLink(
    Uint8List offer,
    Uint8List commitment,
    Uint8List codeSecret,
  );

  /// New device: opens the approval and becomes a full device of the user.
  /// Throws [CryptoErrorKind.verification] for an approval not sealed to the
  /// link code's secret — one the server made itself.
  Future<DeviceKeys> completeDeviceLink(Uint8List approval);

  Future<PinnedUser?> pinnedUser(String userId);

  /// The user accepts [userId]'s changed identity key after looking at the
  /// new safety number.
  Future<void> acceptChangedIdentity(String userId, Uint8List identityKey);

  /// Every changed identity key waiting for the user's decision, read from the
  /// encrypted store (so complete after a restart): the key pinned, the key
  /// presented, the messages held and the groups left because of it.
  /// Accepting a key ([acceptChangedIdentity]) clears its entry.
  Future<List<PendingIdentityChange>> pendingIdentityChanges();

  /// The user compared safety numbers with [userId] and they matched.
  Future<void> markVerified(String userId, Uint8List identityKey);

  // ── Key packages and groups ──

  Future<List<Uint8List>> generateKeyPackages(
    int count, {
    bool lastResort = false,
  });

  Future<void> createGroup(Uint8List groupId);

  Future<bool> hasGroup(Uint8List groupId);

  Future<int> epoch(Uint8List groupId);

  Future<List<GroupMemberInfo>> members(Uint8List groupId);

  /// The signed group state other devices join from. Upload after every
  /// merged commit.
  Future<Uint8List> groupInfo(Uint8List groupId);

  Future<GroupCommit> addMembers(
    Uint8List groupId,
    List<Uint8List> keyPackages,
  );

  Future<GroupCommit> removeMembers(Uint8List groupId, List<int> leafIndices);

  /// Rotates this device's keys in the group (a new epoch, so a new media key
  /// for calls).
  Future<GroupCommit> selfUpdate(Uint8List groupId);

  /// Joins the group [expectedGroupId] from its published [groupInfo] without
  /// anybody online to add this device.
  ///
  /// Refused if [groupInfo] is for another group or this device already holds
  /// [expectedGroupId]. The join is merged on this device already (the commit's
  /// `epochAfter` is the epoch it is at), and nothing is kept if a member of
  /// the group fails validation; if the server then refuses the commit, the
  /// caller deletes the group again.
  Future<({Uint8List groupId, GroupCommit commit})> joinByExternalCommit(
    Uint8List expectedGroupId,
    Uint8List groupInfo,
  );

  /// Joins a group this device was added to; returns its id.
  Future<Uint8List> joinFromWelcome(Uint8List welcome);

  Future<int> mergePendingCommit(Uint8List groupId);

  Future<void> discardPendingCommit(Uint8List groupId);

  /// Drops this device's MLS state for the group and its pending commit, but
  /// keeps the cached and held messages: they are the only copy of their
  /// plaintext. For a group about to be rejoined (resync, a failed join).
  Future<void> resetGroup(Uint8List groupId);

  /// Forgets the group entirely, cached and held messages included. Only for a
  /// group that is gone for this device: it was removed from it, or the
  /// channel was deleted.
  Future<void> deleteGroup(Uint8List groupId);

  // ── Messages ──

  Future<Uint8List> encrypt(Uint8List groupId, Uint8List payload);

  /// Processes a commit, proposal or application message from the stream.
  /// This device's own commit echoed back is merged only if it is the one
  /// still pending; any other "own" commit throws
  /// [CryptoErrorKind.resyncRequired].
  Future<GroupEvent> process(Uint8List message);

  /// Decrypts a channel message into the local cache (or returns the cached
  /// copy); null when [message] was not an application message.
  Future<DecryptedMessage?> receiveMessage({
    required String messageId,
    required DateTime sentAt,
    required Uint8List message,
  });

  /// Keeps this device's own message, which it cannot decrypt from the
  /// server's echo.
  Future<void> rememberSent({
    required Uint8List groupId,
    required String messageId,
    required DateTime sentAt,
    required Uint8List payload,
  });

  /// Newest first, sent before [before] (or the newest overall).
  Future<List<DecryptedMessage>> cachedMessages(
    Uint8List groupId, {
    DateTime? before,
    int limit = 50,
  });

  Future<void> forgetMessage(Uint8List groupId, String messageId);

  /// A secret all current members derive and nobody else can — a call's
  /// media key, for example.
  Future<Uint8List> exportSecret(
    Uint8List groupId, {
    required String label,
    required Uint8List context,
    int length = 32,
  });
}

/// The MLS group id for a channel's group in [generation]: the channel's UUID
/// as 16 bytes in RFC 4122 (big-endian) order — what the server gets from
/// `Guid.ToByteArray(bigEndian: true)`, so both sides name the same group
/// without a lookup — followed, for any generation after 0, by the generation
/// as 8 big-endian bytes. A group that was never reset keeps the id it always
/// had, and no generation's id can be another's: the lengths differ.
Uint8List groupIdForChannel(String channelId, [int generation = 0]) {
  final hex = channelId.replaceAll('-', '');
  if (hex.length != 32) {
    throw ArgumentError.value(channelId, 'channelId', 'not a UUID');
  }
  if (generation < 0) {
    throw ArgumentError.value(generation, 'generation', 'negative');
  }
  return Uint8List.fromList([
    for (var i = 0; i < 32; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
    if (generation > 0)
      for (var shift = 56; shift >= 0; shift -= 8) (generation >> shift) & 0xff,
  ]);
}

/// The channel a group id names — [groupIdForChannel] the other way, for any
/// generation — or null for an id that is not a channel's.
String? channelIdForGroup(Uint8List groupId) {
  if (groupId.length != 16 && groupId.length != 24) return null;
  final hex = [
    for (final b in groupId.take(16)) b.toRadixString(16).padLeft(2, '0'),
  ].join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// What the user carries from a new device to an existing one to link it:
/// the server's link id, a 128-bit commitment to the new device's offer and a
/// 128-bit code secret. The commitment is what stops the server from swapping
/// in keys of its own; the code secret, which never goes to the server, is
/// what stops it from sealing an identity of its own to the new device.
///
/// Written as `RDL2-<link id>-<commitment>-<code secret>`, both in base32,
/// which fits a QR code and can be typed; parsing forgives case, spaces and
/// line breaks.
class DeviceLinkCode {
  const DeviceLinkCode({
    required this.linkId,
    required this.commitment,
    required this.codeSecret,
  });

  final String linkId;
  final Uint8List commitment;
  final Uint8List codeSecret;

  static const _prefix = 'RDL2';
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  @override
  String toString() =>
      '$_prefix-$linkId-${_base32(commitment)}-${_base32(codeSecret)}';

  /// Parses a code, or returns null when it is not one.
  static DeviceLinkCode? tryParse(String text) {
    final parts = text.toUpperCase().replaceAll(RegExp(r'\s'), '').split('-');
    if (parts.length != 4 || parts[0] != _prefix || parts[1].isEmpty) {
      return null;
    }
    final commitment = _unbase32(parts[2]);
    if (commitment == null || commitment.length != 16) return null;
    final codeSecret = _unbase32(parts[3]);
    if (codeSecret == null || codeSecret.length != 16) return null;
    return DeviceLinkCode(
      linkId: parts[1],
      commitment: commitment,
      codeSecret: codeSecret,
    );
  }

  static String _base32(Uint8List bytes) {
    final out = StringBuffer();
    var buffer = 0;
    var bits = 0;
    for (final byte in bytes) {
      buffer = (buffer << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        out.write(_alphabet[(buffer >> (bits - 5)) & 31]);
        bits -= 5;
      }
    }
    if (bits > 0) out.write(_alphabet[(buffer << (5 - bits)) & 31]);
    return out.toString();
  }

  static Uint8List? _unbase32(String text) {
    final out = <int>[];
    var buffer = 0;
    var bits = 0;
    for (final char in text.split('')) {
      final value = _alphabet.indexOf(char);
      if (value < 0) return null;
      buffer = ((buffer << 5) | value) & 0xFFFF;
      bits += 5;
      if (bits >= 8) {
        out.add((buffer >> (bits - 8)) & 0xFF);
        bits -= 8;
      }
    }
    return Uint8List.fromList(out);
  }
}
