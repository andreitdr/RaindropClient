import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_info.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/e2ee_api.dart';
import '../../../core/network/event_stream.dart';
import '../../../core/network/voice_api.dart';
import '../../../core/voice/voice_engine.dart';
import '../../security/controllers/channel_groups.dart';
import '../../servers/controllers/server_events.dart';
import '../../servers/controllers/session_controller.dart';
import '../models/member_media.dart';
import '../models/voice_settings.dart';
import 'member_media_controller.dart';
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
    this.warning,
    this.encryption = VoiceEncryption.none,
    this.cameraOn = false,
    this.cameraSuppressed = false,
    this.cameraBusy = false,
    this.videoAvailable = false,
    this.videoFeeds = const [],
    this.untrustedVideo = const {},
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

  /// Something the engine refused during a call that is still going: media it
  /// could not encrypt, an effect it had to turn off. Separate from [notice],
  /// which is specifically why a call *ended* — this one leaves the call
  /// running, so conflating them would read as a hang-up that did not happen.
  /// Cleared with [VoiceCallController.dismissWarning].
  final String? warning;

  bool get inCall => status != VoiceCallStatus.idle;

  bool isIn(String serverId, String channelId) =>
      inCall && this.serverId == serverId && this.channelId == channelId;

  /// Whether this call's audio is end-to-end encrypted, for the lock in the
  /// call UI.
  final VoiceEncryption encryption;

  /// This client is sending its camera.
  final bool cameraOn;

  /// The camera cannot be turned on: no `video` permission, or every camera
  /// place in the call is taken.
  final bool cameraSuppressed;

  /// A camera is being turned on or off right now — the handshake with the
  /// server and the media server is in flight. The button shows a spinner and
  /// refuses a second tap, which would otherwise race the first.
  final bool cameraBusy;

  /// This server carries camera video at all (`voice.video.v1`). False hides
  /// the camera button rather than offering one that always fails.
  final bool videoAvailable;

  /// Every camera in the call, this client's own first. The whole list is
  /// replaced on every change.
  final List<VoiceVideoFeed> videoFeeds;

  /// Participants whose camera arrived unencrypted or stopped decrypting.
  /// Their tile says so; nothing untrusted is ever drawn.
  final Set<String> untrustedVideo;

  /// The feed for one member, or null when they are not sending a camera this
  /// client is receiving — because they have it off, it is hidden here, or it
  /// is not trusted.
  VoiceVideoFeed? feedFor(String userId) =>
      videoFeeds.where((feed) => feed.identity == userId).firstOrNull;

  /// [warning] takes a nullary function rather than a plain value so a
  /// warning can be *cleared*, which a `??` fallback could never express.
  VoiceCallState copyWith({
    VoiceCallStatus? status,
    Set<String>? speaking,
    bool? serverMuted,
    bool? suppressed,
    String? Function()? warning,
    VoiceEncryption? encryption,
    bool? cameraOn,
    bool? cameraSuppressed,
    bool? cameraBusy,
    bool? videoAvailable,
    List<VoiceVideoFeed>? videoFeeds,
    Set<String>? untrustedVideo,
  }) => VoiceCallState(
    serverId: serverId,
    channelId: channelId,
    status: status ?? this.status,
    speaking: speaking ?? this.speaking,
    serverMuted: serverMuted ?? this.serverMuted,
    suppressed: suppressed ?? this.suppressed,
    notice: notice,
    warning: warning == null ? this.warning : warning(),
    encryption: encryption ?? this.encryption,
    cameraOn: cameraOn ?? this.cameraOn,
    cameraSuppressed: cameraSuppressed ?? this.cameraSuppressed,
    cameraBusy: cameraBusy ?? this.cameraBusy,
    videoAvailable: videoAvailable ?? this.videoAvailable,
    videoFeeds: videoFeeds ?? this.videoFeeds,
    untrustedVideo: untrustedVideo ?? this.untrustedVideo,
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

/// The call could not be end-to-end encrypted on a server that requires it,
/// so it was not joined.
class VoiceEncryptionUnavailableException implements Exception {
  const VoiceEncryptionUnavailableException(this.reason);

  final String reason;

  @override
  String toString() => 'This call could not be end-to-end encrypted: $reason';
}

/// How often the voice channel's group moves to a new epoch — a new media key
/// — during a call, so a key that leaks exposes at most this much audio.
const _rekeyInterval = Duration(minutes: 10);

/// How long to wait for the media server to accept a camera after the server
/// has been told it is on. Long enough for a relayed round trip on a slow
/// connection, short enough that a user does not sit watching a dead button.
const _cameraGrantTimeout = Duration(seconds: 5);

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
  ChannelGroups? _groups;
  Timer? _rekey;

  /// Bumped whenever a call starts or ends, so an answer to an older join
  /// that arrives late cannot resurrect it.
  int _generation = 0;

  @override
  VoiceCallState build() {
    ref.listen(voiceSettingsProvider, _onSettingsChanged);
    ref.listen(memberAudioProvider, (_, _) {
      _applyVolumes();
      _applyVideoVisibility();
    });

    // Backgrounding a phone stops the camera at the OS level anyway, and
    // everybody else is left looking at a frozen frame. Turning it off
    // properly reports it, so their tile reverts instead. Desktop is left
    // alone: a hidden window is still a live camera there, and stopping it
    // silently would surprise.
    if (isMobilePlatform) {
      final lifecycle = AppLifecycleListener(
        onHide: () => unawaited(setCameraEnabled(false)),
      );
      ref.onDispose(lifecycle.dispose);
    }

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

    // The media key comes first, before the server lists this device in the
    // call: on a server whose calls are end-to-end encrypted, a device that
    // cannot encrypt does not join at all.
    VoiceMediaKey? mediaKey;
    ChannelGroups? groups;
    var videoAvailable = false;
    try {
      final info = await session.usersApi.serverInfo();
      videoAvailable = info.capabilities.contains(voiceVideoCapability);
      if (info.capabilities.contains(e2eeVoiceCapability)) {
        groups = await ref.read(channelGroupsProvider(serverId).future);
        if (groups == null) {
          throw const VoiceEncryptionUnavailableException(
            'this device is not set up for encryption on this server.',
          );
        }
        final key = await groups.mediaKey(channelId);
        mediaKey = VoiceMediaKey(key: key.key, index: key.index);
      }
    } on VoiceEncryptionUnavailableException {
      if (generation == _generation) state = const VoiceCallState();
      rethrow;
    } on Object catch (e) {
      if (generation == _generation) state = const VoiceCallState();
      throw VoiceEncryptionUnavailableException('$e');
    }
    if (generation != _generation) return;

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
    _groups = groups;
    state = state.copyWith(
      serverMuted: joined.you.serverMute,
      suppressed: joined.you.suppressed,
      cameraSuppressed: joined.you.cameraSuppressed,
      videoAvailable: videoAvailable,
    );
    _follow(serverId, session, engine);

    // Set before connecting, so the first audio to arrive already plays at
    // the right volume, and a camera hidden earlier is never received at all.
    _applyVolumes();
    _applyVideoVisibility();

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
        mediaKey: mediaKey,
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

    // The group may have moved on while connecting; make sure the call
    // starts on the current key.
    if (generation == _generation && groups != null) {
      unawaited(_refreshMediaKey(groups, channelId));
    }
  }

  /// Hangs up. Safe to call when not in a call.
  Future<void> _refreshMediaKey(ChannelGroups groups, String channelId) async {
    try {
      final key = await groups.mediaKey(channelId);
      await _engine?.setMediaKey(VoiceMediaKey(key: key.key, index: key.index));
    } on Object catch (e) {
      // Staying on the old key: whoever moved on is silent here (their frames
      // do not decrypt) until the next change gets through. Never plaintext.
      debugPrint('voice: could not switch media key: $e');
    }
  }

  /// Rotates the call's key — but only on the one participant with the
  /// lowest member id, so a call rekeys once per interval rather than once
  /// per participant.
  Future<void> _rotateIfFirst(
    String serverId,
    ChannelGroups groups,
    String channelId,
  ) async {
    final me = _session?.currentUser.userId;
    final participants = ref
        .read(voiceRosterProvider(serverId))
        .valueOrNull
        ?.inChannel(channelId)
        .map((p) => p.userId)
        .toList();
    if (me == null || participants == null || participants.isEmpty) return;
    participants.sort();
    if (participants.first != me) return;
    try {
      await groups.rotate(channelId);
    } on Object catch (e) {
      debugPrint('voice: could not rotate the call key: $e');
    }
  }

  Future<void> leave() async {
    if (!state.inCall) return;
    await _end();
  }

  /// Turns the camera on with the options the sheet returned, or off.
  ///
  /// **The grant has to come before the track.** A call token is minted naming
  /// the microphone only, whatever the member's permissions say, and the server
  /// adds the camera to it only once this client says its camera is on. So:
  /// tell the server, wait for the media server to hand the grant over (it
  /// arrives as a permissions update), then publish. If the grant does not
  /// come, take the claim back rather than leaving a camera the server thinks
  /// is on and nobody can see.
  ///
  /// Turning it off is the reverse order — stop publishing *first*, then tell
  /// the server — so the grant is never withdrawn from under a live track.
  ///
  /// Refusals (`missing_permission`, `camera_limit_reached`) surface as the
  /// server's own words through [VoiceCallState.warning], not as a thrown
  /// exception: the caller is a button, and the call goes on either way.
  Future<void> setCameraEnabled(bool on, {VoiceCameraOptions? options}) async {
    final engine = _engine;
    final session = _session;
    final channelId = state.channelId;
    if (engine == null || session == null || channelId == null) return;
    if (state.cameraBusy || on == state.cameraOn) return;

    final generation = _generation;
    final settings = ref.read(voiceSettingsProvider);
    state = state.copyWith(cameraBusy: true, warning: () => null);

    try {
      if (!on) {
        await engine.setCameraEnabled(false);
        await _tellServerCamera(session, on: false);
        if (generation == _generation) {
          state = state.copyWith(cameraOn: false, cameraBusy: false);
        }
        return;
      }

      // The server decides first: it is where the permission and the cap live.
      await _tellServerCamera(session, on: true);
      if (generation != _generation) return;

      final granted = await _awaitCameraGrant(engine);
      if (generation != _generation) return;

      if (!granted || !await engine.setCameraEnabled(true, options: options ?? settings.camera)) {
        // The server believes the camera is on and nothing is being sent.
        // Take the claim back, so the roster does not show a camera nobody has.
        await _tellServerCamera(session, on: false);
        if (generation == _generation) {
          state = state.copyWith(
            cameraOn: false,
            cameraBusy: false,
            warning: () =>
                'Your camera could not be started. Please try again.',
          );
        }
        return;
      }

      if (generation == _generation) {
        state = state.copyWith(cameraOn: true, cameraBusy: false);
      }
    } on ApiException catch (e) {
      if (generation == _generation) {
        state = state.copyWith(cameraBusy: false, warning: () => e.message);
      }
    } on Object {
      if (generation == _generation) {
        state = state.copyWith(
          cameraBusy: false,
          warning: () => 'Your camera could not be turned on.',
        );
      }
    }
  }

  /// Changes the camera or the effect while it is already on.
  Future<void> applyCameraOptions(VoiceCameraOptions options) async {
    if (!state.cameraOn) return;
    await _engine?.applyCameraOptions(options);
  }

  /// Reports this client's camera to the server, carrying the mute and deafen
  /// it already has — `SetVoiceSelfState` replaces the whole self-state, so
  /// sending only the camera would quietly unmute.
  Future<void> _tellServerCamera(ServerSession session, {required bool on}) {
    final settings = ref.read(voiceSettingsProvider);
    return session.voiceApi.setSelfState(
      session.token,
      selfMute: !settings.micOn,
      selfDeaf: settings.selfDeaf,
      cameraOn: on,
    );
  }

  /// Waits for the media server to accept this client's camera.
  ///
  /// The round trip is server to media server and back as a permissions
  /// update, through a relay, so it is not instant. A grant already in place
  /// returns at once. The reconciler re-pushes a missed grant within its own
  /// interval, so a timeout here is worth one retry rather than a failure.
  Future<bool> _awaitCameraGrant(VoiceEngine engine) async {
    if (engine.currentPublishRights.camera) return true;

    try {
      await engine.publishRights
          .firstWhere((rights) => rights.camera)
          .timeout(_cameraGrantTimeout);
      return true;
    } on Object {
      return engine.currentPublishRights.camera;
    }
  }

  /// Tells the engine which cameras this device is not to receive.
  ///
  /// Called whenever the per-member settings change, and once right after
  /// [_follow], so a camera that was already hidden is never received even
  /// once.
  void _applyVideoVisibility() {
    final engine = _engine;
    final serverId = state.serverId;
    final channelId = state.channelId;
    if (engine == null || serverId == null || channelId == null) return;

    final roster = ref.read(voiceRosterProvider(serverId)).valueOrNull;
    if (roster == null) return;

    final members = ref.read(memberAudioProvider.notifier);
    final me = _session?.currentUser.userId;

    for (final participant in roster.inChannel(channelId)) {
      if (participant.userId == me) continue;
      unawaited(
        engine.setVideoVisible(
          participant.userId,
          !members.of(serverId, participant.userId).videoHidden,
        ),
      );
    }
  }

  void dismissNotice() {
    if (!state.inCall && state.notice != null) state = const VoiceCallState();
  }

  void dismissWarning() {
    if (state.warning != null) state = state.copyWith(warning: () => null);
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
      ..add(engine.disconnects.listen(_onEngineDisconnected))
      ..add(
        engine.encryptionChanges.listen(
          (encryption) => state = state.copyWith(encryption: encryption),
        ),
      )
      ..add(
        engine.warnings.listen((warning) {
          if (state.inCall) state = state.copyWith(warning: () => warning);
        }),
      )
      ..add(
        engine.videoFeeds.listen(
          (feeds) => state = state.copyWith(videoFeeds: feeds),
        ),
      )
      ..add(
        engine.untrustedVideo.listen(
          (untrusted) => state = state.copyWith(untrustedVideo: untrusted),
        ),
      )
      ..add(
        engine.cameraStates.listen((on) {
          // The engine's own word, which includes it turning the camera off
          // itself — a track it could not encrypt, or a camera the OS took
          // away. Not applied mid-handshake, which owns the state until it
          // settles.
          if (!state.cameraBusy) state = state.copyWith(cameraOn: on);
        }),
      );

    // Every epoch of the voice channel's group is a new media key: somebody
    // joined or left the group, or its keys were rotated.
    final groups = _groups;
    final channelId = state.channelId;
    if (groups != null && channelId != null) {
      _subscriptions.add(
        groups.epochChanges
            .where((changed) => changed == channelId)
            .listen((_) => unawaited(_refreshMediaKey(groups, channelId))),
      );
      _rekey = Timer.periodic(
        _rekeyInterval,
        (_) => unawaited(_rotateIfFirst(serverId, groups, channelId)),
      );
    }

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
          (_, _) {
            _applyVolumes();
            // A member who joined after a hide wish was recorded is covered
            // here: the roster naming them is the first chance to apply it.
            _applyVideoVisibility();
          },
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
        final you = VoiceParticipant.fromProto(event.proto.voiceState);
        state = state.copyWith(
          serverMuted: you.serverMute,
          suppressed: you.suppressed,
          cameraSuppressed: you.cameraSuppressed,
          // The server's view of the camera, which is what everybody else
          // sees — so another device of this account turning it on, or the
          // permission going away mid-call, is reflected here. Not applied
          // while the handshake is in flight: the server's record and this
          // client's track are briefly out of step on purpose, and the
          // handshake is what settles them.
          cameraOn: state.cameraBusy ? null : you.cameraOn,
        );

      case ServerEventTypes.voiceLeft:
        final left = VoiceLeft.fromProto(event.proto.voiceLeft);
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
          member: const MemberMedia(),
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
    _rekey?.cancel();
    _rekey = null;
    _groups = null;

    final engine = _engine;
    _engine = null;
    _session = null;
    if (engine != null) unawaited(engine.dispose());
  }
}
