import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/server_trust.dart';
import '../../../core/network/users_api.dart';
import '../../../core/storage/secure_store.dart';
import '../../servers/controllers/servers_controller.dart';
import '../../servers/controllers/session_controller.dart';

/// Drives one "add a server" wizard from first contact through to a stored,
/// authenticated session. Deliberately not a Riverpod provider itself — it's
/// a short-lived object owned by the connect/auth screens, created fresh
/// each time the user starts adding a server and discarded once they finish
/// or back out.
class ConnectServerFlow {
  ConnectServerFlow({required this.host, required this.port})
    : _guid = const Uuid().v4(),
      _pinnedFingerprint = null;

  ConnectServerFlow._existing({
    required this.host,
    required this.port,
    required String initialGuid,
    required this._pinnedFingerprint,
  }) : _guid = initialGuid;

  /// Rebuilds a flow for a server already in `ServersController`, e.g. when
  /// a stored session token has expired and the user needs to log back in.
  /// Unlike the fresh-connect constructor, this pins strictly from the start
  /// — a mismatch here is treated as a real certificate change, not TOFU.
  static Future<ConnectServerFlow> forExisting(ServerProfile profile) async {
    final pinned = await const SecureStore().pinnedFingerprint(profile.id);
    return ConnectServerFlow._existing(
      host: profile.host,
      port: profile.port,
      initialGuid: profile.id,
      pinnedFingerprint: pinned,
    );
  }

  final String host;
  final int port;

  /// This client's identity on the server being connected to. Generated up
  /// front — "a client holds a separate GUID per server", per the server's
  /// own design. It doubles as the local `ServerProfile.id`.
  ///
  /// Not final: logging in with a username hands back the UUID the account
  /// already has on this server, and the flow adopts it in place of the one
  /// it generated. Nothing has been keyed off the generated GUID until
  /// [persist] runs, so swapping it before then is safe.
  String get guid => _guid;

  String _guid;

  final String? _pinnedFingerprint;

  late final ApiClient client = ApiClient.forServer(
    host: host,
    port: port,
    pinnedFingerprint: _pinnedFingerprint,
  );
  late final UsersApi usersApi = UsersApi(client);

  ServerInfo? _probed;

  /// Fetches the server's identity. On a first connection the certificate is
  /// taken on trust, so this at least checks the server's story is
  /// consistent: the fingerprint it advertises is the certificate the
  /// handshake presented, and its identity key signed that certificate.
  Future<ServerInfo> probe() async {
    final info = await usersApi.serverInfo();
    final presented = client.pinner.observedFingerprint;
    if (presented != null && !ServerTrust.isConsistent(info, presented)) {
      throw ApiException.certificateMismatch();
    }
    return _probed = info;
  }

  Future<UserStateResult> checkStatus() => usersApi.status(guid);

  Future<UsernameAvailability> usernameAvailable(String username) =>
      usersApi.usernameAvailable(username);

  Future<SessionResult> register({
    required String username,
    required String password,
  }) => usersApi.register(userId: guid, username: username, password: password);

  Future<SessionResult> login({required String password}) =>
      usersApi.login(userId: guid, password: password);

  Future<SessionResult> rejoin({required String password}) =>
      usersApi.rejoin(userId: guid, password: password);

  /// Logs in to an account that already exists here, found by username —
  /// the way back in for a client that no longer holds the account's UUID,
  /// e.g. after the server was removed from this device. The account's own
  /// UUID replaces this flow's generated one, so everything [persist] keys
  /// off it (the pinned certificate, the session token, the crypto store)
  /// belongs to the account that just logged in.
  Future<SessionResult> loginWithUsername(
    WidgetRef ref, {
    required String username,
    required String password,
  }) async =>
      _adopt(ref, await usersApi.login(username: username, password: password));

  /// The same, for an account that left with its data preserved.
  Future<SessionResult> rejoinWithUsername(
    WidgetRef ref, {
    required String username,
    required String password,
  }) async => _adopt(
    ref,
    await usersApi.rejoin(username: username, password: password),
  );

  /// Takes on the UUID the server answered with, refusing if this device is
  /// already connected to that account — adopting it would overwrite the
  /// existing profile's session and pinned certificate.
  SessionResult _adopt(WidgetRef ref, SessionResult session) {
    final existing = ref.read(serversControllerProvider);
    if (existing.any((s) => s.id == session.user.userId)) {
      throw const ApiException(
        409,
        'already_added',
        'This account is already added on this device. '
            'Switch to it from the server list instead.',
      );
    }
    _guid = session.user.userId;
    return session;
  }

  /// Pins the certificate fingerprint observed during this flow (only if
  /// nothing was pinned for this GUID before), stores the new session token,
  /// and registers the server with the rest of the app.
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
    ref.read(serversControllerProvider.notifier).add(profile);
    ref.read(activeServerIdProvider.notifier).select(guid);
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
  }

  void dispose() => client.close();
}
