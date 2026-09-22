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

import 'dart:typed_data';

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
  other,
}

class CryptoException implements Exception {
  const CryptoException(this.kind, this.message, {this.userId});

  final CryptoErrorKind kind;
  final String message;

  /// Whose identity changed, for [CryptoErrorKind.identityChanged].
  final String? userId;

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

  /// New device, before it has an identity: makes its key and a link offer
  /// for one of the user's existing devices to approve. Upload [offer]; put
  /// [commitment] in the [DeviceLinkCode] the user carries across.
  Future<({Uint8List offer, Uint8List commitment})> beginDeviceLink({
    required String userId,
    required String deviceId,
  });

  /// Existing device: checks [offer] against the commitment from the link
  /// code (throws [CryptoErrorKind.verification] if the server swapped it),
  /// and returns the approval to upload.
  Future<Uint8List> approveDeviceLink(Uint8List offer, Uint8List commitment);

  /// New device: opens the approval and becomes a full device of the user.
  Future<DeviceKeys> completeDeviceLink(Uint8List approval);

  Future<PinnedUser?> pinnedUser(String userId);

  /// The user accepts [userId]'s changed identity key after looking at the
  /// new safety number.
  Future<void> acceptChangedIdentity(String userId, Uint8List identityKey);

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

  /// Joins a group from its published [groupInfo] without anybody online to
  /// add this device.
  Future<({Uint8List groupId, GroupCommit commit})> joinByExternalCommit(
    Uint8List groupInfo,
  );

  /// Joins a group this device was added to; returns its id.
  Future<Uint8List> joinFromWelcome(Uint8List welcome);

  Future<int> mergePendingCommit(Uint8List groupId);

  Future<void> discardPendingCommit(Uint8List groupId);

  Future<void> deleteGroup(Uint8List groupId);

  // ── Messages ──

  Future<Uint8List> encrypt(Uint8List groupId, Uint8List payload);

  /// Processes a commit, proposal or application message from the stream.
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

/// The MLS group id for a channel: its UUID as 16 bytes in RFC 4122 (big-
/// endian) order — what the server gets from `Guid.ToByteArray(bigEndian:
/// true)`, so both sides name the same group without a lookup.
Uint8List groupIdForChannel(String channelId) {
  final hex = channelId.replaceAll('-', '');
  if (hex.length != 32) {
    throw ArgumentError.value(channelId, 'channelId', 'not a UUID');
  }
  return Uint8List.fromList([
    for (var i = 0; i < 32; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ]);
}

/// What the user carries from a new device to an existing one to link it:
/// the server's link id and a 128-bit commitment to the new device's offer.
/// The commitment is what stops the server from swapping in keys of its own.
///
/// Written as `RDL1-<link id>-<commitment in base32>`, which fits a QR code
/// and can be typed; parsing forgives case, spaces and line breaks.
class DeviceLinkCode {
  const DeviceLinkCode({required this.linkId, required this.commitment});

  final String linkId;
  final Uint8List commitment;

  static const _prefix = 'RDL1';
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  @override
  String toString() => '$_prefix-$linkId-${_base32(commitment)}';

  /// Parses a code, or returns null when it is not one.
  static DeviceLinkCode? tryParse(String text) {
    final parts = text.toUpperCase().replaceAll(RegExp(r'\s'), '').split('-');
    if (parts.length != 3 || parts[0] != _prefix || parts[1].isEmpty) {
      return null;
    }
    final commitment = _unbase32(parts[2]);
    if (commitment == null || commitment.length != 16) return null;
    return DeviceLinkCode(linkId: parts[1], commitment: commitment);
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
