import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/attachments_api.dart';
import '../../../core/network/channels_api.dart';
import '../../../core/network/e2ee_api.dart';
import '../../../core/network/members_api.dart';
import '../../../core/network/pin_registry.dart';
import '../../../core/network/raindrop_channel.dart';
import '../../../core/network/roles_api.dart';
import '../../../core/network/server_trust.dart';
import '../../../core/network/text_messages_api.dart';
import '../../../core/network/users_api.dart';
import '../../../core/network/voice_api.dart';
import '../../../core/storage/identity_store.dart';
import '../../../core/storage/secure_store.dart';
import '../../../core/theme/theme_controller.dart';
import '../../identity/device_sign_in.dart';
import '../../security/controllers/device_setup_controller.dart';
import 'servers_controller.dart';

/// A live, authenticated connection to one server: its profile, the pinned
/// [RaindropChannel] to it, and the account currently signed in.
///
/// The per-domain API wrappers hang off the one client rather than being
/// passed in, so adding a domain (voice signaling, a member roster) is a
/// line here and nothing at the call sites that build a session.
class ServerSession {
  ServerSession({
    required this.profile,
    required this.client,
    required this.token,
    required this.currentUser,
  });

  final ServerProfile profile;
  final RaindropChannel client;
  final String token;
  final UserProfile currentUser;

  late final UsersApi usersApi = UsersApi(client);
  late final ChannelsApi channelsApi = ChannelsApi(client);
  late final MembersApi membersApi = MembersApi(client);
  late final RolesApi rolesApi = RolesApi(client);
  late final TextMessagesApi textMessagesApi = TextMessagesApi(client);
  late final VoiceApi voiceApi = VoiceApi(client);
  late final E2eeApi e2eeApi = E2eeApi(client);
  late final AttachmentsApi attachmentsApi = AttachmentsApi(client);
}

/// Why a server's session could not be opened without the person's help, by
/// server id: an authenticator code is wanted, or the account is gone. Set
/// by [ServerSessionController] whenever it settles on `null`, and read by
/// the pane that takes the chat's place then.
final signInFailureProvider = StateProvider.family<ApiException?, String>(
  (ref, serverId) => null,
);

/// The session for a connected server, one per [ServerProfile.id].
///
/// A stored token is tried first (`UserService.GetMe`). When there is none,
/// or the server has forgotten it — sessions lapse, and a restarted server
/// forgets them all — this device signs in again with its device key, and
/// nobody is asked anything. `null` is left for the cases that genuinely
/// need the person: see [signInFailureProvider].
final serverSessionProvider =
    AsyncNotifierProvider.family<
      ServerSessionController,
      ServerSession?,
      String
    >(ServerSessionController.new);

class ServerSessionController
    extends FamilyAsyncNotifier<ServerSession?, String> {
  static const _secureStore = SecureStore();

  @override
  Future<ServerSession?> build(String serverId) async {
    final servers = ref.watch(serversControllerProvider);
    ServerProfile? profile;
    for (final s in servers) {
      if (s.id == serverId) {
        profile = s;
        break;
      }
    }
    if (profile == null) return null;

    // A session onboarding just opened ([adopt]) is the session: restoring
    // another from the same token would hand everything that follows the
    // session (device setup, the event stream, channel groups) a second one
    // while the first is still in use.
    final handedOver = _handedOver.remove(serverId);
    if (handedOver != null) {
      ref.onDispose(handedOver.client.close);
      return handedOver;
    }

    var fingerprint = await _secureStore.pinnedFingerprint(serverId);

    try {
      return await _open(profile, fingerprint);
    } on ApiException catch (e) {
      // Not reaching the server says nothing about the session: fail, so the
      // shell offers a retry (and a way to remove the server) rather than
      // claiming anything about the account.
      if (e.isNetworkError) rethrow;
      if (!e.isCertificateMismatch || fingerprint == null) return _gaveUp(e);
    }

    // The certificate changed. Follow it only if the identity key pinned for
    // this server signed the new one; otherwise the mismatch stands.
    try {
      fingerprint = await ServerTrust.followCertificateChange(
        serverId: serverId,
        host: profile.host,
        port: profile.port,
      );
      return await _open(profile, fingerprint);
    } on ApiException catch (e) {
      if (e.isNetworkError) rethrow;
      return _gaveUp(e);
    }
  }

  ServerSession? _gaveUp(ApiException reason) {
    _retryWhenRecoveryEnds(reason);
    // After the build that is running: providers may not be written to
    // while another is building.
    Future.microtask(
      () => ref.read(signInFailureProvider(arg).notifier).state = reason,
    );
    return null;
  }

  /// The stored session if the server still knows it, else a new one opened
  /// with this device's key.
  Future<ServerSession> _open(
    ServerProfile profile,
    String? fingerprint, {
    String? username,
    String? authenticatorCode,
  }) async {
    final token = await _secureStore.sessionToken(profile.id);
    if (token != null && username == null && authenticatorCode == null) {
      try {
        return await _restore(profile, token, fingerprint);
      } on ApiException catch (e) {
        if (e.code != 'invalid_session') rethrow;
        await _secureStore.clearSessionToken(profile.id);
      }
    }
    final session = await _signIn(
      profile,
      fingerprint,
      username: username,
      authenticatorCode: authenticatorCode,
    );
    ref.onDispose(session.client.close);
    return session;
  }

  /// Opens a session with the device key (see [signInWithDevice]). The
  /// caller owns the session's client: [build] closes it with the provider,
  /// and [adopt] hands it to the build that follows.
  Future<ServerSession> _signIn(
    ServerProfile profile,
    String? fingerprint, {
    String? username,
    String? authenticatorCode,
  }) async {
    final identity = await const IdentityStore().read();
    final serverKey = await _secureStore.pinnedIdentityKey(profile.id);
    if (identity == null || serverKey == null) {
      throw const ApiException(
        0,
        'no_identity',
        'This device has no identity to sign in with.',
      );
    }
    if (fingerprint != null) {
      PinRegistry.instance.pin(profile.host, profile.port, fingerprint);
    }

    final client = RaindropChannel.forServer(
      host: profile.host,
      port: profile.port,
      pinnedFingerprint: fingerprint,
    );
    try {
      final result = await signInWithDevice(
        api: UsersApi(client),
        engine: await ref.read(cryptoEngineProvider(profile.id).future),
        identity: identity,
        serverKey: serverKey,
        username: username,
        typedCode: authenticatorCode,
      );
      await _secureStore.saveSessionToken(profile.id, result.token);
      // In: any wait this device had to get in without a code is over.
      await ref.read(appPrefsProvider).setRecoveryWait(profile.id, null);
      return ServerSession(
        profile: profile,
        client: client,
        token: result.token,
        currentUser: result.user,
      );
    } on Object {
      client.close();
      rethrow;
    }
  }

  /// Signs in with what only the person can supply: an [authenticatorCode]
  /// for a device new to an account that has an authenticator, or a
  /// [username] to register again on a server that no longer has the
  /// account. Throws the [ApiException] when it is refused.
  Future<void> signInWith({String? username, String? authenticatorCode}) async {
    ServerProfile? profile;
    for (final s in ref.read(serversControllerProvider)) {
      if (s.id == arg) profile = s;
    }
    if (profile == null) return;

    final session = await _signIn(
      profile,
      await _secureStore.pinnedFingerprint(arg),
      username: username,
      authenticatorCode: authenticatorCode,
    );
    ref.read(signInFailureProvider(arg).notifier).state = null;
    adopt(session);
  }

  /// Starts this device's wait to get in without an authenticator code, for
  /// a person who has lost the authenticator and its backup codes. Returns
  /// when it ends; the session then opens by itself, if the app is running,
  /// or at the next launch.
  Future<DateTime> requestRecovery() async {
    ServerProfile? profile;
    for (final s in ref.read(serversControllerProvider)) {
      if (s.id == arg) profile = s;
    }
    final identity = await const IdentityStore().read();
    final serverKey = await _secureStore.pinnedIdentityKey(arg);
    if (profile == null || identity == null || serverKey == null) {
      throw const ApiException(
        0,
        'no_identity',
        'This device has no identity to sign in with.',
      );
    }

    final client = RaindropChannel.forServer(
      host: profile.host,
      port: profile.port,
      pinnedFingerprint: await _secureStore.pinnedFingerprint(arg),
    );
    try {
      final eligibleAt = await requestRecoveryWithDevice(
        api: UsersApi(client),
        engine: await ref.read(cryptoEngineProvider(arg).future),
        identity: identity,
        serverKey: serverKey,
      );
      await ref.read(appPrefsProvider).setRecoveryWait(arg, eligibleAt);
      final waiting = ApiException(
        0,
        'recovery_pending',
        'This device can be added without a code from $eligibleAt.',
      );
      ref.read(signInFailureProvider(arg).notifier).state = waiting;
      _retryWhenRecoveryEnds(waiting);
      return eligibleAt;
    } finally {
      client.close();
    }
  }

  Timer? _recoveryRetry;

  /// While this device waits to get in without a code, signs in again by
  /// itself the moment the wait is over.
  void _retryWhenRecoveryEnds(ApiException reason) {
    _recoveryRetry?.cancel();
    if (reason.code != 'recovery_pending') return;
    final eligibleAt = ref.read(appPrefsProvider).recoveryWaits[arg];
    if (eligibleAt == null) return;
    final delay = eligibleAt.difference(DateTime.now().toUtc());
    if (delay.isNegative) return;
    _recoveryRetry = Timer(delay + const Duration(seconds: 5), () {
      ref.read(signInFailureProvider(arg).notifier).state = null;
      ref.invalidateSelf();
    });
    ref.onDispose(() => _recoveryRetry?.cancel());
  }

  Future<ServerSession> _restore(
    ServerProfile profile,
    String token,
    String? fingerprint,
  ) async {
    // Voice connects through a library that opens its own sockets; the
    // process-wide override is how those get the same pin as this client.
    if (fingerprint != null) {
      PinRegistry.instance.pin(profile.host, profile.port, fingerprint);
    }

    final client = RaindropChannel.forServer(
      host: profile.host,
      port: profile.port,
      pinnedFingerprint: fingerprint,
    );
    ref.onDispose(client.close);
    final api = UsersApi(client);

    final me = await api.me(token);

    // Servers pinned before identity keys existed pick theirs up here, over
    // the connection the pinned certificate already vouches for.
    if (fingerprint != null) {
      try {
        await ServerTrust.pinIdentityIfMissing(
          serverId: profile.id,
          info: await api.serverInfo(),
          presentedFingerprint: fingerprint,
        );
      } on ApiException {
        // Best-effort: the next restore tries again.
      }
    }

    return ServerSession(
      profile: profile,
      client: client,
      token: token,
      currentUser: me,
    );
  }

  /// Sessions [adopt] handed over, waiting for [build] to take them.
  static final _handedOver = <String, ServerSession>{};

  /// Called once onboarding (register/login/rejoin) hands back a fresh
  /// token, so the shell picks the new session up immediately.
  ///
  /// The session goes through [build] rather than straight into `state`:
  /// a build already in flight (one restoring from the token onboarding just
  /// saved) would otherwise land afterwards and replace it with a second
  /// session on the same token. Rebuilding drops that build's result, and the
  /// new one returns this session without touching the network.
  void adopt(ServerSession session) {
    // A first connection pinned the certificate it just saw; nothing has
    // told the process-wide registry yet.
    final pinner = session.client.pinner;
    final fingerprint = pinner.pinnedFingerprint ?? pinner.observedFingerprint;
    if (fingerprint != null) {
      PinRegistry.instance.pin(
        session.profile.host,
        session.profile.port,
        fingerprint,
      );
    }
    _handedOver[arg] = session;
    ref.invalidateSelf();
  }

  /// Ends this device's session, and with [forgetDevice] takes this device
  /// off the account too — for when the server is being removed from this
  /// device, whose keys are about to be deleted and would otherwise stay
  /// listed against the account for good.
  ///
  /// Never waits on the server: it may be down, or gone, and removing it from
  /// this device has to work regardless. The calls are sent and left to
  /// finish, or not, on their own.
  Future<void> logout({bool forgetDevice = false}) async {
    final current = state.valueOrNull;
    await _secureStore.clearSessionToken(arg);
    if (current == null) return;
    state = const AsyncData(null);

    unawaited(() async {
      try {
        if (forgetDevice) {
          final device = await (await ref.read(
            cryptoEngineProvider(arg).future,
          )).device();
          if (device != null) {
            // Revoking a device ends its sessions, this one included.
            await current.e2eeApi
                .revokeDevice(current.token, device.deviceId)
                .timeout(_farewellTimeout);
            return;
          }
        }
        await current.usersApi.logout(current.token).timeout(_farewellTimeout);
      } on Object {
        // Best-effort: everything local is being discarded regardless.
      }
    }());
  }

  static const _farewellTimeout = Duration(seconds: 5);

  /// Leaves the server for good (`UserService.LeaveServer`): the account is
  /// kept, reserved but inactive, until the server's retention runs out when
  /// [preserveData] is set, and erased at once otherwise. Unlike [logout] a
  /// failure is not swallowed. There is no password to confirm with: the
  /// server takes the session being bound to one of the person's devices,
  /// and the dialog asks for this device to be unlocked first.
  /// Forgetting the server locally is the caller's next step.
  Future<LeaveResult> leave({required bool preserveData}) async {
    final current = state.valueOrNull;
    if (current == null) throw StateError('Not signed in to $arg.');
    final result = await current.usersApi.leave(
      current.token,
      password: '',
      preserveData: preserveData,
    );
    await _secureStore.clearSessionToken(current.profile.id);
    state = const AsyncData(null);
    return result;
  }
}
