import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/crypto_store.dart';
import '../../../core/crypto/identity_crypto.dart';
import '../../../core/models/server_profile.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/raindrop_channel.dart';
import '../../../core/network/server_trust.dart';
import '../../../core/network/users_api.dart';
import '../../../core/storage/identity_store.dart';
import '../../../core/storage/secure_store.dart';
import '../../identity/device_sign_in.dart';
import '../../security/controllers/device_setup_controller.dart';
import '../../servers/controllers/servers_controller.dart';
import '../../servers/controllers/session_controller.dart';

/// Drives one "add a server" wizard from first contact through to a stored,
/// signed-in session. Deliberately not a Riverpod provider itself — it's
/// a short-lived object owned by the connect screens, created fresh each time
/// the user starts adding a server and discarded once they finish or back
/// out.
///
/// There is nothing to type but the address, and a username the first time:
/// the account on a server is derived from the person's root secret and the
/// server's own identity key, so the same person adding the same server from
/// any of their devices — or adding it back after removing it — arrives at
/// the same account.
class ConnectServerFlow {
  ConnectServerFlow({
    required this.host,
    required this.port,
    required this.identity,
    this.stores = const CryptoStores(),
  });

  final String host;
  final int port;

  /// The person signing in.
  final ClientIdentity identity;

  /// Where this device's per-server keys live; [dispose] deletes the ones an
  /// abandoned flow made.
  final CryptoStores stores;

  late final RaindropChannel client = RaindropChannel.forServer(
    host: host,
    port: port,
  );
  late final UsersApi usersApi = UsersApi(client);

  ServerInfo? _probed;
  String? _guid;
  bool _persisted = false;
  bool _madeKeys = false;

  /// The account this person has on the server: derived by [probe], and also
  /// the local `ServerProfile.id`.
  String get guid =>
      _guid ?? (throw StateError('probe() has not completed yet.'));

  Uint8List get _serverKey => _probed!.identityKey!;

  /// Fetches the server's identity and derives the account from it. On a
  /// first connection the certificate is taken on trust, so this at least
  /// checks the server's story is consistent: the fingerprint it advertises
  /// is the certificate the handshake presented, and its identity key signed
  /// that certificate.
  Future<ServerInfo> probe() async {
    final info = await usersApi.serverInfo();
    final presented = client.pinner.observedFingerprint;
    if (presented != null && !ServerTrust.isConsistent(info, presented)) {
      throw ApiException.certificateMismatch();
    }
    final key = info.identityKey;
    if (key == null) {
      // The account is derived from this key and the sign-in signature covers
      // it; without one there is nothing to derive from.
      throw const ApiException(
        0,
        'auth_unavailable',
        'This server has no identity key, so this app cannot sign in to it. '
            'Ask whoever runs it to update the server.',
      );
    }
    _guid = await IdentityCrypto.accountId(identity.root, key);
    return _probed = info;
  }

  /// Whether this device already lists the server [probe] found.
  bool alreadyAdded(WidgetRef ref) =>
      _listedIn(ref.read(serversControllerProvider));

  bool _listedIn(List<ServerProfile> servers) =>
      servers.any((s) => s.id == guid);

  Future<UserStateResult> checkStatus() => usersApi.status(guid);

  Future<UsernameAvailability> usernameAvailable(String username) =>
      usersApi.usernameAvailable(username);

  /// Signs this device in. [username] registers the account when the server
  /// has none for this person; [authenticatorCode] is for a device that is
  /// new to an account with an authenticator and does not hold its secret
  /// (see [needsAuthenticatorCode]).
  Future<SessionResult> signIn(
    WidgetRef ref, {
    String? username,
    String? authenticatorCode,
  }) async {
    // Through the provider, not a store of this flow's own: the session that
    // follows opens the same file, and one store must have one owner.
    final engine = await ref.read(cryptoEngineProvider(guid).future);
    _madeKeys = true;
    return signInWithDevice(
      api: usersApi,
      engine: engine,
      identity: identity,
      serverKey: _serverKey,
      username: username,
      typedCode: authenticatorCode,
    );
  }

  /// Pins the certificate fingerprint and identity key observed during this
  /// flow, stores the new session token, and registers the server with the
  /// rest of the app.
  Future<void> persist(
    WidgetRef ref, {
    required SessionResult session,
    required String displayName,
  }) async {
    const secure = SecureStore();
    final observed = client.pinner.observedFingerprint;
    if (observed != null && await secure.pinnedFingerprint(guid) == null) {
      await secure.pinFingerprint(guid, observed);
    }
    final pinned = await secure.pinnedFingerprint(guid);
    final info = _probed;
    if (info != null && pinned != null) {
      await ServerTrust.pinIdentityIfMissing(
        serverId: guid,
        info: info,
        presentedFingerprint: pinned,
      );
    }
    await secure.saveSessionToken(guid, session.token);

    final profile = ServerProfile(
      id: guid,
      host: host,
      port: port,
      displayName: displayName,
    );
    // Handed over before the server is listed, so the session provider's
    // first build with this profile takes this session instead of opening a
    // second one.
    ref
        .read(serverSessionProvider(guid).notifier)
        .adopt(
          ServerSession(
            profile: profile,
            client: client,
            token: session.token,
            currentUser: session.user,
          ),
        );
    _persisted = true;
    ref.read(serversControllerProvider.notifier).add(profile);
    ref.read(activeServerIdProvider.notifier).select(guid);
  }

  /// Puts the flow where an abandoned sign-in leaves it — the account
  /// derived and this device's keys made — without a server.
  @visibleForTesting
  void debugKeysMadeFor(String guid) {
    _guid = guid;
    _madeKeys = true;
  }

  /// Closes the flow. When it was abandoned after making this device's keys
  /// for the server, those keys go too: nothing lists the server, so nothing
  /// would ever use or delete them.
  ///
  /// Takes the app's [ProviderContainer] rather than a screen's `WidgetRef`:
  /// it runs as the screen goes away — from its `dispose`, when that ref is
  /// already unusable — and carries on after awaits the screen does not live
  /// through. Capture it with `ProviderScope.containerOf` while the screen is
  /// still mounted.
  Future<void> dispose(ProviderContainer container) async {
    if (_persisted) return;
    final guid = _guid;
    if (guid != null &&
        _madeKeys &&
        !_listedIn(container.read(serversControllerProvider))) {
      try {
        (await container.read(cryptoEngineProvider(guid).future)).dispose();
      } on Object {
        // It never opened; there is still a file and a key to remove.
      }
      container.invalidate(cryptoEngineProvider(guid));
      await stores.delete(guid);
    }
    client.close();
  }
}
