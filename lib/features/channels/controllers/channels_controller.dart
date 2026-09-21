import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/channels_api.dart';
import '../../../core/network/event_stream.dart';
import '../../servers/controllers/live_sync.dart';
import '../../servers/controllers/session_controller.dart';
import '../models/channel.dart';

/// A connected server's channel list, fetched from `GET /api/channels`, one
/// entry per server id, and kept current by the event stream: channels
/// created, renamed or deleted anywhere arrive as events, and a role change —
/// which can change which channels this account sees, and what it may do in
/// them — re-reads the list.
final channelsProvider =
    AsyncNotifierProvider.family<ChannelsController, List<Channel>, String>(
      ChannelsController.new,
    );

class ChannelsController extends FamilyAsyncNotifier<List<Channel>, String> {
  ServerSession? _session;
  bool _resyncing = false;

  /// False until the first list has been read; events before then are held
  /// in [_early] and applied to it.
  bool _loaded = false;
  final _early = <ServerEvent>[];

  @override
  Future<List<Channel>> build(String serverId) async {
    // Riverpod reuses this instance on rebuild, so per-build state resets.
    _loaded = false;
    _early.clear();

    // Re-fetches on its own when the session changes — signing out empties
    // the list, signing back in refills it.
    final session = await ref.watch(serverSessionProvider(serverId).future);
    _session = session;
    if (session == null) return const [];

    // No fallback poll: the list changes rarely, and it never polled before
    // there was a stream. A reconnect re-reads it anyway.
    LiveSync(ref, serverId: serverId, onEvent: _apply, resync: _resync);

    var channels = await _read(session);
    _loaded = true;
    // A role change seen while loading may or may not be reflected in what
    // was just read, so it earns one more read once the list is showing.
    var reread = false;
    for (final event in _early) {
      channels = _applyTo(channels, event) ?? channels;
      reread |= _changesPermissions(event);
    }
    _early.clear();
    if (reread) Future.microtask(_resync);
    return channels;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => build(arg));
  }

  // ── Changing channels ────────────────────────────────────────────────────
  //
  // Each of these throws the server's [ApiException] for the caller to show,
  // and folds the answer into the list itself rather than waiting for the
  // echoed `channel.*` event. The event arrives too — the server tells the
  // member who caused a change as well — and merges on id, so the two cannot
  // leave a channel showing twice.

  /// Creates a channel called [name] — text unless [type] says otherwise —
  /// and returns it as the server made it. Needs the server-wide
  /// `create_channels` permission.
  Future<Channel> create(
    String name, {
    ChannelType type = ChannelType.text,
  }) async {
    final session = _requireSession();
    final channel = Channel.fromSummary(
      await session.channelsApi.create(
        session.token,
        name: name,
        type: type == ChannelType.voice
            ? ChannelTypeNames.voice
            : ChannelTypeNames.text,
      ),
    );
    _upsert(channel);
    return channel;
  }

  /// Renames the channel with [channelId]. Needs `rename_channels` in it.
  Future<void> rename(String channelId, String name) async {
    final session = _requireSession();
    _upsert(
      Channel.fromSummary(
        await session.channelsApi.rename(
          session.token,
          channelId: channelId,
          name: name,
        ),
      ),
    );
  }

  /// Deletes the channel with [channelId] and every message in it. Needs
  /// `delete_channels` in it. If it was the selected channel, the shell falls
  /// back to another one by itself — see `resolveChannel`.
  Future<void> delete(String channelId) async {
    final session = _requireSession();
    await session.channelsApi.delete(session.token, channelId: channelId);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final c in current)
        if (c.id != channelId) c,
    ]);
  }

  ServerSession _requireSession() =>
      _session ?? (throw StateError('Not signed in to this server.'));

  void _upsert(Channel channel) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      _sorted([
        for (final c in current)
          if (c.id != channel.id) c,
        channel,
      ]),
    );
  }

  void _apply(ServerEvent event) {
    final current = state.valueOrNull;
    if (!_loaded || current == null) {
      _early.add(event);
      return;
    }

    final next = _applyTo(current, event);
    if (next != null) {
      state = AsyncData(next);
    } else if (_changesPermissions(event)) {
      _resync();
    }
  }

  /// Folds a channel event into [channels], or answers null for an event
  /// that is not about a single channel.
  static List<Channel>? _applyTo(List<Channel> channels, ServerEvent event) {
    switch (event.type) {
      case ServerEventTypes.channelCreated:
      case ServerEventTypes.channelRenamed:
        final Channel channel;
        try {
          // The server sends each member the channel as *they* see it, with
          // their own permissions, so this is exactly the row a re-read gives.
          channel = Channel.fromSummary(ChannelSummary.fromJson(event.data));
        } on Object {
          return null;
        }
        return _sorted([
          for (final c in channels)
            if (c.id != channel.id) c,
          channel,
        ]);

      case ServerEventTypes.channelDeleted:
        final id = event.channelId;
        return [
          for (final c in channels)
            if (c.id != id) c,
        ];

      default:
        return null;
    }
  }

  /// Role events are not about one channel, but can change which channels
  /// this account sees and what it may do in them. Working that out here
  /// would be re-deriving the server's resolver, so the list is re-read.
  static bool _changesPermissions(ServerEvent event) => switch (event.type) {
    ServerEventTypes.roleCreated ||
    ServerEventTypes.roleUpdated ||
    ServerEventTypes.roleDeleted ||
    ServerEventTypes.memberRoles => true,
    _ => false,
  };

  /// The server orders the list by name; keep an event-built list the same.
  static List<Channel> _sorted(List<Channel> channels) =>
      channels
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Future<void> _resync() async {
    final session = _session;
    if (session == null || _resyncing) return;
    _resyncing = true;
    try {
      state = AsyncData(await _read(session));
    } on ApiException {
      // Leave the list on screen; the next event or reconnect tries again.
    } finally {
      _resyncing = false;
    }
  }

  Future<List<Channel>> _read(ServerSession session) async {
    final summaries = await session.channelsApi.list(session.token);
    return summaries.map(Channel.fromSummary).toList(growable: false);
  }
}
