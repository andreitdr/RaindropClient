import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/event_stream.dart';
import '../../servers/controllers/live_sync.dart';
import '../../servers/controllers/session_controller.dart';
import '../models/member.dart';

/// How often the roster is re-read *while the event stream is down*.
///
/// Normally the roster follows `member.joined`, `member.renamed`,
/// `member.left` and `member.presence` events (see [LiveSync]). Slower than
/// chat's fallback because a member list a few seconds behind reads as fine,
/// and this is a whole-roster query rather than one channel's newest page.
const _fallbackPollInterval = Duration(seconds: 15);

/// A connected server's member list with each member's presence, one entry
/// per server id.
///
/// Auto-disposing on purpose: the member pane is hidden below 1000px unless
/// it is toggled on, and a hidden pane has no roster to keep current.
final membersProvider = AsyncNotifierProvider.autoDispose
    .family<MembersController, List<Member>, String>(MembersController.new);

class MembersController
    extends AutoDisposeFamilyAsyncNotifier<List<Member>, String> {
  ServerSession? _session;
  bool _disposed = false;
  bool _polling = false;

  /// False until the first roster has been read; events before then are held
  /// in [_early] and applied to it.
  bool _loaded = false;
  final _early = <ServerEvent>[];

  @override
  Future<List<Member>> build(String serverId) async {
    // Riverpod reuses this instance on rebuild, so per-build state resets.
    _disposed = false;
    _loaded = false;
    _early.clear();
    ref.onDispose(() => _disposed = true);

    final session = await ref.watch(serverSessionProvider(serverId).future);
    _session = session;
    if (session == null) return const [];

    LiveSync(
      ref,
      serverId: serverId,
      onEvent: _apply,
      resync: _resync,
      fallbackPoll: _fallbackPollInterval,
    );

    var roster = await _read(session);
    _loaded = true;
    for (final event in _early) {
      roster = _applyTo(roster, event);
    }
    _early.clear();
    return roster;
  }

  void _apply(ServerEvent event) {
    final current = state.valueOrNull;
    if (!_loaded || current == null) {
      _early.add(event);
      return;
    }
    final next = _applyTo(current, event);
    if (!identical(next, current)) state = AsyncData(next);
  }

  /// One member event folded into the roster. Every one names the member it
  /// is about, and carries its state rather than a change — so applying the
  /// same one twice, or one the roster already reflects, changes nothing.
  static List<Member> _applyTo(List<Member> roster, ServerEvent event) {
    final userId = event.userId;
    if (userId == null) return roster;
    final index = roster.indexWhere((m) => m.id == userId);

    switch (event.type) {
      case ServerEventTypes.memberJoined:
        final username = event.data['username'] as String?;
        if (index >= 0 || username == null) return roster;
        // Offline until told otherwise — a `member.presence` follows as soon
        // as their first session opens.
        return [
          ...roster,
          Member(
            id: userId,
            username: username,
            presence: PresenceStatus.offline,
          ),
        ];

      case ServerEventTypes.memberRenamed:
        final username = event.data['username'] as String?;
        if (index < 0 || username == null) return roster;
        final member = roster[index];
        return [...roster]
          ..[index] = Member(
            id: member.id,
            username: username,
            presence: member.presence,
          );

      case ServerEventTypes.memberLeft:
        if (index < 0) return roster;
        return [...roster]..removeAt(index);

      case ServerEventTypes.memberPresence:
        if (index < 0) return roster;
        final member = roster[index];
        final presence = PresenceStatus.parse(
          event.data['presence'] as String?,
        );
        if (member.presence == presence) return roster;
        return [...roster]
          ..[index] = Member(
            id: member.id,
            username: member.username,
            presence: presence,
          );

      default:
        return roster;
    }
  }

  /// Re-reads the roster — after every (re)connect of the event stream, and
  /// as the fallback poll while it is down — leaving the list on screen alone
  /// if it fails: a stale member list is a better answer than an error where
  /// the member list used to be.
  Future<void> _resync() async {
    final session = _session;
    if (session == null || _polling) return;
    _polling = true;
    try {
      final roster = await _read(session);
      if (_disposed) return;
      state = AsyncData(roster);
    } on ApiException {
      // Deliberately swallowed; see above.
    } finally {
      _polling = false;
    }
  }

  /// Fetches immediately rather than waiting for the next event.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => build(arg));
  }

  Future<List<Member>> _read(ServerSession session) async {
    final summaries = await session.membersApi.list(session.token);
    return summaries.map(Member.fromSummary).toList(growable: false);
  }
}
