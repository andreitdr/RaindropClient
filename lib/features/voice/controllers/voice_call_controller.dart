import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/event_stream.dart';
import '../../../core/network/voice_api.dart';
import '../../../core/voice/voice_engine.dart';
import '../../servers/controllers/server_events.dart';
import '../../servers/controllers/session_controller.dart';
import '../models/member_audio.dart';
import '../models/voice_settings.dart';
import 'member_audio_controller.dart';
import 'voice_roster_controller.dart';
import 'voice_settings_controller.dart';

enum VoiceCallStatus { idle, joining, connected, reconnecting }

/// The one call this client is in, if any — across every server, since a
/// person has one pair of ears.
class VoiceCallState {
  const VoiceCallState({
    this.serverId,
    this.channelId,
    this.status = VoiceCallStatus.idle,
    this.speaking = const {},
    this.serverMuted = false,
    this.suppressed = false,
    this.notice,
  });

  final String? serverId;
  final String? channelId;
  final VoiceCallStatus status;

  /// The member UUIDs talking right now, this client's included.
  final Set<String> speaking;

  /// A moderator muted this member for everyone.
  final bool serverMuted;

  /// This member may only listen in this call: they lack `speak`.
  final bool suppressed;

  /// Why the last call ended, when it was not this client's own choice —
  /// shown once, then cleared with [VoiceCallController.dismissNotice].
  final String? notice;

  bool get inCall => status != VoiceCallStatus.idle;

  bool isIn(String serverId, String channelId) =>
      inCall && this.serverId == serverId && this.channelId == channelId;

  VoiceCallState copyWith({
    VoiceCallStatus? status,
    Set<String>? speaking,
    bool? serverMuted,
    bool? suppressed,
  }) => VoiceCallState(
    serverId: serverId,
    channelId: channelId,
    status: status ?? this.status,
    speaking: speaking ?? this.speaking,
    serverMuted: serverMuted ?? this.serverMuted,
    suppressed: suppressed ?? this.suppressed,
    notice: notice,
  );
}

/// The server named a media transport this build cannot speak.
class UnsupportedVoiceTransportException implements Exception {
  const UnsupportedVoiceTransportException(this.transport);

  final String transport;

  @override
  String toString() =>
      'This server carries calls over "$transport", which this version of '
      'Raindrop does not support. Updating the app may help.';
}

final voiceCallProvider = NotifierProvider<VoiceCallController, VoiceCallState>(
  VoiceCallController.new,
);

/// Joins, runs and leaves the call, and keeps its audio in step with the
/// settings: mute, deafen, output volume, per-member volume and devices.
///
/// Not auto-disposed, and it follows the session with `ref.listen` rather
/// than `watch`: editing a server's nickname rebuilds its session, and a
/// watch would tear the call down with it. The call ends when the session
/// really ends — signed out, or a different token.
class VoiceCallController extends Notifier<VoiceCallState> {
  VoiceEngine? _engine;
  ServerSession? _session;
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _watches = <ProviderSubscription<Object?>>[];

  /// Bumped whenever a call starts or ends, so an answer to an older join
  /// that arrives late cannot resurrect it.
  int _generation = 0;

  @override
  VoiceCallState build() {
    ref.listen(voiceSettingsProvider, _onSettingsChanged);
    ref.listen(memberAudioProvider, (_, _) => _applyVolumes());
    ref.onDispose(_teardown);
    return const VoiceCallState();
  }

  /// Joins [channelId] on [serverId], leaving any other call first. Throws
  /// the server's [ApiException] (`channel_full`, `missing_permission`,
  /// `voice_unavailable`) or [UnsupportedVoiceTransportException] for the
  /// caller to show.
  Future<void> join(String serverId, String channelId) async {
    if (state.isIn(serverId, channelId)) return;
    await leave();

    final generation = ++_generation;
    final session = await ref.read(serverSessionProvider(serverId).future);
    if (session == null) throw StateError('Not signed in to this server.');
    if (generation != _generation) return;

    state = VoiceCallState(
      serverId: serverId,
      channelId: channelId,
      status: VoiceCallStatus.joining,
    );

    final settings = ref.read(voiceSettingsProvider);
    final VoiceJoinResult joined;
    try {
      joined = await session.voiceApi.join(
        session.token,
        channelId: channelId,
        selfMute: !settings.micOn,
        selfDeaf: settings.selfDeaf,
      );
    } on Object {
      if (generation == _generation) state = const VoiceCallState();
      rethrow;
    }

    if (generation != _generation) {
      unawaited(_leaveQuietly(session, channelId));
      return;
    }

    final engine = createVoiceEngine(joined.transport);
    if (engine == null) {
      state = const VoiceCallState();
      unawaited(_leaveQuietly(session, channelId));
      throw UnsupportedVoiceTransportException(joined.transport);
    }

    _engine = engine;
    _session = session;
    state = state.copyWith(
      serverMuted: joined.you.serverMute,
      suppressed: joined.you.suppressed,
    );
    _follow(serverId, session, engine);

    // Set before connecting, so the first audio to arrive already plays at
    // the right volume.
    _applyVolumes();

    try {
      await engine.connect(
        joined.signalUri(
          host: session.profile.host,
          port: session.profile.port,
        ),
        joined.token,
        micEnabled: settings.micOn,
        processing: settings.processing,
        inputDeviceId: settings.inputDeviceId,
        outputDeviceId: settings.outputDeviceId,
      );
    } on Object {
      if (generation == _generation) {
        await _end(notice: 'Could not connect to the call.');
      }
      rethrow;
    }

    if (generation == _generation && state.status == VoiceCallStatus.joining) {
      state = state.copyWith(status: VoiceCallStatus.connected);
    }
  }

  /// Hangs up. Safe to call when not in a call.
  Future<void> leave() async {
    if (!state.inCall) return;
    await _end();
  }

  void dismissNotice() {
    if (!state.inCall && state.notice != null) state = const VoiceCallState();
  }

  // ── Following the call ─────────────────────────────────────────────────────

  void _follow(String serverId, ServerSession session, VoiceEngine engine) {
    _subscriptions
      ..add(
        engine.activeSpeakers.listen(
          (speakers) => state = state.copyWith(speaking: speakers),
        ),
      )
      ..add(
        engine.connectionStates.listen((connection) {
          if (!state.inCall) return;
          switch (connection) {
            case VoiceConnectionState.reconnecting:
              state = state.copyWith(status: VoiceCallStatus.reconnecting);
            case VoiceConnectionState.connected:
              state = state.copyWith(status: VoiceCallStatus.connected);
            case VoiceConnectionState.connecting:
            case VoiceConnectionState.disconnected:
          }
        }),
      )
      ..add(engine.disconnects.listen(_onEngineDisconnected));

    final events = ref.read(serverEventsProvider(serverId));
    if (events != null) {
      _subscriptions.add(events.events.listen(_onServerEvent));
    }

    _watches
      ..add(
        ref.listen<AsyncValue<ServerSession?>>(
          serverSessionProvider(serverId),
          (_, next) {
            if (next.isLoading) return;
            final current = next.valueOrNull;
            if (current == null || current.token != session.token) {
              unawaited(
                _end(
                  notice: 'You were signed out of this server.',
                  reportLeave: false,
                ),
              );
            } else {
              // Same session, rebuilt (a renamed server): keep using the live
              // client — the old one was closed with the old instance.
              _session = current;
            }
          },
        ),
      )
      ..add(
        ref.listen<AsyncValue<VoiceRoster>>(
          voiceRosterProvider(serverId),
          (_, _) => _applyVolumes(),
        ),
      );
  }

  void _onServerEvent(ServerEvent event) {
    final me = _session?.currentUser.userId;
    if (me == null ||
        event.userId != me ||
        event.channelId != state.channelId) {
      return;
    }

    switch (event.type) {
      case ServerEventTypes.voiceState:
        final you = VoiceParticipant.fromJson(event.data);
        state = state.copyWith(
          serverMuted: you.serverMute,
          suppressed: you.suppressed,
        );

      case ServerEventTypes.voiceLeft:
        final left = VoiceLeft.fromJson(event.data);
        unawaited(_end(notice: _noticeFor(left.reason), reportLeave: false));
    }
  }

  void _onEngineDisconnected(VoiceDisconnectReason reason) {
    if (!state.inCall) return;
    switch (reason) {
      case VoiceDisconnectReason.clientInitiated:
        return;
      case VoiceDisconnectReason.replacedByOtherDevice:
        unawaited(
          _end(
            notice: 'You joined this call from another device.',
            reportLeave: false,
          ),
        );
      case VoiceDisconnectReason.removedByServer:
        unawaited(
          _end(notice: 'You were removed from the call.', reportLeave: false),
        );
      case VoiceDisconnectReason.callEnded:
        unawaited(_end(notice: 'The call ended.', reportLeave: false));
      case VoiceDisconnectReason.networkFailure:
      case VoiceDisconnectReason.unknown:
        unawaited(_end(notice: 'Lost the connection to the call.'));
    }
  }

  static String? _noticeFor(String reason) => switch (reason) {
    VoiceLeaveReasons.left => null,
    VoiceLeaveReasons.moved => 'You joined another call from another device.',
    VoiceLeaveReasons.permissionLost =>
      'You can no longer join that channel, so you left the call.',
    VoiceLeaveReasons.sessionEnded => 'You were signed out of this server.',
    VoiceLeaveReasons.channelDeleted => 'The channel was deleted.',
    VoiceLeaveReasons.serverEnded => 'The server ended the call.',
    VoiceLeaveReasons.disconnected => 'Lost the connection to the call.',
    _ => 'You left the call.',
  };

  // ── Keeping the audio in step with settings ────────────────────────────────

  void _onSettingsChanged(VoiceSettings? previous, VoiceSettings next) {
    final engine = _engine;
    final session = _session;
    if (engine == null || session == null || previous == null) return;

    if (previous.micOn != next.micOn) {
      unawaited(engine.setMicEnabled(next.micOn));
    }

    if (previous.selfMute != next.selfMute ||
        previous.selfDeaf != next.selfDeaf) {
      unawaited(_report(session, next));
    }

    if (previous.selfDeaf != next.selfDeaf ||
        previous.outputVolume != next.outputVolume) {
      _applyVolumes();
    }

    if (previous.processing != next.processing) {
      unawaited(engine.applyProcessing(next.processing));
    }

    if (next.inputDeviceId case final input?
        when input != previous.inputDeviceId) {
      unawaited(engine.setInputDevice(input));
    }

    if (next.outputDeviceId case final output?
        when output != previous.outputDeviceId) {
      unawaited(engine.setOutputDevice(output));
    }
  }

  /// Tells everybody else this client muted or deafened — the icon next to
  /// its name. The audio itself already stopped locally.
  Future<void> _report(ServerSession session, VoiceSettings settings) async {
    try {
      await session.voiceApi.setSelfState(
        session.token,
        selfMute: !settings.micOn,
        selfDeaf: settings.selfDeaf,
      );
    } on ApiException {
      // Not in the call any more (the event saying so is on its way), or the
      // server is unreachable; either way nothing to do here.
    }
  }

  /// Every remote member's volume: silent while deafened or locally muted,
  /// otherwise their own volume scaled by the output volume.
  void _applyVolumes() {
    final engine = _engine;
    final serverId = state.serverId;
    final channelId = state.channelId;
    if (engine == null || serverId == null || channelId == null) return;

    final settings = ref.read(voiceSettingsProvider);
    final audio = ref.read(memberAudioProvider.notifier);
    final me = _session?.currentUser.userId;

    unawaited(
      engine.setDefaultVolume(
        effectiveVolume(
          outputVolume: settings.outputVolume,
          member: const MemberAudio(),
          deafened: settings.selfDeaf,
        ),
      ),
    );

    final roster = ref.read(voiceRosterProvider(serverId)).valueOrNull;
    for (final participant in roster?.inChannel(channelId) ?? const []) {
      if (participant.userId == me) continue;
      unawaited(
        engine.setParticipantVolume(
          participant.userId,
          effectiveVolume(
            outputVolume: settings.outputVolume,
            member: audio.of(serverId, participant.userId),
            deafened: settings.selfDeaf,
          ),
        ),
      );
    }
  }

  // ── Ending ─────────────────────────────────────────────────────────────────

  Future<void> _end({String? notice, bool reportLeave = true}) async {
    _generation++;
    final session = _session;
    final channelId = state.channelId;

    _teardown();
    state = VoiceCallState(notice: notice);

    if (reportLeave && session != null && channelId != null) {
      await _leaveQuietly(session, channelId);
    }
  }

  static Future<void> _leaveQuietly(
    ServerSession session,
    String channelId,
  ) async {
    try {
      await session.voiceApi.leave(session.token, channelId: channelId);
    } on ApiException {
      // Already out, or the server is unreachable — its reconciler drops a
      // participant whose audio is gone either way.
    }
  }

  void _teardown() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    for (final watch in _watches) {
      watch.close();
    }
    _watches.clear();

    final engine = _engine;
    _engine = null;
    _session = null;
    if (engine != null) unawaited(engine.dispose());
  }
}
