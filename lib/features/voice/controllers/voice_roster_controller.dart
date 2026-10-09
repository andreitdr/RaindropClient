import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/event_stream.dart';
import '../../../core/network/voice_api.dart';
import '../../servers/controllers/live_sync.dart';
import '../../servers/controllers/session_controller.dart';

/// Who is in every call on one server — what the sidebar draws under each
/// voice channel and the voice view draws as tiles — and whether voice works
/// there at all.
class VoiceRoster {
  const VoiceRoster({
    required this.available,
    required this.transport,
    required this.maximumParticipants,
    required this.byChannel,
    this.maximumCameraPublishers = 0,
    this.maximumScreenShares = 0,
  });

  static const empty = VoiceRoster(
    available: false,
    transport: 'none',
    maximumParticipants: 0,
    byChannel: {},
  );

  final bool available;
  final String transport;
  final int maximumParticipants;

  /// How many members of one call may send their camera at once. 0 when this
  /// server carries no camera video at all.
  final int maximumCameraPublishers;

  /// How many members of one call may share their screen at once. 0 when this
  /// server carries no screen sharing.
  final int maximumScreenShares;

  /// Each call's participants, in the order they joined.
  final Map<String, List<VoiceParticipant>> byChannel;

  List<VoiceParticipant> inChannel(String channelId) =>
      byChannel[channelId] ?? const [];

  factory VoiceRoster.fromStatus(VoiceStatus status) {
    final byChannel = <String, List<VoiceParticipant>>{};
    for (final p in status.participants) {
      (byChannel[p.channelId] ??= []).add(p);
    }
    return VoiceRoster(
      available: status.available,
      transport: status.transport,
      maximumParticipants: status.maximumParticipants,
      maximumCameraPublishers: status.maximumCameraPublishers,
      maximumScreenShares: status.maximumScreenShares,
      byChannel: byChannel,
    );
  }

  /// Puts [participant] in their call — taking them out of any other, since
  /// a member is in one call at a time.
  VoiceRoster upsert(VoiceParticipant participant) {
    final next = <String, List<VoiceParticipant>>{};
    for (final entry in byChannel.entries) {
      final rest = [
        for (final p in entry.value)
          if (p.userId != participant.userId) p,
      ];
      if (rest.isNotEmpty) next[entry.key] = rest;
    }
    next[participant.channelId] = [...?next[participant.channelId], participant]
      ..sort((a, b) => a.joinedAtUtc.compareTo(b.joinedAtUtc));
    return _with(next);
  }

  VoiceRoster remove(String channelId, String userId) {
    final current = byChannel[channelId];
    if (current == null) return this;
    final rest = [
      for (final p in current)
        if (p.userId != userId) p,
    ];
    return _with({
      for (final entry in byChannel.entries)
        if (entry.key != channelId) entry.key: entry.value,
      if (rest.isNotEmpty) channelId: rest,
    });
  }

  VoiceRoster removeChannel(String channelId) => _with({
    for (final entry in byChannel.entries)
      if (entry.key != channelId) entry.key: entry.value,
  });

  VoiceRoster _with(Map<String, List<VoiceParticipant>> byChannel) =>
      VoiceRoster(
        available: available,
        transport: transport,
        maximumParticipants: maximumParticipants,
        maximumCameraPublishers: maximumCameraPublishers,
        maximumScreenShares: maximumScreenShares,
        byChannel: byChannel,
      );
}

/// One server's [VoiceRoster], read from `VoiceService.GetVoiceStatus` and kept
/// current by `voice.state` / `voice.left`. A deleted channel takes its call
/// with it, and a role change — which can change which calls this account
/// sees — re-reads the whole thing.
final voiceRosterProvider =
    AsyncNotifierProvider.family<VoiceRosterController, VoiceRoster, String>(
      VoiceRosterController.new,
    );

class VoiceRosterController extends FamilyAsyncNotifier<VoiceRoster, String> {
  ServerSession? _session;
  bool _resyncing = false;
  bool _loaded = false;
  final _early = <ServerEvent>[];

  @override
  Future<VoiceRoster> build(String serverId) async {
    _loaded = false;
    _early.clear();

    final session = await ref.watch(serverSessionProvider(serverId).future);
    _session = session;
    if (session == null) return VoiceRoster.empty;

    // Polled while the stream is down, like the member list: who is in a
    // call changes often and is on screen the whole time.
    LiveSync(
      ref,
      serverId: serverId,
      onEvent: _apply,
      resync: _resync,
      fallbackPoll: const Duration(seconds: 15),
    );

    var roster = await _read(session);
    _loaded = true;
    for (final event in _early) {
      roster = _applyTo(roster, event) ?? roster;
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
    if (next != null) {
      state = AsyncData(next);
    } else if (_changesPermissions(event)) {
      _resync();
    }
  }

  static VoiceRoster? _applyTo(VoiceRoster roster, ServerEvent event) {
    try {
      return switch (event.type) {
        ServerEventTypes.voiceState => roster.upsert(
          VoiceParticipant.fromProto(event.proto.voiceState),
        ),
        ServerEventTypes.voiceLeft => roster.remove(
          event.channelId ?? '',
          event.userId ?? '',
        ),
        ServerEventTypes.channelDeleted => roster.removeChannel(
          event.channelId ?? '',
        ),
        _ => null,
      };
    } on Object {
      return null;
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
      state = AsyncData(await _read(session));
    } on ApiException {
      // Keep what is showing; the next event or reconnect tries again.
    } finally {
      _resyncing = false;
    }
  }

  Future<VoiceRoster> _read(ServerSession session) async {
    try {
      return VoiceRoster.fromStatus(
        await session.voiceApi.status(session.token),
      );
    } on ApiException catch (e) {
      // A server without the voice service: nothing to show, nothing to join.
      if (e.code == 'unimplemented') return VoiceRoster.empty;
      rethrow;
    }
  }
}
