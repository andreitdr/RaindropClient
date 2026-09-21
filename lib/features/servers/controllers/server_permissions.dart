import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/channels_api.dart';
import '../../../core/network/event_stream.dart';
import '../../../core/network/roles_api.dart';
import 'live_sync.dart';
import 'session_controller.dart';

/// What the signed-in account may do on a server as a whole, from
/// `GET /api/roles/me`, one entry per server id, and kept current by the
/// event stream: any role event re-reads it.
///
/// Per-channel permissions are not here — they ride on each channel
/// (`Channel.canRename`, …). This is only for what is not about any one
/// channel, which today is creating one. Null means "not known" — signed
/// out, or a server too old to have the endpoint — and every answer built on
/// it errs towards hiding the control rather than offering something the
/// server may refuse.
final serverPermissionsProvider =
    AsyncNotifierProvider.family<ServerPermissionsController, MyRoles?, String>(
      ServerPermissionsController.new,
    );

/// Whether [roles] lets the account create channels on the server.
bool canCreateChannels(MyRoles? roles) =>
    roles?.can(ChannelPermissionNames.createChannels) ?? false;

class ServerPermissionsController
    extends FamilyAsyncNotifier<MyRoles?, String> {
  ServerSession? _session;
  bool _resyncing = false;

  /// False until the first read has finished. A role event seen before then
  /// may or may not be reflected in what was read, so it earns one more read.
  bool _loaded = false;
  bool _changedWhileLoading = false;

  @override
  Future<MyRoles?> build(String serverId) async {
    // Riverpod reuses this instance on rebuild, so per-build state resets.
    _loaded = false;
    _changedWhileLoading = false;

    final session = await ref.watch(serverSessionProvider(serverId).future);
    _session = session;
    if (session == null) return null;

    LiveSync(ref, serverId: serverId, onEvent: _apply, resync: _resync);

    final roles = await _read(session);
    _loaded = true;
    if (_changedWhileLoading) Future.microtask(_resync);
    return roles;
  }

  void _apply(ServerEvent event) {
    if (!_changesPermissions(event)) return;
    if (_loaded) {
      _resync();
    } else {
      _changedWhileLoading = true;
    }
  }

  static bool _changesPermissions(ServerEvent event) => switch (event.type) {
    ServerEventTypes.roleCreated ||
    ServerEventTypes.roleUpdated ||
    ServerEventTypes.roleDeleted ||
    ServerEventTypes.memberRoles => true,
    _ => false,
  };

  Future<void> _resync() async {
    final session = _session;
    if (session == null || _resyncing) return;
    _resyncing = true;
    try {
      final roles = await _read(session);
      // A read that failed keeps what is on screen; the next event or
      // reconnect tries again.
      if (roles != null) state = AsyncData(roles);
    } finally {
      _resyncing = false;
    }
  }

  Future<MyRoles?> _read(ServerSession session) async {
    try {
      return await session.rolesApi.me(session.token);
    } on ApiException {
      return null;
    }
  }
}
