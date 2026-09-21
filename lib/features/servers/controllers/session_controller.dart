import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/channels_api.dart';
import '../../../core/network/members_api.dart';
import '../../../core/network/pin_registry.dart';
import '../../../core/network/roles_api.dart';
import '../../../core/network/text_messages_api.dart';
import '../../../core/network/users_api.dart';
import '../../../core/network/voice_api.dart';
import '../../../core/storage/secure_store.dart';
import 'servers_controller.dart';

/// A live, authenticated connection to one server: its profile, the pinned
/// [ApiClient] for it, and the account currently signed in.
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
  final ApiClient client;
  final String token;
  final UserProfile currentUser;

  late final UsersApi usersApi = UsersApi(client);
  late final ChannelsApi channelsApi = ChannelsApi(client);
  late final MembersApi membersApi = MembersApi(client);
  late final RolesApi rolesApi = RolesApi(client);
  late final TextMessagesApi textMessagesApi = TextMessagesApi(client);
  late final VoiceApi voiceApi = VoiceApi(client);
}

/// Resolves whether we already have a valid session for a connected server
/// (token in SecureStore, verified against `/api/users/me`), one per
/// [ServerProfile.id]. `null` means "not signed in here" — the shell routes
/// to the onboarding login/register flow for that server instead.
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

    final token = await _secureStore.sessionToken(serverId);
    if (token == null) return null;

    final fingerprint = await _secureStore.pinnedFingerprint(serverId);

    // Voice connects through a library that opens its own sockets; the
    // process-wide override is how those get the same pin as this client.
    if (fingerprint != null) {
      PinRegistry.instance.pin(profile.host, profile.port, fingerprint);
    }

    final client = ApiClient.forServer(
      host: profile.host,
      port: profile.port,
      pinnedFingerprint: fingerprint,
    );
    ref.onDispose(client.close);
    final api = UsersApi(client);

    try {
      final me = await api.me(token);
      return ServerSession(
        profile: profile,
        client: client,
        token: token,
        currentUser: me,
      );
    } on ApiException catch (e) {
      if (e.code == 'invalid_session') {
        await _secureStore.clearSessionToken(serverId);
      }
      return null;
    }
  }

  /// Called once onboarding (register/login/rejoin) hands back a fresh
  /// token, so the shell picks the new session up immediately.
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
    state = AsyncData(session);
  }

  Future<void> logout() async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      await current.usersApi.logout(current.token);
    } on ApiException {
      // Best-effort: the token is being discarded locally regardless.
    }
    await _secureStore.clearSessionToken(current.profile.id);
    state = const AsyncData(null);
  }
}
