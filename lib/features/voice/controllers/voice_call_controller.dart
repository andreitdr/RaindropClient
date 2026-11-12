import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_info.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/e2ee_api.dart';
import '../../../core/network/event_stream.dart';
import '../../../core/network/voice_api.dart';
import '../../../core/voice/call_session_host.dart';
import '../../../core/voice/voice_engine.dart';
import '../../channels/controllers/channels_controller.dart';
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
    this.screenShare = const VoiceScreenShareState.off(),
    this.screenShareSuppressed = false,
    this.screenShareBusy = false,
    this.screenSharingAvailable = false,
    this.screenShares = const {},
    this.untrustedScreenShares = const {},
    this.watching = const {},
    this.microphoneFailed = false,
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

  /// The microphone would not open, so nobody can hear this member — for a
  /// reason that is nothing to do with the server: something else has it, or
  /// there is no input device. Unlike [serverMuted] and [suppressed] this is
  /// worth trying again, which is what the mute button does while it is set
  /// ([retryMicrophone]). Cleared as soon as the microphone opens.
  final bool microphoneFailed;

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

  /// Every camera in the call and every share this client watches, its own
  /// first. The whole list is replaced on every change.
  final List<VoiceVideoFeed> videoFeeds;

  /// Participants whose camera arrived unencrypted or stopped decrypting.
  /// Their tile says so; nothing untrusted is ever drawn.
  final Set<String> untrustedVideo;

  /// What this client is sharing, as the engine reports it — which can be
  /// less than was asked for, when a window's sound could not be captured.
  final VoiceScreenShareState screenShare;

  /// A share cannot be started: no `screen_share` permission, or this server
  /// carries none.
  final bool screenShareSuppressed;

  /// A share is being started or stopped right now; the button refuses a
  /// second tap.
  final bool screenShareBusy;

  /// This server carries screen sharing at all (`voice.screen.v1`). Whether
  /// *this device* can share is a separate question — `canShareScreen` — since
  /// a phone can still watch.
  final bool screenSharingAvailable;

  /// Members sharing a screen this client trusts, watched or not.
  final Set<String> screenShares;

  /// Members whose share arrived unencrypted or stopped decrypting. Never
  /// shown or played.
  final Set<String> untrustedScreenShares;

  /// Members whose share this client has chosen to watch.
  final Set<String> watching;

  /// One member's camera, or null when they are not sending a camera this
  /// client is receiving — because they have it off, it is hidden here, or it
  /// is not trusted. Never their screen share, which is not a camera.
  VoiceVideoFeed? feedFor(String userId) => videoFeeds
      .where(
        (feed) => feed.identity == userId && feed.kind == VoiceVideoKind.camera,
      )
      .firstOrNull;

  /// One member's screen share, or null when they are not sharing one this
  /// client watches — or, for this client's own, when it is not sharing.
  VoiceVideoFeed? screenFeedFor(String userId) => videoFeeds
      .where(
        (feed) => feed.identity == userId && feed.kind == VoiceVideoKind.screen,
      )
      .firstOrNull;

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
    VoiceScreenShareState? screenShare,
    bool? screenShareSuppressed,
    bool? screenShareBusy,
    bool? screenSharingAvailable,
    Set<String>? screenShares,
    Set<String>? untrustedScreenShares,
    Set<String>? watching,
    bool? microphoneFailed,
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
    screenShare: screenShare ?? this.screenShare,
    screenShareSuppressed: screenShareSuppressed ?? this.screenShareSuppressed,
    screenShareBusy: screenShareBusy ?? this.screenShareBusy,
    screenSharingAvailable:
        screenSharingAvailable ?? this.screenSharingAvailable,
    screenShares: screenShares ?? this.screenShares,
    untrustedScreenShares: untrustedScreenShares ?? this.untrustedScreenShares,
    watching: watching ?? this.watching,
    microphoneFailed: microphoneFailed ?? this.microphoneFailed,
  );
}

/// What this client has told the server about its screen share. A record so
/// the three parts always travel together: a share's kind and sound mean
/// nothing without it being on.
typedef ScreenShareClaim = ({bool on, String? kind, bool audio});

/// Not sharing.
const ScreenShareClaim noScreenShare = (on: false, kind: null, audio: false);

/// The share claim for [options]: what the server is asked to record before
/// anything is captured.
ScreenShareClaim screenShareClaimOf(VoiceScreenShareOptions options) => (
  on: true,
  kind: options.source.kind == VoiceScreenSourceKind.window
      ? VoiceShareKinds.window
      : VoiceShareKinds.screen,
  audio: options.withAudio,
);

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

/// How long to wait for the media server to accept a camera or a share after
/// the server has been told about it. Long enough for a relayed round trip on
/// a slow connection, short enough that a user does not sit watching a dead
/// button.
const _cameraGrantTimeout = Duration(seconds: 5);

/// How long to wait before each try at putting a dropped call back together,
/// and — by its length — how many tries there are. Short at first, because a
/// phone that has just changed network is usually reachable again within a
/// second or two; then longer, and then the call is genuinely over. About
/// half a minute in total, which is long enough to walk through a tunnel and
/// short enough not to leave somebody talking to a call that is not there.
const _rejoinBackoff = [
  Duration(seconds: 1),
  Duration(seconds: 3),
  Duration(seconds: 6),
  Duration(seconds: 10),
  Duration(seconds: 10),
];

/// What tells the operating system a call is in progress, so a phone keeps
/// it running while the app is not on screen. Overridden in tests, and by
/// anything that wants a call announced its own way.
final callSessionHostProvider = Provider<CallSessionHost>(
  (_) => createCallSessionHost(),
);

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

  /// What this client last told the server about its camera.
  ///
  /// Kept apart from [VoiceCallState.cameraOn], which only turns true once the
  /// camera is actually sending: the server hears "on" at the start of the
  /// handshake, before that. `SetVoiceSelfState` is the whole state, so a mute
  /// toggled in between has to repeat this claim, not [VoiceCallState.cameraOn],
  /// or it would take the camera back off the server mid-handshake.
  bool _cameraClaimed = false;

  /// What this client last told the server about its screen share, for the
  /// same reason as [_cameraClaimed].
  ScreenShareClaim _shareClaim = noScreenShare;

  /// The rejoin in progress, if any ([_rejoinOrEnd]). It survives across the
  /// tries it makes — each of which takes a generation of its own — so it
  /// cannot be tracked by [_generation]; anything that settles the call for
  /// good clears it, and that is how the rejoin knows to stop.
  Object? _rejoin;

  /// The last call's media still being released, if it is.
  Future<void>? _disposing;

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

    // Quitting the app leaves the call first, so everybody else sees this
    // member go at once instead of when the server gives up on them, and the
    // microphone and camera are let go before the process is. Bounded, so a
    // server that cannot be reached never holds up the quit. A detach (the OS
    // tearing the app down) cannot be waited for, so it is a best try.
    final exit = AppLifecycleListener(
      onExitRequested: () async {
        await leaveNow();
        return AppExitResponse.exit;
      },
      onDetach: () => unawaited(leaveNow()),
    );
    ref.onDispose(exit.dispose);

    ref.onDispose(_teardown);
    return const VoiceCallState();
  }

  /// Joins [channelId] on [serverId], leaving any other call first. Throws
  /// the server's [ApiException] (`channel_full`, `missing_permission`,
  /// `voice_unavailable`) or [UnsupportedVoiceTransportException] for the
  /// caller to show.
  Future<void> join(String serverId, String channelId) async {
    if (state.isIn(serverId, channelId)) return;
    _rejoin = null;
    await leave();
    await _connect(serverId, channelId, VoiceCallStatus.joining);
  }

  /// The join itself, from a member asking for it ([VoiceCallStatus.joining])
  /// or from this client picking a dropped call back up
  /// ([VoiceCallStatus.reconnecting]) — see [_rejoinOrEnd]. The two differ
  /// only in what the call controls say while it happens.
  Future<void> _connect(
    String serverId,
    String channelId,
    VoiceCallStatus status,
  ) async {
    final rejoining = status == VoiceCallStatus.reconnecting;
    final generation = ++_generation;
    _cameraClaimed = false;
    _shareClaim = noScreenShare;
    final session = await ref.read(serverSessionProvider(serverId).future);
    if (session == null) throw StateError('Not signed in to this server.');
    if (generation != _generation) return;

    state = VoiceCallState(
      serverId: serverId,
      channelId: channelId,
      status: status,
    );

    // The media key comes first, before the server lists this device in the
    // call: on a server whose calls are end-to-end encrypted, a device that
    // cannot encrypt does not join at all.
    VoiceMediaKey? mediaKey;
    ChannelGroups? groups;
    var videoAvailable = false;
    var screenSharingAvailable = false;
    try {
      final info = await session.usersApi.serverInfo();
      videoAvailable = info.capabilities.contains(voiceVideoCapability);
      screenSharingAvailable = info.capabilities.contains(
        voiceScreenCapability,
      );
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
      screenShareSuppressed: joined.you.screenShareSuppressed,
      screenSharingAvailable: screenSharingAvailable,
    );
    _follow(serverId, session, engine);

    // Set before connecting, so the first audio to arrive already plays at
    // the right volume, a camera hidden earlier is never received at all, and
    // out of the right speaker.
    _applyVolumes();
    _applyVideoVisibility();
    unawaited(engine.setSpeakerphone(settings.speakerphone));

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
        // A rejoin's failed try is neither news nor the end of the call:
        // [_rejoinOrEnd] tries again, and speaks for the call once it has
        // stopped trying.
        await _end(
          notice: rejoining ? null : 'Could not connect to the call.',
          settles: !rejoining,
        );
      }
      rethrow;
    }

    if (generation == _generation &&
        state.status != VoiceCallStatus.connected) {
      state = state.copyWith(status: VoiceCallStatus.connected);
    }

    // Only now: a call the OS is told about is one that is actually up, so a
    // join that failed never leaves a notification behind.
    if (generation == _generation) _describeSession(serverId, channelId);

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

  /// Leaves the call and waits — for at most [limit] — until the server has
  /// been told and the call's devices are released. For quitting the app,
  /// where nothing runs afterwards to finish the job. Never throws.
  Future<void> leaveNow({
    Duration limit = const Duration(milliseconds: 1500),
  }) async {
    // `_end` tears the engine down before its first await, so the release it
    // starts is already in [_disposing] here.
    final leaving = state.inCall ? _end() : Future<void>.value();
    final disposing = _disposing;
    try {
      await Future.wait([leaving, ?disposing]).timeout(limit);
    } on Object catch (e) {
      debugPrint('voice: leaving on exit did not finish: $e');
    }
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
        await _sendSelfState(session, cameraOn: false);
        if (generation == _generation) {
          state = state.copyWith(cameraOn: false, cameraBusy: false);
        }
        return;
      }

      // The server decides first: it is where the permission and the cap live.
      await _sendSelfState(session, cameraOn: true);
      if (generation != _generation) return;

      final granted = await _awaitCameraGrant(engine);
      if (generation != _generation) return;

      if (!granted ||
          !await engine.setCameraEnabled(
            true,
            options: options ?? settings.camera,
          )) {
        // The server believes the camera is on and nothing is being sent.
        // Take the claim back, so the roster does not show a camera nobody has.
        await _sendSelfState(session, cameraOn: false);
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

  /// Starts sharing [options] — or switches a running share to it.
  ///
  /// The camera's handshake, for the camera's reason: a call token names no
  /// share until the server adds one, so tell the server first (which is where
  /// the permission, the cap and the rule about sound live), wait for the media
  /// server's grant, and only then capture and publish. Nothing is captured
  /// for a share the server refused. If the grant never comes, the claim is
  /// taken back, so the roster never shows a share nobody can watch.
  ///
  /// Refusals surface as the server's own words through
  /// [VoiceCallState.warning], like the camera's.
  Future<void> startScreenShare(VoiceScreenShareOptions options) async {
    final engine = _engine;
    final session = _session;
    if (engine == null || session == null || !state.inCall) return;
    if (state.screenShareBusy) return;

    final generation = _generation;
    final claim = screenShareClaimOf(options);
    state = state.copyWith(screenShareBusy: true, warning: () => null);

    try {
      // Switching: the old share stops before the new one is claimed. A new
      // claim can withdraw part of the old grant — the sound, going from a
      // window to a screen — and the engine must not take that, under a live
      // share, as the server silencing it.
      if (engine.currentScreenShare.on) {
        await engine.setScreenShareEnabled(false);
        if (generation != _generation) return;
      }

      await _sendSelfState(session, share: claim);
      if (generation != _generation) return;

      final granted = await _awaitShareGrant(engine, withAudio: claim.audio);
      if (generation != _generation) return;

      if (!granted ||
          !await engine.setScreenShareEnabled(true, options: options)) {
        await _sendSelfState(session, share: noScreenShare);
        if (generation == _generation) {
          state = state.copyWith(
            screenShare: const VoiceScreenShareState.off(),
            screenShareBusy: false,
            warning: () => 'Your screen could not be shared. Please try again.',
          );
        }
        return;
      }
      if (generation != _generation) return;

      // What the engine is really sending, which can be less than was asked:
      // nothing, when the capture failed (it has said why), or no sound, when
      // the window's could not be captured. The server is told the truth.
      final sharing = engine.currentScreenShare;
      if (!sharing.on) {
        await _sendSelfState(session, share: noScreenShare);
      } else if (claim.audio && !sharing.withAudio) {
        await _sendSelfState(
          session,
          share: (on: true, kind: claim.kind, audio: false),
        );
      }

      if (generation == _generation) {
        state = state.copyWith(screenShare: sharing, screenShareBusy: false);
      }
    } on ApiException catch (e) {
      if (generation == _generation) {
        state = state.copyWith(
          screenShareBusy: false,
          warning: () => e.message,
        );
      }
    } on Object {
      if (generation == _generation) {
        state = state.copyWith(
          screenShareBusy: false,
          warning: () => 'Your screen could not be shared.',
        );
      }
    }
  }

  /// Stops sharing. The engine first, then the server — never the other way
  /// round, or the grant would be withdrawn from under a live share.
  Future<void> stopScreenShare() async {
    final engine = _engine;
    final session = _session;
    if (engine == null || session == null) return;
    if (state.screenShareBusy || !_shareClaim.on && !state.screenShare.on) {
      return;
    }

    final generation = _generation;
    state = state.copyWith(screenShareBusy: true);
    try {
      await engine.setScreenShareEnabled(false);
      await _sendSelfState(session, share: noScreenShare);
    } on ApiException {
      // Not in the call any more, or unreachable: the engine has stopped, and
      // the server's own reconciling withdraws the grant either way.
    }
    if (generation == _generation) {
      state = state.copyWith(
        screenShare: const VoiceScreenShareState.off(),
        screenShareBusy: false,
      );
    }
  }

  /// Starts or stops receiving [userId]'s screen share. Local only: they are
  /// never told, and nobody else is affected.
  Future<void> setScreenShareWatched(String userId, bool watched) async {
    final engine = _engine;
    if (engine == null) return;
    state = state.copyWith(
      watching: watched
          ? {...state.watching, userId}
          : ({...state.watching}..remove(userId)),
    );
    await engine.setScreenShareWatched(userId, watched);
  }

  /// Forgets watching [userId]'s share because they left the call: the share
  /// ended with them, and a later one is offered as a Watch card again rather
  /// than streamed unasked.
  void _stopWatchingLeaver(String? userId) {
    if (userId == null || !state.watching.contains(userId)) return;
    state = state.copyWith(watching: {...state.watching}..remove(userId));
    final engine = _engine;
    if (engine != null) {
      unawaited(
        engine.setScreenShareWatched(userId, false).catchError((Object _) {
          // They are already gone from the room; nothing left to stop.
        }),
      );
    }
  }

  /// Waits for the media server to accept this client's share — its sound
  /// too, when [withAudio]. Like [_awaitCameraGrant].
  Future<bool> _awaitShareGrant(
    VoiceEngine engine, {
    required bool withAudio,
  }) async {
    bool allowed(VoicePublishRights rights) =>
        rights.screen && (!withAudio || rights.screenAudio);

    if (allowed(engine.currentPublishRights)) return true;

    try {
      await engine.publishRights
          .firstWhere(allowed)
          .timeout(_cameraGrantTimeout);
      return true;
    } on Object {
      return allowed(engine.currentPublishRights);
    }
  }

  /// Changes the camera or the effect while it is already on.
  Future<void> applyCameraOptions(VoiceCameraOptions options) async {
    if (!state.cameraOn) return;
    await _engine?.applyCameraOptions(options);
  }

  /// Sends this client's whole self-state: mute, deafen, and the camera and
  /// the share as last claimed — with [cameraOn] or [share] changing that claim
  /// when given.
  ///
  /// `SetVoiceSelfState` replaces all of it rather than applying a change, so
  /// every report goes through here — a camera report that left out the mute
  /// would quietly unmute, and a mute that left out the camera or the share
  /// would end it at the server and take its grant away from under the track.
  /// A claim the server refuses is put back, so the next mute does not ask for
  /// it again.
  Future<VoiceParticipant> _sendSelfState(
    ServerSession session, {
    VoiceSettings? settings,
    bool? cameraOn,
    ScreenShareClaim? share,
  }) async {
    final VoiceSettings current = settings ?? ref.read(voiceSettingsProvider);
    final cameraBefore = _cameraClaimed;
    final shareBefore = _shareClaim;
    if (cameraOn != null) _cameraClaimed = cameraOn;
    if (share != null) _shareClaim = share;

    try {
      return await session.voiceApi.setSelfState(
        session.token,
        selfMute: !current.micOn,
        selfDeaf: current.selfDeaf,
        cameraOn: _cameraClaimed,
        screenShareOn: _shareClaim.on,
        screenShareKind: _shareClaim.kind,
        screenShareAudio: _shareClaim.audio,
      );
    } on ApiException {
      if (cameraOn != null) _cameraClaimed = cameraBefore;
      if (share != null) _shareClaim = shareBefore;
      rethrow;
    }
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

  /// Asks for the microphone again after it would not open. Whatever was
  /// holding it may have let go; if it has not, the engine reports another
  /// failure and nothing else changes. Muting is not the answer here —
  /// nobody can hear this member either way — so this is what the mute
  /// button does while [VoiceCallState.microphoneFailed].
  Future<void> retryMicrophone() async {
    final engine = _engine;
    if (engine == null || !state.microphoneFailed) return;
    state = state.copyWith(microphoneFailed: false);
    await engine.setMicEnabled(ref.read(voiceSettingsProvider).micOn);
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
        engine.microphoneFailures.listen(
          (_) => state = state.copyWith(microphoneFailed: true),
        ),
      )
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
          // itself — a track it could not encrypt, a camera the OS took away,
          // or the grant withdrawn. Not applied mid-handshake, which owns the
          // state until it settles. A camera the engine stopped is reported,
          // so the roster stops claiming one nobody can see.
          if (state.cameraBusy) return;
          state = state.copyWith(cameraOn: on);
          if (!on && _cameraClaimed) unawaited(_reportQuietly(cameraOn: false));
        }),
      )
      ..add(engine.screenShareStates.listen(_onEngineShare))
      ..add(
        engine.screenShares.listen(
          (sharing) => state = state.copyWith(screenShares: sharing),
        ),
      )
      ..add(
        engine.untrustedScreenShares.listen(
          (untrusted) =>
              state = state.copyWith(untrustedScreenShares: untrusted),
        ),
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
        ref.listen<AsyncValue<VoiceRoster>>(voiceRosterProvider(serverId), (
          _,
          _,
        ) {
          _applyVolumes();
          // A member who joined after a hide wish was recorded is covered
          // here: the roster naming them is the first chance to apply it.
          _applyVideoVisibility();
        }),
      );
  }

  /// The engine's own word on the share, which includes it stopping or
  /// trimming the share itself: the window closed, the grant was withdrawn,
  /// it could not be encrypted, or the window's sound could not be captured.
  /// The server is told, so the roster stops claiming what is not being sent.
  /// Not applied mid-handshake, which settles the state itself.
  void _onEngineShare(VoiceScreenShareState share) {
    if (state.screenShareBusy) return;
    state = state.copyWith(screenShare: share);

    final claim = _shareClaim;
    if (!claim.on) return;

    ScreenShareClaim? corrected;
    if (!share.on) {
      corrected = noScreenShare;
    } else if (claim.audio && !share.withAudio) {
      corrected = (on: true, kind: claim.kind, audio: false);
    }
    if (corrected == null) return;

    unawaited(_reportQuietly(share: corrected));
  }

  /// Corrects a claim after the engine changed something on its own. Never
  /// throws: out of the call, or unreachable, there is nothing left to correct.
  Future<void> _reportQuietly({bool? cameraOn, ScreenShareClaim? share}) async {
    final session = _session;
    if (session == null) return;
    try {
      await _sendSelfState(session, cameraOn: cameraOn, share: share);
    } on ApiException {
      // Nothing to do.
    }
  }

  void _onServerEvent(ServerEvent event) {
    final me = _session?.currentUser.userId;
    if (me == null || event.channelId != state.channelId) return;

    // Somebody else left this call. Raindrop says so before (or instead of)
    // the media server noticing, so their share stops being watched here
    // straight away — the stage and the full view close rather than waiting
    // on a stream that has ended.
    if (event.userId != me) {
      if (event.type == ServerEventTypes.voiceLeft) {
        _stopWatchingLeaver(event.userId);
      }
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
        // The claims do not follow this event: it can arrive after a newer
        // report has already gone out, and a claim moved back by a stale one
        // would have the next mute end the camera or the share. Whatever the
        // server takes away on its own — a permission, the right to speak —
        // it takes from the media server's grant too, the engine stops what
        // it must, and the claims follow the engine ([_onEngineShare] and
        // the camera's listener).
        state = state.copyWith(
          screenShareSuppressed: you.screenShareSuppressed,
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
        // Nobody decided the call was over — the network did. The media
        // library has already exhausted its own reconnects by the time this
        // arrives, so picking it up again means joining afresh.
        unawaited(_rejoinOrEnd());
    }
  }

  /// Puts a call back together after it dropped on its own, and ends it for
  /// good if it cannot be.
  ///
  /// This is what makes a call survive a phone changing network — Wi-Fi to
  /// cellular, or a tunnel — which is far more common than a desktop losing
  /// its connection. The call stays on screen as
  /// [VoiceCallStatus.reconnecting] throughout, so a member who is talking
  /// sees it working rather than a call that vanished.
  ///
  /// Each try is a fresh join: a new token from the server, and on an
  /// end-to-end encrypted server a fresh media key, since the group may have
  /// moved on while this device was away. Anything the server refuses on the
  /// way (the channel is gone, this member may no longer connect) ends the
  /// call rather than being retried — those will refuse again.
  Future<void> _rejoinOrEnd() async {
    final serverId = state.serverId;
    final channelId = state.channelId;
    final session = _session;
    if (serverId == null || channelId == null) return;

    final token = Object();
    _rejoin = token;

    // The engine is finished; the call is not. Everything this call was
    // following goes with it, and [_connect] sets it all up again.
    _teardown();
    state = state.copyWith(status: VoiceCallStatus.reconnecting);

    // Tell the server this device is out, so the roster does not show it in
    // the call twice while it comes back. Its own reconciler would get there
    // eventually; saying so is faster and quieter.
    if (session != null) await _leaveQuietly(session, channelId);

    for (final wait in _rejoinBackoff) {
      await Future<void>.delayed(wait);
      // Hung up, signed out, or joined somewhere else while waiting: whatever
      // did that cleared the token, and it outranks this.
      if (!identical(_rejoin, token)) return;

      try {
        await _connect(serverId, channelId, VoiceCallStatus.reconnecting);
        // Back in the call — unless something replaced this rejoin while it
        // was connecting, in which case that is the call now.
        if (identical(_rejoin, token)) _rejoin = null;
        return;
      } on ApiException catch (e) {
        // The server said no, and will say no again: the channel is gone,
        // the call is full, or this member may not connect any more.
        if (!identical(_rejoin, token)) return;
        await _end(notice: _rejoinRefusal(e), reportLeave: false);
        return;
      } on Object {
        // Still unreachable, or the media connection failed again. [_connect]
        // cleared the call on its way out, so put it back — quietly — and
        // wait out the next interval.
        if (!identical(_rejoin, token)) return;
        state = VoiceCallState(
          serverId: serverId,
          channelId: channelId,
          status: VoiceCallStatus.reconnecting,
        );
      }
    }

    await _end(notice: 'Lost the connection to the call.', reportLeave: false);
  }

  static String _rejoinRefusal(ApiException e) => switch (e.code) {
    'channel_full' => 'The call filled up while you were reconnecting.',
    'missing_permission' => 'You can no longer join that call.',
    _ => 'Lost the connection to the call.',
  };

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
      // Turning it back on is a retry: assume it works, and let the engine
      // say otherwise again if it does not.
      if (next.micOn) state = state.copyWith(microphoneFailed: false);
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

    if (previous.speakerphone != next.speakerphone) {
      unawaited(engine.setSpeakerphone(next.speakerphone));
    }
  }

  /// Tells everybody else this client muted or deafened — the icon next to
  /// its name. The audio itself already stopped locally.
  Future<void> _report(ServerSession session, VoiceSettings settings) async {
    try {
      await _sendSelfState(session, settings: settings);
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
      final member = audio.of(serverId, participant.userId);
      unawaited(
        engine.setParticipantVolume(
          participant.userId,
          effectiveVolume(
            outputVolume: settings.outputVolume,
            member: member,
            deafened: settings.selfDeaf,
          ),
        ),
      );
      unawaited(
        engine.setScreenShareVolume(
          participant.userId,
          effectiveScreenVolume(
            outputVolume: settings.outputVolume,
            member: member,
            deafened: settings.selfDeaf,
          ),
        ),
      );
    }
  }

  // ── Telling the OS about the call ──────────────────────────────────────────

  /// Asks the platform to keep this call running while the app is not on
  /// screen, described by where it is: the channel, on the server. Does
  /// nothing on platforms that need no telling — see [CallSessionHost].
  void _describeSession(String serverId, String channelId) {
    final channel = ref
        .read(channelsProvider(serverId))
        .valueOrNull
        ?.where((c) => c.id == channelId)
        .firstOrNull;

    unawaited(
      ref
          .read(callSessionHostProvider)
          .begin(
            CallSessionDescription(
              // Before the channel list has loaded there is still a call to
              // announce; it is named as plainly as it can be.
              title: channel == null ? 'In a voice call' : 'In ${channel.name}',
              body: _session?.profile.displayName ?? '',
            ),
          ),
    );
  }

  // ── Ending ─────────────────────────────────────────────────────────────────

  /// Ends the call and tears everything down. [settles] says whether that is
  /// the *call* ending — which cancels any rejoin under way — or only one
  /// failed try inside a rejoin, which the rejoin itself goes on from.
  Future<void> _end({
    String? notice,
    bool reportLeave = true,
    bool settles = true,
  }) async {
    _generation++;
    _cameraClaimed = false;
    _shareClaim = noScreenShare;
    if (settles) _rejoin = null;
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
    // Before anything else: whatever went wrong with the call, the OS must
    // not be left believing one is still running.
    unawaited(ref.read(callSessionHostProvider).end());

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
    if (engine != null) {
      // Kept, so that quitting the app can wait for the devices to be let go
      // ([leaveNow]); everything else lets it finish on its own.
      final disposing = engine.dispose().catchError((Object e) {
        debugPrint('voice: the call did not close cleanly: $e');
      });
      _disposing = disposing;
      unawaited(
        disposing.whenComplete(() {
          if (identical(_disposing, disposing)) _disposing = null;
        }),
      );
    }
  }
}
