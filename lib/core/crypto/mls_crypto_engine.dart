import 'dart:typed_data';

import 'bridge/api/session.dart' as rust;
import 'crypto_engine.dart';

/// [CryptoEngine] over the Rust core (`RaindropCrypto/crates/raindrop_crypto`,
/// OpenMLS underneath), reached through the generated bridge in `bridge/`.
/// The only file outside `bridge/` that imports it.
class MlsCryptoEngine implements CryptoEngine {
  MlsCryptoEngine._(this._session);

  final rust.CryptoSession _session;

  /// Opens (creating on first use) the encrypted store at [path] with the
  /// 32-byte [key]. Throws [CryptoException] with
  /// [CryptoErrorKind.storeLocked] for a wrong key.
  static Future<MlsCryptoEngine> open({
    required String path,
    required Uint8List key,
  }) => _guard(() async {
    return MlsCryptoEngine._(
      await rust.CryptoSession.open(path: path, key: key),
    );
  });

  bool _disposed = false;

  /// Releases the native session and closes the store. The engine must not
  /// be used afterwards. Safe to call more than once.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _session.dispose();
  }

  // ── Identity ──

  @override
  Future<DeviceKeys?> device() => _guard(() async {
    final device = await _session.device();
    return device == null ? null : _device(device);
  });

  @override
  Future<DeviceKeys> createIdentity({
    required String userId,
    required String deviceId,
  }) => _guard(
    () async => _device(
      await _session.createIdentity(userId: userId, deviceId: deviceId),
    ),
  );

  @override
  Future<DeviceKeys> restoreWithRecoveryWords({
    required Uint8List backup,
    required String words,
    required String deviceId,
  }) => _guard(
    () async => _device(
      await _session.restoreIdentityWithRecoveryKey(
        blob: backup,
        recoveryWords: words,
        deviceId: deviceId,
      ),
    ),
  );

  @override
  Future<DeviceKeys> restoreWithPassphrase({
    required Uint8List backup,
    required String passphrase,
    required String deviceId,
  }) => _guard(
    () async => _device(
      await _session.restoreIdentityWithPassphrase(
        blob: backup,
        passphrase: passphrase,
        deviceId: deviceId,
      ),
    ),
  );

  @override
  Future<SealedKeyBackup> sealBackupWithRecoveryKey() => _guard(() async {
    final sealed = await _session.sealBackupWithRecoveryKey();
    return SealedKeyBackup(
      blob: sealed.blob,
      recoveryWords: sealed.recoveryWords,
    );
  });

  @override
  Future<SealedKeyBackup> sealBackupWithPassphrase(String passphrase) =>
      _guard(() async {
        final sealed = await _session.sealBackupWithPassphrase(
          passphrase: passphrase,
        );
        return SealedKeyBackup(blob: sealed.blob);
      });

  @override
  Future<Uint8List> signSessionChallenge(Uint8List nonce) =>
      _guard(() => _session.signSessionChallenge(nonce: nonce));

  @override
  Future<Uint8List> signMessageAttestation(Uint8List canonical) =>
      _guard(() => _session.signMessageAttestation(canonical: canonical));

  @override
  Future<Uint8List> signMessageAttestationV2(Uint8List canonical) =>
      _guard(() => _session.signMessageAttestationV2(canonical: canonical));

  @override
  Future<({Uint8List offer, Uint8List commitment})> beginDeviceLink({
    required String userId,
    required String deviceId,
  }) => _guard(() async {
    final link = await _session.beginDeviceLink(
      userId: userId,
      deviceId: deviceId,
    );
    return (offer: link.offer, commitment: link.commitment);
  });

  @override
  Future<Uint8List> approveDeviceLink(Uint8List offer, Uint8List commitment) =>
      _guard(
        () => _session.approveDeviceLink(offer: offer, commitment: commitment),
      );

  @override
  Future<DeviceKeys> completeDeviceLink(Uint8List approval) => _guard(
    () async => _device(await _session.completeDeviceLink(approval: approval)),
  );

  @override
  Future<PinnedUser?> pinnedUser(String userId) => _guard(() async {
    final pinned = await _session.pinnedIdentity(userId: userId);
    return pinned == null
        ? null
        : PinnedUser(
            userId: pinned.userId,
            identityKey: pinned.identityKey,
            verified: pinned.verified,
          );
  });

  @override
  Future<void> acceptChangedIdentity(String userId, Uint8List identityKey) =>
      _guard(
        () => _session.acceptChangedIdentity(
          userId: userId,
          identityKey: identityKey,
        ),
      );

  @override
  Future<void> markVerified(String userId, Uint8List identityKey) => _guard(
    () => _session.markVerified(userId: userId, identityKey: identityKey),
  );

  // ── Key packages and groups ──

  @override
  Future<List<Uint8List>> generateKeyPackages(
    int count, {
    bool lastResort = false,
  }) => _guard(
    () => _session.generateKeyPackages(count: count, lastResort: lastResort),
  );

  @override
  Future<void> createGroup(Uint8List groupId) =>
      _guard(() => _session.createGroup(groupId: groupId));

  @override
  Future<bool> hasGroup(Uint8List groupId) =>
      _guard(() => _session.hasGroup(groupId: groupId));

  @override
  Future<int> epoch(Uint8List groupId) =>
      _guard(() async => (await _session.epoch(groupId: groupId)).toInt());

  @override
  Future<List<GroupMemberInfo>> members(Uint8List groupId) => _guard(
    () async =>
        (await _session.members(groupId: groupId)).map(_member).toList(),
  );

  @override
  Future<Uint8List> groupInfo(Uint8List groupId) =>
      _guard(() => _session.groupInfo(groupId: groupId));

  @override
  Future<GroupCommit> addMembers(
    Uint8List groupId,
    List<Uint8List> keyPackages,
  ) => _guard(
    () async => _commit(
      await _session.addMembers(groupId: groupId, keyPackages: keyPackages),
    ),
  );

  @override
  Future<GroupCommit> removeMembers(Uint8List groupId, List<int> leafIndices) =>
      _guard(
        () async => _commit(
          await _session.removeMembers(
            groupId: groupId,
            leafIndices: leafIndices,
          ),
        ),
      );

  @override
  Future<GroupCommit> selfUpdate(Uint8List groupId) =>
      _guard(() async => _commit(await _session.selfUpdate(groupId: groupId)));

  @override
  Future<({Uint8List groupId, GroupCommit commit})> joinByExternalCommit(
    Uint8List groupInfo,
  ) => _guard(() async {
    final join = await _session.joinByExternalCommit(groupInfo: groupInfo);
    return (groupId: join.groupId, commit: _commit(join.pending));
  });

  @override
  Future<Uint8List> joinFromWelcome(Uint8List welcome) =>
      _guard(() => _session.joinFromWelcome(welcome: welcome));

  @override
  Future<int> mergePendingCommit(Uint8List groupId) => _guard(
    () async => (await _session.mergePendingCommit(groupId: groupId)).toInt(),
  );

  @override
  Future<void> discardPendingCommit(Uint8List groupId) =>
      _guard(() => _session.discardPendingCommit(groupId: groupId));

  @override
  Future<void> deleteGroup(Uint8List groupId) =>
      _guard(() => _session.deleteGroup(groupId: groupId));

  // ── Messages ──

  @override
  Future<Uint8List> encrypt(Uint8List groupId, Uint8List payload) =>
      _guard(() => _session.encrypt(groupId: groupId, payload: payload));

  @override
  Future<GroupEvent> process(Uint8List message) => _guard(() async {
    final m = await _session.process(message: message);
    final epoch = m.epoch.toInt();
    return switch (m.kind) {
      rust.ProcessedKind.application => GroupApplicationMessage(
        m.groupId,
        epoch,
        sender: _member(m.sender!),
        payload: m.payload!,
      ),
      rust.ProcessedKind.commit => GroupMembershipChanged(
        m.groupId,
        epoch,
        added: m.added.map(_member).toList(),
        removed: m.removed.map(_member).toList(),
        removedSelf: m.removedSelf,
      ),
      rust.ProcessedKind.proposal => GroupProposalReceived(m.groupId),
      rust.ProcessedKind.ownMessage => GroupOwnMessage(m.groupId, epoch),
    };
  });

  @override
  Future<DecryptedMessage?> receiveMessage({
    required String messageId,
    required DateTime sentAt,
    required Uint8List message,
  }) => _guard(() async {
    final cached = await _session.receiveMessage(
      messageId: messageId,
      sentAtUnixMs: sentAt.millisecondsSinceEpoch,
      message: message,
    );
    return cached == null ? null : _cached(cached);
  });

  @override
  Future<void> rememberSent({
    required Uint8List groupId,
    required String messageId,
    required DateTime sentAt,
    required Uint8List payload,
  }) => _guard(
    () => _session.rememberSent(
      groupId: groupId,
      messageId: messageId,
      sentAtUnixMs: sentAt.millisecondsSinceEpoch,
      payload: payload,
    ),
  );

  @override
  Future<List<DecryptedMessage>> cachedMessages(
    Uint8List groupId, {
    DateTime? before,
    int limit = 50,
  }) => _guard(() async {
    final messages = await _session.cachedMessages(
      groupId: groupId,
      beforeUnixMs: before?.millisecondsSinceEpoch,
      limit: limit,
    );
    return messages.map(_cached).toList();
  });

  @override
  Future<void> forgetMessage(Uint8List groupId, String messageId) => _guard(
    () => _session.forgetMessage(groupId: groupId, messageId: messageId),
  );

  @override
  Future<Uint8List> exportSecret(
    Uint8List groupId, {
    required String label,
    required Uint8List context,
    int length = 32,
  }) => _guard(
    () => _session.exportSecret(
      groupId: groupId,
      label: label,
      context: context,
      length: length,
    ),
  );

  // ── Translation ──

  static DeviceKeys _device(rust.DeviceIdentity d) => DeviceKeys(
    userId: d.userId,
    deviceId: d.deviceId,
    userIdentityKey: d.userIdentityKey,
    deviceSignatureKey: d.deviceSignatureKey,
    certificate: d.certificate,
  );

  static GroupCommit _commit(rust.PendingCommit p) => GroupCommit(
    commit: p.commit,
    welcome: p.welcome,
    epochAfter: p.epochAfter.toInt(),
  );

  static GroupMemberInfo _member(rust.GroupMember m) => GroupMemberInfo(
    leafIndex: m.leafIndex,
    userId: m.userId,
    deviceId: m.deviceId,
  );

  static DecryptedMessage _cached(rust.CachedMessage m) => DecryptedMessage(
    groupId: m.groupId,
    messageId: m.messageId,
    senderUserId: m.senderUserId,
    senderDeviceId: m.senderDeviceId,
    epoch: m.epoch.toInt(),
    sentAt: DateTime.fromMillisecondsSinceEpoch(
      m.sentAtUnixMs.toInt(),
      isUtc: true,
    ),
    payload: m.payload,
  );

  /// Runs [call], turning the bridge's error type into [CryptoException] so
  /// nothing above this file sees a generated type.
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on rust.CryptoFailure catch (e) {
      throw CryptoException(
        switch (e.kind) {
          rust.CryptoFailureKind.storeLocked => CryptoErrorKind.storeLocked,
          rust.CryptoFailureKind.identityChanged =>
            CryptoErrorKind.identityChanged,
          rust.CryptoFailureKind.backupLocked => CryptoErrorKind.backupLocked,
          rust.CryptoFailureKind.verification => CryptoErrorKind.verification,
          rust.CryptoFailureKind.notFound => CryptoErrorKind.notFound,
          rust.CryptoFailureKind.malformed => CryptoErrorKind.malformed,
          rust.CryptoFailureKind.other => CryptoErrorKind.other,
        },
        e.message,
        userId: e.userId,
      );
    }
  }
}

/// The 60-digit safety number two users compare, symmetric in its arguments.
String safetyNumber({
  required String userA,
  required Uint8List keyA,
  required String userB,
  required Uint8List keyB,
}) => rust.safetyNumber(userA: userA, keyA: keyA, userB: userB, keyB: keyB);
