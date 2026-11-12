/// [VoiceEngine] on LiveKit. The only file in the app that imports
/// `livekit_client` or `flutter_webrtc`.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:raindrop_camera_effects/raindrop_camera_effects.dart';

import '../platform/platform_info.dart';
import '../video/camera_effects_engine.dart';
import 'voice_engine.dart';

class LiveKitVoiceEngine implements VoiceEngine {
  /// The transport name the server uses for LiveKit.
  static const transportName = 'livekit';

  /// Prepares the media stack, once, before any call.
  ///
  /// Only phones need this: WebRTC reads Android's playout attributes when it
  /// builds its audio device module, which happens on the first call and
  /// cannot be changed afterwards, so the call's own settings have to be in
  /// place before then. Asking for a *communication* session is what routes a
  /// call to the earpiece and Bluetooth headsets rather than the media
  /// speaker, and what lets it keep the microphone in the background.
  /// Desktop initializes itself lazily and is left alone.
  static Future<void> initialize() async {
    if (!isMobilePlatform) return;
    await LiveKitClient.initialize(
      // LiveKit marks the audio-session API experimental. Passing nothing
      // leaves Android's playout attributes on media defaults, which puts a
      // call on the media stream — wrong volume rocker, wrong routing — so
      // this is worth following across an SDK upgrade rather than skipping.
      // ignore: experimental_member_use
      initialAudioSessionOptions: const AudioSessionOptions.communication(),
    );
  }

  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _micWanted = false;
  bool _disconnectReported = false;
  VoiceAudioProcessing _processing = const VoiceAudioProcessing();
  final Map<String, double> _volumes = {};
  double _defaultVolume = 1.0;

  final _connectionStates = StreamController<VoiceConnectionState>.broadcast();
  final _activeSpeakers = StreamController<Set<String>>.broadcast();
  final _disconnects = StreamController<VoiceDisconnectReason>.broadcast();
  final _publishRights = StreamController<VoicePublishRights>.broadcast();
  final _micFailures = StreamController<void>.broadcast();
  final _encryption = StreamController<VoiceEncryption>.broadcast();
  final _warnings = StreamController<String>.broadcast();
  final _cameraStates = StreamController<bool>.broadcast();
  final _videoFeeds = StreamController<List<VoiceVideoFeed>>.broadcast();
  final _untrustedVideo = StreamController<Set<String>>.broadcast();

  /// What the server currently lets this participant send. Kept rather than
  /// derived on demand, because the camera handshake has to know whether a
  /// grant is already in place before it decides to wait for one.
  VoicePublishRights _rights = VoicePublishRights.none;

  /// The effects on this call's camera, if any are running.
  final _effects = _TrackEffects();

  /// What the camera was last asked to be, and with what. Remembered so a
  /// track republished after a reconnect comes back with the same choice.
  bool _cameraWanted = false;
  VoiceCameraOptions _camera = const VoiceCameraOptions();

  /// The camera publish in flight, if any. Publishing is single-flight: the
  /// grant arriving and the call controller reacting to it can both ask, and
  /// two overlapping `setCameraEnabled(true)` calls can leave this device
  /// showing a track nobody else receives.
  Future<void>? _cameraApplying;

  /// Publications whose failed subscription has already been asked for once
  /// more, so a track that cannot be received is retried once, not forever.
  final _subscribeRetried = <String>{};

  /// Whether the chosen camera faces the user, which is the only thing that
  /// decides whether their own picture is mirrored. Resolved from the device
  /// list when the camera is chosen, since a capture track does not say.
  bool _frontCamera = true;

  /// Participants whose camera this device is not to receive. A wish, not a
  /// state: it is re-applied whenever they publish, so hiding somebody does not
  /// leak the moment they turn their camera off and on again.
  final _videoHidden = <String>{};

  /// Participants whose screen share this device receives — the opposite
  /// default to [_videoHidden]: a share is not received until it is watched,
  /// and the wish outlives the share, like that one.
  final _watching = <String>{};

  /// How loud each participant's shared window plays here, apart from their
  /// voice.
  final Map<String, double> _screenVolumes = {};

  final _screenShareStates =
      StreamController<VoiceScreenShareState>.broadcast();
  final _screenShares = StreamController<Set<String>>.broadcast();
  final _untrustedScreenShares = StreamController<Set<String>>.broadcast();

  /// What this client is sharing.
  VoiceScreenShareState _share = const VoiceScreenShareState.off();

  /// Bumped whenever a share starts or stops, so a start still waiting on the
  /// capture cannot publish after it was stopped or replaced.
  int _shareGeneration = 0;

  /// Keeps the running share inside the 1080p box, and notices it ending.
  _ScreenSizeGuard? _sizeGuard;
  _ShareEndWatch? _endWatch;

  /// Set when the call is end-to-end encrypted.
  BaseKeyProvider? _keyProvider;

  /// Participants who published media without encryption in an encrypted
  /// call. Kept silent, and their camera unshown, for as long as they are in
  /// it, whatever the keys do afterwards: a client that sent one frame in the
  /// clear is not using the group's key, and republishing does not earn it a
  /// second chance. Deliberately per participant rather than per publication,
  /// which is the stricter of the two readings.
  final _unencrypted = <String>{};

  /// Publications whose frames currently fail to decrypt, by track sid.
  /// Usually a key change one side has not made yet, so this clears on the
  /// next key change or the first frame that decrypts; the cryptor drops
  /// those frames anyway.
  ///
  /// Keyed by publication, not by participant: `E2EEManager` keeps one frame
  /// cryptor per track, so one participant's microphone can decrypt while
  /// their camera does not, and a verdict about one must not reach the other.
  final _failing = <String>{};

  /// The key ring LiveKit keeps per call: this many past keys stay usable, so
  /// frames sent just before a key change still decrypt after it.
  static const keyRingSize = 16;

  /// What a camera is sent as. VP8 is universally supported by the frame
  /// cryptor; see [blockedVideoCodecs] for the codec that is not, and why
  /// this is pinned rather than negotiated.
  static const _videoCodec = 'vp8';

  @override
  Stream<VoiceConnectionState> get connectionStates => _connectionStates.stream;

  @override
  Stream<Set<String>> get activeSpeakers => _activeSpeakers.stream;

  @override
  Stream<VoiceDisconnectReason> get disconnects => _disconnects.stream;

  @override
  Stream<VoicePublishRights> get publishRights => _publishRights.stream;

  @override
  VoicePublishRights get currentPublishRights => _rights;

  @override
  Stream<bool> get cameraStates => _cameraStates.stream;

  @override
  Stream<List<VoiceVideoFeed>> get videoFeeds => _videoFeeds.stream;

  @override
  Stream<Set<String>> get untrustedVideo => _untrustedVideo.stream;

  @override
  Stream<void> get microphoneFailures => _micFailures.stream;

  @override
  Stream<VoiceEncryption> get encryptionChanges => _encryption.stream;

  @override
  Stream<VoiceScreenShareState> get screenShareStates =>
      _screenShareStates.stream;

  @override
  VoiceScreenShareState get currentScreenShare => _share;

  @override
  Stream<Set<String>> get screenShares => _screenShares.stream;

  @override
  Stream<Set<String>> get untrustedScreenShares =>
      _untrustedScreenShares.stream;

  @override
  Stream<String> get warnings => _warnings.stream;

  @override
  Future<void> connect(
    Uri url,
    String token, {
    required bool micEnabled,
    required VoiceAudioProcessing processing,
    String? inputDeviceId,
    String? outputDeviceId,
    VoiceMediaKey? mediaKey,
  }) async {
    _micWanted = micEnabled;
    _processing = processing;
    _connectionStates.add(VoiceConnectionState.connecting);

    // End-to-end encryption: LiveKit's frame cryptor encrypts every frame
    // with the group's shared key before it leaves, and decrypts on arrival.
    // Keys are never ratcheted (window 0): each epoch's key comes fresh from
    // the MLS group, and a ratchet would let anybody holding an old key
    // derive the next. Failures never disable encryption (tolerance -1):
    // undecryptable frames are dropped, not played.
    E2EEOptions? encryption;
    if (mediaKey != null) {
      final provider = _SharedKeyProvider.from(
        await BaseKeyProvider.create(
          sharedKey: true,
          ratchetWindowSize: 0,
          failureTolerance: -1,
          keyRingSize: keyRingSize,
        ),
      );
      await provider.setSharedKey(
        String.fromCharCodes(mediaKey.key),
        keyIndex: mediaKey.index,
      );
      _keyProvider = provider;
      encryption = E2EEOptions(keyProvider: provider);
    }

    final room = Room(
      roomOptions: RoomOptions(
        // Video goes only where it is looked at, at the size it is looked at:
        // a camera tile off screen, or a share drawn small, is not sent at full
        // resolution — and with dynacast a layer nobody receives (a share
        // nobody watches) is not even encoded. This is why [_reportFeeds]
        // never reads `publication.enabled`: with adaptive stream that turns
        // false whenever no tile is visible, and a feed dropped for it would
        // never get a tile to become visible in.
        adaptiveStream: true,
        dynacast: true,
        defaultAudioCaptureOptions: _captureOptions(inputDeviceId),
        // Speech bitrate, and silence sent as nothing (DTX), which is most of
        // a group call.
        defaultAudioPublishOptions: const AudioPublishOptions(
          encoding: AudioEncoding.presetSpeech,
          dtx: true,
        ),
        defaultAudioOutputOptions: AudioOutputOptions(deviceId: outputDeviceId),
        // Stated rather than inherited from the SDK's defaults, because the
        // codec is a security setting here and not only a quality one: see
        // [blockedVideoCodecs]. Simulcast and the backup codec are pinned to
        // the same codec so no negotiation can quietly land on another one.
        defaultVideoPublishOptions: const VideoPublishOptions(
          videoCodec: _videoCodec,
          simulcast: true,
          backupVideoCodec: BackupVideoCodec(
            enabled: true,
            codec: _videoCodec,
            simulcast: true,
          ),
          degradationPreference: DegradationPreference.maintainFramerate,
        ),
        encryption: encryption,
      ),
    );
    _room = room;
    _listen(room);

    await room.connect(url.toString(), token);
    _connectionStates.add(VoiceConnectionState.connected);
    if (mediaKey != null) {
      // Senders start on the key's slot; LiveKit otherwise stays on 0.
      await room.e2eeManager?.setKeyIndex(mediaKey.index);
    }
    _reportEncryption();

    // The token's own grant, before any update arrives: a client that joined
    // muted for everyone must know it cannot speak without waiting for an
    // event that may never come, because nothing changed after it connected.
    if (room.localParticipant case final local?) {
      _rights = _rightsOf(local.permissions);
      if (!_publishRights.isClosed) _publishRights.add(_rights);
    }

    if (outputDeviceId != null) await _selectOutput(outputDeviceId);
    await _applyMic();
  }

  @override
  Future<void> setMediaKey(VoiceMediaKey key) async {
    final provider = _keyProvider;
    if (provider == null) return;
    await provider.setSharedKey(
      String.fromCharCodes(key.key),
      keyIndex: key.index,
    );
    // Switch what this participant sends to the new key. Receivers already
    // hold it too, and still hold the old one for frames in flight.
    await _room?.e2eeManager?.setKeyIndex(key.index);
    // A publication whose frames failed may simply have been ahead of us.
    _failing.clear();
    await _reapplyVolumes();
    _reportEncryption();
  }

  @override
  Future<void> disconnect() async {
    _disconnectReported = true;
    await _closeRoom();
  }

  @override
  Future<void> setMicEnabled(bool enabled) async {
    _micWanted = enabled;
    await _applyMic();
  }

  @override
  Future<void> setParticipantVolume(String identity, double volume) async {
    final clamped = volume.clamp(0.0, maximumVolume).toDouble();
    _volumes[identity] = clamped;

    final participant = _room?.remoteParticipants[identity];
    if (participant == null) return;

    // Their voice only: a shared window's sound has its own volume.
    for (final publication in participant.audioTrackPublications) {
      if (_isScreen(publication)) continue;
      final track = publication.track;
      if (track == null) continue;
      await _setTrackVolume(
        track,
        _gateAudio(identity, publication.sid, clamped),
      );
    }
  }

  @override
  Future<void> setDefaultVolume(double volume) async {
    _defaultVolume = volume.clamp(0.0, maximumVolume).toDouble();
    // Everybody without a volume of their own follows it — and every shared
    // window without one, which is how deafening silences those too.
    await _reapplyVolumes();
  }

  @override
  Future<bool> setCameraEnabled(
    bool enabled, {
    VoiceCameraOptions? options,
  }) async {
    if (options != null) {
      _camera = options;
      _frontCamera = await _isFront(options.deviceId);
    }
    _cameraWanted = enabled;

    if (!enabled) {
      await _stopCamera();
      return true;
    }

    // The grant has to be in place first. Returning false rather than opening
    // the camera is what keeps a light from coming on for a camera nobody will
    // see; the caller asked the server for the grant and reports the wait.
    if (!_rights.camera) return false;

    await _applyCamera();
    return true;
  }

  @override
  Future<void> applyCameraOptions(VoiceCameraOptions options) async {
    final previous = _camera;
    _camera = options;
    if (previous.deviceId != options.deviceId) {
      _frontCamera = await _isFront(options.deviceId);
    }

    if (!_cameraWanted || !_rights.camera) return;

    // Swapping the effect leaves the capture alone; changing the camera or the
    // quality cannot, and other participants see that as a brief freeze.
    if (previous.needsRestartFor(options)) {
      // After any publish already running, which captured the old options.
      await _cameraApplying;
      await _applyCamera();
    } else {
      await _applyEffect();
    }
  }

  @override
  Future<void> setVideoVisible(String identity, bool visible) async {
    // Recorded whether or not they are here yet: the wish outlives the
    // publication, so somebody who republishes — or who joins after the wish
    // was made — is hidden before their first frame arrives.
    if (visible) {
      _videoHidden.remove(identity);
    } else {
      _videoHidden.add(identity);
    }

    final participant = _room?.remoteParticipants[identity];
    if (participant == null) return;

    // Their camera only: hiding somebody's camera says nothing about whether
    // their screen share is watched.
    for (final publication in participant.videoTrackPublications) {
      if (publication.source != TrackSource.camera) continue;
      await _applyVisibility(publication, visible);
    }

    _reportFeeds();
  }

  @override
  Future<bool> setScreenShareEnabled(
    bool enabled, {
    VoiceScreenShareOptions? options,
  }) async {
    if (!enabled || options == null) {
      await _stopScreenShare();
      return true;
    }

    // The grant has to be in place first, as with the camera: returning false
    // rather than starting the capture is what keeps a screen from being
    // captured for a share the media server would refuse.
    if (!_rights.screen) return false;
    if (options.withAudio && !_rights.screenAudio) return false;

    await _startScreenShare(options);
    return true;
  }

  @override
  Future<void> setScreenShareWatched(String identity, bool watched) async {
    // Recorded whether or not they are sharing yet, like a hidden camera.
    if (watched) {
      _watching.add(identity);
    } else {
      _watching.remove(identity);
    }

    final participant = _room?.remoteParticipants[identity];
    if (participant != null) {
      for (final publication in participant.trackPublications.values) {
        if (_isScreen(publication)) {
          await _applyVisibility(publication, watched);
        }
      }
    }

    _reportFeeds();
  }

  @override
  Future<void> setScreenShareVolume(String identity, double volume) async {
    _screenVolumes[identity] = volume.clamp(0.0, maximumVolume).toDouble();

    final participant = _room?.remoteParticipants[identity];
    if (participant == null) return;

    for (final publication in participant.audioTrackPublications) {
      if (!_isScreen(publication)) continue;
      final track = publication.track;
      if (track == null) continue;
      await _setTrackVolume(track, _volumeFor(participant, publication));
    }
  }

  @override
  Future<void> setInputDevice(String deviceId) async {
    final device = (await Hardware.instance.audioInputs())
        .where((d) => d.deviceId == deviceId)
        .firstOrNull;
    if (device != null) await _room?.setAudioInputDevice(device);
  }

  @override
  Future<void> setOutputDevice(String deviceId) => _selectOutput(deviceId);

  @override
  Future<void> applyProcessing(VoiceAudioProcessing processing) async {
    if (processing == _processing) return;
    _processing = processing;

    final local = _room?.localParticipant;
    if (local == null) return;

    for (final publication in local.audioTrackPublications) {
      await publication.track?.restartTrack(
        _captureOptions(_room?.roomOptions.defaultAudioCaptureOptions.deviceId),
      );
    }
  }

  @override
  Future<void> dispose() async {
    // Before the room goes: the effects hold a segmentation thread, and the
    // room disconnecting does not release it; the share's guards hold timers.
    await _effects.clear();
    // Nothing still starting may publish after this, and nothing is wanted
    // any more: a call that is over has no camera and no share to restore.
    _shareGeneration++;
    _sizeGuard?.stop();
    _sizeGuard = null;
    _endWatch?.stop();
    _endWatch = null;
    _share = const VoiceScreenShareState.off();
    _cameraWanted = false;
    _micWanted = false;
    await _listener?.dispose();
    _listener = null;
    await _closeRoom();
    await _micFailures.close();
    await _connectionStates.close();
    await _activeSpeakers.close();
    await _disconnects.close();
    await _publishRights.close();
    await _encryption.close();
    await _warnings.close();
    await _cameraStates.close();
    await _videoFeeds.close();
    await _untrustedVideo.close();
    await _screenShareStates.close();
    await _screenShares.close();
    await _untrustedScreenShares.close();
  }

  // ── Devices ────────────────────────────────────────────────────────────────

  static Future<List<AudioDevice>> inputs() async => [
    for (final d in await Hardware.instance.audioInputs())
      AudioDevice(id: d.deviceId, label: d.label),
  ];

  static Future<List<AudioDevice>> outputs() async => [
    for (final d in await Hardware.instance.audioOutputs())
      AudioDevice(id: d.deviceId, label: d.label),
  ];

  static Future<List<VideoDevice>> cameras() async => [
    for (final d in await Hardware.instance.videoInputs())
      VideoDevice(
        id: d.deviceId,
        label: d.label,
        isFront: _looksFrontFacing(d.label),
      ),
  ];

  /// The displays and windows this machine can share, for the share picker.
  static Future<VoiceScreenSources> screenSources() async {
    final sources = _LiveKitScreenSources();
    await sources._open();
    return sources;
  }

  /// A camera outside a call, for the camera-and-effects sheet.
  static Future<VoiceCameraPreview> preview(VoiceCameraOptions options) async {
    final preview = _LiveKitCameraPreview();
    await preview.apply(options);
    return preview;
  }

  /// Whether a camera faces the user, from its name.
  ///
  /// There is no flag for this: `getUserMedia` reports a label, and that is
  /// all. On a phone the labels are reliable ("front"/"user"); on a laptop the
  /// built-in camera is front-facing and almost everything is, so defaulting to
  /// true mirrors the common case correctly and the odd external camera reads
  /// as front too. Mirroring only ever affects what you see of yourself.
  static bool _looksFrontFacing(String label) {
    final name = label.toLowerCase();
    if (name.contains('back') ||
        name.contains('rear') ||
        name.contains('environment')) {
      return false;
    }
    return true;
  }

  static Future<bool> _isFront(String? deviceId) async {
    if (deviceId == null) return true;

    final device = (await cameras()).where((c) => c.id == deviceId).firstOrNull;
    return device?.isFront ?? true;
  }

  // ── Plumbing ───────────────────────────────────────────────────────────────

  /// Leaves the room and releases everything it holds, at once.
  ///
  /// Deliberately not `Room.disconnect()`: that sends LiveKit's leave and then
  /// waits — up to a fixed ten seconds — for the server to answer with a leave
  /// of its own, which a client-initiated leave does not reliably get, and
  /// only *after* that wait does it stop the local tracks. Hanging up through
  /// it left the microphone (and any camera or shared screen) capturing for
  /// ten seconds after the call had ended on screen, and then threw.
  ///
  /// So, in this order: stop capturing — microphone, camera, the shared
  /// screen and its sound — so every device light goes off whatever happens
  /// next; tell LiveKit we are leaving without waiting for an answer; and
  /// dispose the room, which closes both peer connections and the signalling
  /// socket. Raindrop's own `LeaveVoice` is what takes this participant out of
  /// the call for everybody else; the leave sent here only makes LiveKit
  /// notice sooner. Safe to call twice.
  Future<void> _closeRoom() async {
    final room = _room;
    _room = null;
    if (room == null) return;

    for (final publication
        in room.localParticipant?.trackPublications.values.toList() ??
            const <LocalTrackPublication>[]) {
      try {
        await publication.track?.stop();
      } on Object catch (e) {
        debugPrint('voice: could not stop a local track: $e');
      }
    }

    try {
      // `Room.disconnect()` minus its wait (see above). The engine is marked
      // internal; if an upgrade takes it away, disposing below still closes
      // every connection and Raindrop's leave still ends the call.
      // ignore: invalid_use_of_internal_member
      await room.engine.disconnect();
    } on Object catch (e) {
      debugPrint('voice: could not send the leave to the media server: $e');
    }

    try {
      await room.dispose();
    } on Object catch (e) {
      debugPrint('voice: the room did not close cleanly: $e');
    }
  }

  AudioCaptureOptions _captureOptions(String? deviceId) => AudioCaptureOptions(
    deviceId: deviceId,
    echoCancellation: _processing.echoCancellation,
    noiseSuppression: _processing.noiseSuppression,
    autoGainControl: _processing.autoGainControl,
  );

  void _listen(Room room) {
    final listener = room.createListener();
    _listener = listener;

    listener
      ..on<RoomReconnectingEvent>(
        (_) => _connectionStates.add(VoiceConnectionState.reconnecting),
      )
      ..on<RoomReconnectedEvent>(
        (_) => _connectionStates.add(VoiceConnectionState.connected),
      )
      ..on<RoomDisconnectedEvent>((event) {
        _connectionStates.add(VoiceConnectionState.disconnected);
        if (_disconnectReported &&
            event.reason != DisconnectReason.clientInitiated) {
          return;
        }
        _disconnectReported = true;
        _disconnects.add(_reasonOf(event.reason));
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        final identity = event.participant.identity;
        final sids = event.participant.trackPublications.keys;
        _unencrypted.remove(identity);
        _failing.removeAll(sids);
        _subscribeRetried.removeAll(sids);
        // `_watching` is left to the call controller, which drops it when
        // Raindrop says they left the call: the media server also reports a
        // participant gone when they are only rejoining after a network drop,
        // and that share should keep being watched.
        //
        // `_videoHidden` deliberately survives them leaving: it is the user's
        // standing wish about a person, not about a publication, and it is
        // persisted across restarts anyway.
        _reportEncryption();
        _reportFeeds();
      })
      ..on<ActiveSpeakersChangedEvent>(
        (event) => _activeSpeakers.add({
          for (final speaker in event.speakers) speaker.identity,
        }),
      )
      ..on<TrackPublishedEvent>((event) async {
        // Before anything is received: somebody who republishes their camera,
        // or who joins after they were hidden, must not come back visible —
        // and a screen share is not received at all until it is watched.
        final publication = event.publication;
        final identity = event.participant.identity;
        if (_isScreen(publication)) {
          if (!_watching.contains(identity)) {
            await _applyVisibility(publication, false);
          }
          _reportFeeds();
          return;
        }
        if (publication.kind != TrackType.VIDEO) return;
        if (_videoHidden.contains(identity)) {
          await _applyVisibility(publication, false);
        } else if (!publication.subscribed &&
            !_unencrypted.contains(identity)) {
          // A backstop for auto-subscribe: a camera nobody asked for is a tile
          // that never leaves its avatar. A no-op once it is on its way.
          await publication.subscribe();
        }
        _reportFeeds();
      })
      ..on<TrackUnpublishedEvent>((_) => _reportFeeds())
      ..on<TrackSubscribedEvent>((event) async {
        final identity = event.participant.identity;
        final publication = event.publication;

        // Fail closed: in an encrypted call, media published without
        // encryption is from somebody not using the group's key — the media
        // server itself, or a client that is not a member. A blocked codec
        // counts as unencrypted even when the publication claims otherwise,
        // because for those the frame cryptor is never set up at all.
        final trusted =
            _keyProvider == null ||
            (publication.encryptionType != EncryptionType.kNone &&
                !isBlockedVideoCodec(publication.mimeType));
        if (!trusted && _unencrypted.add(identity)) {
          _reportEncryption();
          // Untrusting a participant has to reach the media they already have
          // playing, not only the publication that gave them away: an
          // unencrypted camera is reason enough to stop trusting the
          // microphone that arrived before it.
          await _reapplyVolumes();
        }

        final unwatched =
            _isScreen(publication) && !_watching.contains(identity);

        switch (event.track) {
          case final RemoteAudioTrack track:
            // Untrusted audio arrives and is kept silent, rather than
            // refused: silence is the whole guarantee, and dropping the
            // subscription would lose the speaking indicator with it.
            await _setTrackVolume(
              track,
              _volumeFor(event.participant, publication),
            );
            if (unwatched) await _applyVisibility(publication, false);
            if (_isScreen(publication)) _reportFeeds();
          case RemoteVideoTrack _:
            // Untrusted video is never drawn, so it should not cost bandwidth
            // either — unlike audio there is nothing to keep it around for.
            if (!trusted) {
              await publication.unsubscribe();
            } else if (unwatched ||
                (publication.source == TrackSource.camera &&
                    _videoHidden.contains(identity))) {
              await _applyVisibility(publication, false);
            }
            _reportFeeds();
          case _:
        }
      })
      ..on<TrackE2EEStateEvent>((event) async {
        // By publication, not by participant: this fires per frame cryptor,
        // and a participant's microphone and camera each have their own.
        final sid = event.publication.sid;
        switch (event.state) {
          case E2EEState.kOk:
            if (_failing.remove(sid)) await _reapplyVolumes();
          case E2EEState.kDecryptionFailed ||
              E2EEState.kMissingKey ||
              E2EEState.kEncryptionFailed ||
              E2EEState.kInternalError:
            if (_failing.add(sid)) await _reapplyVolumes();
          case E2EEState.kNew || E2EEState.kKeyRatcheted:
        }
        _reportEncryption();
        // A camera that stops decrypting drops out of the feed list on the
        // spot, and its owner's tile says so instead of showing video.
        _reportFeeds();
      })
      ..on<LocalTrackPublishedEvent>((event) async {
        if (_keyProvider == null) return;
        final publication = event.publication;
        final screen = _isScreen(publication);
        if (publication.kind != TrackType.VIDEO && !screen) return;

        // Fail closed on the way out, which matters more than on the way in:
        // the receive side can only keep somebody else's mistake quiet, but
        // this is the only thing standing between a camera or a screen and
        // the media server seeing it. A publication the frame cryptor did not
        // take — a blocked codec, or encryption that never came up — is
        // withdrawn rather than left sending in the clear.
        final codec = publication.track?.codec ?? publication.mimeType;
        final blocked =
            publication.kind == TrackType.VIDEO && isBlockedVideoCodec(codec);
        if (!blocked && publication.encryptionType != EncryptionType.kNone) {
          return;
        }

        if (screen) {
          // Both halves go: a share's sound without its picture, or the other
          // way round, is not what the sharer agreed to send.
          await _stopScreenShare();
          if (!_warnings.isClosed) {
            _warnings.add(
              'Your screen share could not be encrypted, so it was stopped.',
            );
          }
          return;
        }

        await event.participant.removePublishedTrack(publication.sid);
        _cameraWanted = false;
        if (!_cameraStates.isClosed) _cameraStates.add(false);
        _reportEncryption();
        _reportFeeds();
        if (!_warnings.isClosed) {
          _warnings.add(
            'Your camera could not be encrypted, so it was turned off.',
          );
        }
      })
      ..on<LocalTrackUnpublishedEvent>((event) {
        _failing.remove(event.publication.sid);
        // A share the media server withdrew — its grant taken away — rather
        // than one this client stopped, which has already moved on.
        if (_share.on) {
          switch (event.publication.source) {
            case TrackSource.screenShareVideo:
              unawaited(_stopScreenShare());
            case TrackSource.screenShareAudio when _share.withAudio:
              _setShare(
                VoiceScreenShareState.sharing(_share.source!, withAudio: false),
              );
            case _:
          }
        }
        _reportFeeds();
      })
      ..on<TrackUnsubscribedEvent>((event) {
        _failing.remove(event.publication.sid);
        _reportFeeds();
      })
      // A camera whose subscription fails would otherwise just never get a
      // feed, and its owner's tile would quietly stay an avatar. Asked for
      // once more, and said out loud if that fails as well.
      ..on<TrackSubscriptionExceptionEvent>((event) async {
        final participant = event.participant;
        final sid = event.sid;
        if (participant != null && sid != null && _subscribeRetried.add(sid)) {
          final publication = participant.getTrackPublicationBySid(sid);
          if (publication != null &&
              !_unencrypted.contains(participant.identity)) {
            await publication.subscribe();
          }
        } else if (!_warnings.isClosed) {
          _warnings.add(
            "Somebody's video could not be received (${event.reason.name}).",
          );
        }
        _reportFeeds();
      })
      // Anything that can make a feed appear after it was first missed —
      // subscribing becoming allowed, a track resuming — rebuilds the list.
      ..on<TrackSubscriptionPermissionChangedEvent>((_) => _reportFeeds())
      ..on<TrackStreamStateUpdatedEvent>((_) => _reportFeeds())
      ..on<TrackMutedEvent>((_) => _reportFeeds())
      ..on<TrackUnmutedEvent>((_) => _reportFeeds())
      ..on<ParticipantPermissionsUpdatedEvent>((event) async {
        if (event.participant != room.localParticipant) return;

        final before = _rights;
        // Read before announcing the new rights: the call controller wakes on
        // that announcement and publishes the camera itself, so only a camera
        // that was already wanted (a reconnect, a grant given back) is this
        // handler's to publish.
        final cameraWantedBefore = _cameraWanted;
        _rights = _rightsOf(event.permissions);
        if (_rights != before && !_publishRights.isClosed) {
          _publishRights.add(_rights);
        }

        // Given the microphone back after a mute for everyone: send again if
        // this participant had it on.
        if (_rights.microphone && !before.microphone) await _applyMic();

        // The camera grant arriving is the second half of the handshake the
        // call controller started. It asked the server, the server told the
        // media server, and this is it coming back — so publish now.
        if (_rights.camera &&
            !before.camera &&
            cameraWantedBefore &&
            _cameraWanted &&
            _localCameraTrack == null) {
          await _applyCamera();
        }
        // And taken away: stop, rather than leave a track the media server has
        // stopped accepting.
        if (!_rights.camera && before.camera) await _stopCamera();

        // The same for a share. Losing only its sound — muted for everyone —
        // leaves the picture going: that is the server's rule, not a failure.
        if (!_rights.screen && before.screen && _share.on) {
          await _stopScreenShare();
        } else if (!_rights.screenAudio &&
            before.screenAudio &&
            _share.withAudio) {
          await _stopShareAudio();
          if (!_warnings.isClosed) {
            _warnings.add(
              "You can't be heard in this call right now, so your window's "
              'sound was stopped. The picture is still being shared.',
            );
          }
        }
      });
  }

  // ── The camera ─────────────────────────────────────────────────────────────

  /// What a permission update lets this participant send — the rule itself,
  /// including LiveKit's "empty means everything", is [voicePublishRightsOf].
  static VoicePublishRights _rightsOf(ParticipantPermissions permissions) =>
      voicePublishRightsOf(
        canPublish: permissions.canPublish,
        sources: permissions.canPublishSources.map((source) => source.value),
      );

  /// Whether a publication is half of a screen share — its picture or its
  /// sound.
  static bool _isScreen(TrackPublication publication) =>
      publication.source == TrackSource.screenShareVideo ||
      publication.source == TrackSource.screenShareAudio;

  /// Publishes the camera, joining a publish already in flight rather than
  /// starting a second one alongside it.
  Future<void> _applyCamera() {
    final running = _cameraApplying;
    if (running != null) return running;
    final applying = _applyCameraOnce();
    _cameraApplying = applying;
    return applying.whenComplete(() {
      if (identical(_cameraApplying, applying)) _cameraApplying = null;
    });
  }

  Future<void> _applyCameraOnce() async {
    final local = _room?.localParticipant;
    if (local == null) return;

    try {
      await local.setCameraEnabled(
        true,
        cameraCaptureOptions: _captureCamera(),
      );
      await _applyEffect();
      if (!_cameraStates.isClosed) _cameraStates.add(true);
    } on Object catch (e) {
      // A camera another app holds, or one the user declined: the call goes on
      // without it, and the caller takes the claim back off the server.
      _cameraWanted = false;
      if (!_cameraStates.isClosed) _cameraStates.add(false);
      if (!_warnings.isClosed) {
        _warnings.add('Your camera could not be opened ($e).');
      }
    }

    _reportFeeds();
  }

  Future<void> _stopCamera() async {
    // Before the track goes: detaching needs the track to still be there, and
    // the handle holds a segmentation thread that has to be let go either way.
    await _effects.clear();

    final local = _room?.localParticipant;
    if (local != null) {
      try {
        await local.setCameraEnabled(false);
      } on Object {
        // Already gone, or never published. Nothing to undo.
      }
    }

    if (!_cameraStates.isClosed) _cameraStates.add(false);
    _reportFeeds();
  }

  // ── The screen share ───────────────────────────────────────────────────────

  /// How a share is sent. Stated in full rather than inherited, for the same
  /// reason as the room's camera options — the codec is a security setting
  /// here — plus what makes a share a share: its own bitrate and frame rate,
  /// and keeping the resolution when bandwidth runs short, because text that
  /// goes soft is unreadable while text that updates a little less often is
  /// not.
  static const _screenPublish = VideoPublishOptions(
    name: VideoPublishOptions.defaultScreenShareName,
    videoCodec: _videoCodec,
    simulcast: true,
    backupVideoCodec: BackupVideoCodec(
      enabled: true,
      codec: _videoCodec,
      simulcast: true,
    ),
    screenShareEncoding: VideoEncoding(
      maxBitrate: screenShareMaxBitrate,
      maxFramerate: screenShareFrameRate,
    ),
    degradationPreference: DegradationPreference.maintainResolution,
  );

  /// How a shared window's sound is sent: as music, not speech. The room's
  /// microphone options are tuned for a voice — a low bitrate, and nothing
  /// sent in silence — which would cut a film's quiet passages to nothing.
  static const _screenAudioPublish = AudioPublishOptions(
    name: 'screenshare_audio',
    encoding: AudioEncoding.presetMusic,
    dtx: false,
  );

  Future<void> _startScreenShare(VoiceScreenShareOptions options) async {
    final local = _room?.localParticipant;
    if (local == null) return;

    // One share at a time: a new source replaces the old one.
    await _stopScreenShare();
    final generation = ++_shareGeneration;

    final capture = ScreenShareCaptureOptions(
      sourceId: options.source.id,
      maxFrameRate: screenShareFrameRate.toDouble(),
      params: VideoParametersPresets.screenShareH1080FPS15,
    );

    final List<LocalTrack> tracks;
    try {
      // Sound is asked for only for a window its sharer agreed to send it from
      // — [VoiceScreenShareOptions] drops it for a screen before it gets here.
      tracks = options.withAudio
          ? await LocalVideoTrack.createScreenShareTracksWithAudio(capture)
          : [await LocalVideoTrack.createScreenShareTrack(capture)];
    } on Object catch (e) {
      if (!_warnings.isClosed) {
        _warnings.add('Your screen could not be captured ($e).');
      }
      _setShare(const VoiceScreenShareState.off());
      return;
    }

    final video = tracks.whereType<LocalVideoTrack>().first;
    final audio = tracks.whereType<LocalAudioTrack>().firstOrNull;

    // What this start has published, so that if it is stopped or replaced
    // while publishing is still in flight, exactly that is taken down again —
    // by publication, never by source, which would take a newer share's down
    // with it — and nothing is left capturing.
    final published = <String>[];
    Future<void> abandon() async {
      for (final sid in published) {
        try {
          await local.removePublishedTrack(sid);
        } on Object {
          // Already gone.
        }
      }
      await _release(tracks);
    }

    if (generation != _shareGeneration) {
      await abandon();
      return;
    }

    try {
      published.add(
        (await local.publishVideoTrack(
          video,
          publishOptions: _screenPublish,
        )).sid,
      );
      if (generation != _shareGeneration) {
        await abandon();
        return;
      }

      // Before the first frames go far: the guard is what keeps a 4K screen
      // from going out at 4K.
      _sizeGuard = _ScreenSizeGuard(video)..start();

      var withAudio = false;
      if (audio != null) {
        if (_rights.screenAudio) {
          published.add(
            (await local.publishAudioTrack(
              audio,
              publishOptions: _screenAudioPublish,
            )).sid,
          );
          withAudio = true;
        } else {
          await _release([audio]);
        }
      }
      if (generation != _shareGeneration) {
        await abandon();
        return;
      }

      if (options.withAudio && !withAudio && !_warnings.isClosed) {
        _warnings.add(
          "This window's sound couldn't be captured, so only the picture is "
          'being shared.',
        );
      }

      if (options.source.kind == VoiceScreenSourceKind.window) {
        _endWatch = _ShareEndWatch(options.source.id, () {
          if (generation != _shareGeneration) return;
          unawaited(_stopScreenShare());
          if (!_warnings.isClosed) {
            _warnings.add('The window you were sharing closed.');
          }
        })..start();
      }

      _setShare(
        VoiceScreenShareState.sharing(options.source, withAudio: withAudio),
      );
    } on Object catch (e) {
      if (generation == _shareGeneration) {
        await _stopScreenShare();
        if (!_warnings.isClosed) {
          _warnings.add('Your screen could not be shared ($e).');
        }
      }
      // Whatever failed, the capture this start opened is closed: a window's
      // sound left recording with nowhere to go is still a recording.
      await abandon();
    }

    _reportFeeds();
  }

  /// Stops the share, picture and sound. Safe at any point: the state goes to
  /// off *before* anything is unpublished, so the unpublish events this causes
  /// are not mistaken for the media server withdrawing it.
  Future<void> _stopScreenShare() async {
    _shareGeneration++;
    _sizeGuard?.stop();
    _sizeGuard = null;
    _endWatch?.stop();
    _endWatch = null;

    final wasOn = _share.on;
    _setShare(const VoiceScreenShareState.off());

    final local = _room?.localParticipant;
    if (local != null) {
      try {
        // Removes the sound with the picture: that is LiveKit's own rule for
        // a screen share, and the right one.
        await local.setScreenShareEnabled(false);
      } on Object {
        // Never published, or already gone. Nothing to undo.
      }
    }

    if (wasOn) _reportFeeds();
  }

  /// Stops only a share's sound, leaving its picture going.
  Future<void> _stopShareAudio() async {
    final source = _share.source;
    if (source == null) return;
    _setShare(VoiceScreenShareState.sharing(source, withAudio: false));

    final local = _room?.localParticipant;
    final publication = local?.getTrackPublicationBySource(
      TrackSource.screenShareAudio,
    );
    if (local == null || publication == null) return;
    try {
      await local.removePublishedTrack(publication.sid);
    } on Object {
      // The media server already took it.
    }
  }

  void _setShare(VoiceScreenShareState share) {
    _share = share;
    if (!_screenShareStates.isClosed) _screenShareStates.add(share);
  }

  static Future<void> _release(Iterable<LocalTrack> tracks) async {
    for (final track in tracks) {
      try {
        await track.stop();
        await track.dispose();
      } on Object {
        // Already released.
      }
    }
  }

  /// Installs, changes or removes the effects on the camera that is running.
  ///
  /// The one place the effects touch a call. Everything about how they work
  /// lives in [_TrackEffects]; what this knows is which track is currently
  /// publishing and what the user asked for.
  Future<void> _applyEffect() async {
    final warning = await _effects.apply(_localCameraTrack, _camera.effect);
    if (warning != null && !_warnings.isClosed) _warnings.add(warning);
  }

  /// The camera track this participant is publishing, if any.
  LocalVideoTrack? get _localCameraTrack {
    for (final publication
        in _room?.localParticipant?.videoTrackPublications ??
            const <LocalTrackPublication<LocalVideoTrack>>[]) {
      if (publication.source == TrackSource.camera) return publication.track;
    }
    return null;
  }

  CameraCaptureOptions _captureCamera() => CameraCaptureOptions(
    deviceId: _camera.deviceId,
    params: switch (_camera.quality) {
      VoiceVideoQuality.sd360 => VideoParametersPresets.h360_169,
      VoiceVideoQuality.sd540 => VideoParametersPresets.h540_169,
      VoiceVideoQuality.hd720 => VideoParametersPresets.h720_169,
    },
  );

  /// Stops or starts receiving one publication.
  ///
  /// `disable` rather than `unsubscribe`: it tells the media server to stop
  /// forwarding this track *to this subscriber*, so the bandwidth really goes
  /// away, while the subscription and its frame cryptor stay set up — which
  /// makes showing the camera again immediate rather than a renegotiation.
  /// `unsubscribe` is kept for a track that must never come back, which is the
  /// untrusted case.
  static Future<void> _applyVisibility(
    RemoteTrackPublication publication,
    bool visible,
  ) async {
    if (visible) {
      await publication.enable();
    } else {
      await publication.disable();
    }
  }

  /// Rebuilds the whole feed list, this device's own camera first.
  ///
  /// The whole list rather than a diff, like [activeSpeakers], so nothing
  /// downstream has to merge — and so a feed that stopped being trusted
  /// disappears by simply not being included.
  void _reportFeeds() {
    if (_videoFeeds.isClosed) return;

    final room = _room;
    final local = room?.localParticipant;
    if (room == null) {
      _videoFeeds.add(const []);
      return;
    }

    final feeds = <VoiceVideoFeed>[];

    if (local != null) {
      for (final publication in local.videoTrackPublications) {
        final track = publication.track;
        if (track == null) continue;
        final screen = _isScreen(publication);
        feeds.add(
          _LiveKitVideoFeed(
            identity: local.identity,
            track: track,
            isLocal: true,
            kind: screen ? VoiceVideoKind.screen : VoiceVideoKind.camera,
            // Only a camera is a mirror; a mirrored screen is unreadable.
            mirror: !screen && _frontCamera,
          ),
        );
      }
    }

    for (final participant in room.remoteParticipants.values) {
      final identity = participant.identity;
      if (_unencrypted.contains(identity)) continue;

      for (final publication in participant.videoTrackPublications) {
        final track = publication.track;
        if (track == null) continue;
        if (_failing.contains(publication.sid)) continue;
        if (!publication.subscribed) continue;

        // The wishes, not `publication.enabled`: see the room options.
        final screen = _isScreen(publication);
        if (screen
            ? !_watching.contains(identity)
            : _videoHidden.contains(identity)) {
          continue;
        }

        feeds.add(
          _LiveKitVideoFeed(
            identity: identity,
            track: track,
            isLocal: false,
            kind: screen ? VoiceVideoKind.screen : VoiceVideoKind.camera,
          ),
        );
      }
    }

    _videoFeeds.add(feeds);
    _reportUntrustedVideo();
    _reportScreenShares();
  }

  void _reportUntrustedVideo() {
    if (_untrustedVideo.isClosed) return;

    final room = _room;
    if (room == null) {
      _untrustedVideo.add(const {});
      return;
    }

    final untrusted = <String>{};
    for (final participant in room.remoteParticipants.values) {
      for (final publication in participant.videoTrackPublications) {
        if (publication.source != TrackSource.camera) continue;
        if (_unencrypted.contains(participant.identity) ||
            _failing.contains(publication.sid)) {
          untrusted.add(participant.identity);
        }
      }
    }

    _untrustedVideo.add(untrusted);
  }

  /// Who is sharing a screen, and whose share is not to be trusted. A share is
  /// counted from the moment it is published, watched or not — that is what
  /// lets somebody choose to watch it.
  void _reportScreenShares() {
    if (_screenShares.isClosed || _untrustedScreenShares.isClosed) return;

    final sharing = <String>{};
    final untrusted = <String>{};

    for (final participant
        in _room?.remoteParticipants.values ?? const <RemoteParticipant>[]) {
      for (final publication in participant.videoTrackPublications) {
        if (publication.source != TrackSource.screenShareVideo) continue;
        if (_unencrypted.contains(participant.identity) ||
            _failing.contains(publication.sid)) {
          untrusted.add(participant.identity);
        } else {
          sharing.add(participant.identity);
        }
      }
    }

    _screenShares.add(sharing);
    _untrustedScreenShares.add(untrusted);
  }

  /// One publication's volume, or silence while it is not trusted.
  double _gateAudio(String identity, String sid, double volume) => gatedVolume(
    volume: volume,
    unencrypted: _unencrypted.contains(identity),
    undecryptable: _failing.contains(sid),
  );

  /// What one audio publication should play at: their voice at their volume,
  /// their shared window at its own — and either silent while untrusted.
  double _volumeFor(
    RemoteParticipant participant,
    TrackPublication publication,
  ) {
    final identity = participant.identity;
    final wanted = _isScreen(publication)
        ? _screenVolumes[identity] ?? _defaultVolume
        : _volumes[identity] ?? _defaultVolume;
    return _gateAudio(identity, publication.sid, wanted);
  }

  Future<void> _reapplyVolumes() async {
    for (final participant
        in _room?.remoteParticipants.values ?? const <RemoteParticipant>[]) {
      for (final publication in participant.audioTrackPublications) {
        final track = publication.track;
        if (track == null) continue;
        await _setTrackVolume(track, _volumeFor(participant, publication));
      }
    }
  }

  void _reportEncryption() {
    if (_encryption.isClosed) return;
    _encryption.add(
      _keyProvider == null
          ? VoiceEncryption.none
          : _unencrypted.isEmpty && _failing.isEmpty
          ? VoiceEncryption.active
          : VoiceEncryption.degraded,
    );
  }

  /// Opens or closes the microphone, and never throws for failing to.
  ///
  /// Capture can fail for reasons that have nothing to do with this call —
  /// another app holding the microphone, no input device at all — and it is
  /// reached from a connect, a settings change and a permissions event, none
  /// of which should end a call that is otherwise working. So a failure is
  /// reported on [microphoneFailures] and the call carries on without this
  /// participant's audio.
  Future<void> _applyMic() async {
    final local = _room?.localParticipant;
    if (local == null) return;

    if (_micWanted && !_rights.microphone) return;
    try {
      await local.setMicrophoneEnabled(_micWanted);
    } on Object catch (e) {
      // Turning it *off* is not worth reporting: it is already not being
      // heard, which is what was asked for.
      if (!_micWanted) return;
      debugPrint('voice: could not open the microphone: $e');
      if (!_micFailures.isClosed) _micFailures.add(null);
    }
  }

  @override
  Future<void> setSpeakerphone(bool enabled) async {
    if (!AudioManager.instance.canSwitchSpeakerphone) return;
    // Not forced: a headset or a Bluetooth earpiece that is plugged in still
    // wins, which is what somebody putting one on expects.
    await AudioManager.instance.setSpeakerOutputPreferred(enabled);
  }

  Future<void> _selectOutput(String deviceId) async {
    final device = (await Hardware.instance.audioOutputs())
        .where((d) => d.deviceId == deviceId)
        .firstOrNull;
    if (device != null) await _room?.setAudioOutputDevice(device);
  }

  /// libwebrtc's source volume is a gain: 1 is as sent, 0 silent.
  static Future<void> _setTrackVolume(RemoteAudioTrack track, double volume) =>
      rtc.Helper.setVolume(volume, track.mediaStreamTrack);

  static VoiceDisconnectReason _reasonOf(DisconnectReason? reason) =>
      switch (reason) {
        DisconnectReason.clientInitiated =>
          VoiceDisconnectReason.clientInitiated,
        DisconnectReason.duplicateIdentity =>
          VoiceDisconnectReason.replacedByOtherDevice,
        DisconnectReason.participantRemoved =>
          VoiceDisconnectReason.removedByServer,
        DisconnectReason.roomDeleted ||
        DisconnectReason.serverShutdown => VoiceDisconnectReason.callEnded,
        DisconnectReason.joinFailure ||
        DisconnectReason.signalingConnectionFailure ||
        DisconnectReason.reconnectAttemptsExceeded ||
        DisconnectReason.disconnected ||
        DisconnectReason.signalClose ||
        DisconnectReason.stateMismatch => VoiceDisconnectReason.networkFailure,
        _ => VoiceDisconnectReason.unknown,
      };
}

/// A [VoiceVideoFeed] over one LiveKit track.
///
/// The feed *is* the renderer factory, which is what keeps `livekit_client` and
/// `flutter_webrtc` inside this file: a tile in `features/voice/` is handed one
/// of these and asks it to build a surface, so no widget outside `core/voice/`
/// ever names a track type.
class _LiveKitVideoFeed implements VoiceVideoFeed {
  const _LiveKitVideoFeed({
    required this.identity,
    required this.track,
    required this.isLocal,
    this.kind = VoiceVideoKind.camera,
    this.mirror = false,
  });

  final VideoTrack track;

  @override
  final String identity;

  @override
  final VoiceVideoKind kind;

  @override
  final bool isLocal;

  @override
  final bool mirror;

  @override
  bool get live => !track.muted;

  @override
  Widget buildSurface(BuildContext context, {BoxFit fit = BoxFit.cover}) =>
      VideoTrackRenderer(
        track,
        fit: fit == BoxFit.contain ? VideoViewFit.contain : VideoViewFit.cover,
        // Decided here rather than left to `auto`, because auto mirrors any
        // local track and the back camera on a phone must not be mirrored.
        mirrorMode: mirror
            ? VideoViewMirrorMode.mirror
            : VideoViewMirrorMode.off,
      );
}

/// A camera running outside a call, for the camera-and-effects sheet.
///
/// It publishes nothing and touches no room: the sheet is reachable from
/// settings with no call in progress, and opening a preview must not need one.
/// The camera effects on one running track: the Rust handle and the native
/// processor that calls into it.
///
/// The two are kept together because neither half is any use alone — a
/// processor left on the track after the handle is destroyed calls into
/// nothing, and a handle left behind after the processor is gone holds a
/// segmentation thread for a camera that has stopped.
///
/// Used by both the call and the camera-and-effects sheet's preview, which is
/// what makes the preview an honest preview: the same effect, applied the same
/// way, to a track that simply is not published.
class _TrackEffects {
  CameraEffects? _running;

  /// The track the processor is attached to, remembered rather than looked up,
  /// because detaching has to name the track it was attached to even after that
  /// track has stopped.
  String? _trackId;

  /// Whether the platform can take a processor at all. Asked once: the answer
  /// is a property of the build, and asking per frame-rate change would be a
  /// method channel round trip for a constant.
  static Future<bool>? _supported;

  static Future<bool> get _platformSupports =>
      _supported ??= RaindropCameraEffects.isSupported;

  /// Applies [effect] to [track], and returns a warning to show the user when
  /// it could not be — never throws. A camera without its effect is still a
  /// camera, and the call carries on.
  Future<String?> apply(
    LocalVideoTrack? track,
    VoiceCameraEffect effect,
  ) async {
    final wanted = effect.effective(effectsAvailable: cameraEffectsAvailable);

    if (track == null || wanted == VoiceCameraEffectKind.none) {
      await clear();
      return null;
    }

    if (!await _platformSupports) {
      await clear();
      return null;
    }

    final trackId = track.mediaStreamTrack.id;
    if (trackId == null) {
      // Nothing to look the track up by on the native side, so there is
      // nowhere to put the processor.
      await clear();
      return null;
    }

    // Already running on this very track: the effect changes under it, with no
    // new processor and no restart, which is the whole point of doing this on
    // the frames rather than on the capture.
    if (_running case final running? when _trackId == trackId) {
      try {
        await running.apply(effect);
        return null;
      } on CameraEffectsFailure catch (failure) {
        await clear();
        return 'Your camera effect was turned off (${failure.message}).';
      }
    }

    await clear();

    try {
      final effects = await CameraEffects.start(effect);
      if (effects == null) return null;

      await RaindropCameraEffects.attach(
        trackId: trackId,
        processAddress: effects.processAddress,
        context: effects.context,
      );

      _running = effects;
      _trackId = trackId;
      return null;
    } on CameraEffectsFailure catch (failure) {
      await clear();
      return 'Your camera effect could not be applied (${failure.message}).';
    } on CameraEffectsUnavailable catch (failure) {
      await clear();
      return 'Your camera effect could not be applied (${failure.reason}).';
    }
  }

  /// What the effects are costing, or null when none are running.
  ///
  /// Read by the preview, which waits for the first mask before it shows
  /// anything: until one has been produced the frames go through untouched,
  /// which looks exactly like the effect not working.
  Future<CameraEffectsLoad?> load() async {
    try {
      return await _running?.load();
    } on CameraEffectsFailure {
      return null;
    }
  }

  /// Takes the processor off and releases the effects. Safe at any point, and
  /// in this order: the pipeline must stop calling before the handle goes.
  Future<void> clear() async {
    if (_trackId case final trackId?) {
      _trackId = null;
      await RaindropCameraEffects.detach(trackId: trackId);
    }

    final running = _running;
    _running = null;
    await running?.dispose();
  }
}

class _LiveKitCameraPreview implements VoiceCameraPreview {
  LocalVideoTrack? _track;
  VoiceCameraOptions _options = const VoiceCameraOptions();
  bool _front = true;
  final _effects = _TrackEffects();

  @override
  VoiceVideoFeed get feed => _LiveKitVideoFeed(
    identity: 'preview',
    track: _track!,
    isLocal: true,
    mirror: _front,
  );

  @override
  Future<void> apply(VoiceCameraOptions options) async {
    final previous = _options;
    _options = options;
    _front = await LiveKitVoiceEngine._isFront(options.deviceId);

    // The effect is not a property of the capture, so only a different camera
    // or quality reopens it.
    if (_track != null && !previous.needsRestartFor(options)) {
      _warning = await _effects.apply(_track, options.effect);
      return;
    }

    await _stop();
    _track = await LocalVideoTrack.createCameraTrack(
      CameraCaptureOptions(
        deviceId: options.deviceId,
        params: switch (options.quality) {
          VoiceVideoQuality.sd360 => VideoParametersPresets.h360_169,
          VoiceVideoQuality.sd540 => VideoParametersPresets.h540_169,
          VoiceVideoQuality.hd720 => VideoParametersPresets.h720_169,
        },
      ),
    );
    _warning = await _effects.apply(_track, options.effect);
  }

  String? _warning;

  @override
  String? get warning => _warning;

  @override
  Future<CameraEffectsLoad?> load() => _effects.load();

  @override
  Future<void> dispose() => _stop();

  Future<void> _stop() async {
    await _effects.clear();

    final track = _track;
    _track = null;
    if (track == null) return;

    try {
      await track.stop();
      await track.dispose();
    } on Object {
      // A camera already taken away by the OS. Nothing left to release.
    }
  }
}

/// The displays and windows this machine can share, kept current for the
/// share picker.
///
/// flutter_webrtc reports a source appearing, going or changing only when it
/// is asked to look again, so this asks every few seconds while the picker is
/// open, and stops when it closes.
class _LiveKitScreenSources implements VoiceScreenSources {
  final _sources = StreamController<List<VoiceScreenSource>>.broadcast();
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _byId = <String, rtc.DesktopCapturerSource>{};
  List<VoiceScreenSource> _current = const [];
  Timer? _refresh;
  bool _disposed = false;
  bool _allowed = true;

  static const _types = [rtc.SourceType.Screen, rtc.SourceType.Window];

  @override
  Stream<List<VoiceScreenSource>> get sources => _sources.stream;

  @override
  List<VoiceScreenSource> get current => _current;

  @override
  bool get captureAllowed => _allowed;

  Future<void> _open() async {
    // Asked here, as the picker opens, so the system's prompt comes up while
    // the user is choosing what to share rather than in the middle of a call.
    if (needsScreenCapturePermission) {
      try {
        _allowed = await rtc.Helper.requestCapturePermission();
      } on Object {
        _allowed = false;
      }
      if (!_allowed) {
        _emit();
        return;
      }
    }

    final listed = await rtc.desktopCapturer.getSources(
      types: _types,
      thumbnailSize: rtc.ThumbnailSize(320, 180),
    );
    for (final source in listed) {
      _byId[source.id] = source;
    }

    final capturer = rtc.desktopCapturer;
    _subscriptions
      ..add(
        capturer.onAdded.stream.listen((source) {
          _byId[source.id] = source;
          _emit();
        }),
      )
      ..add(
        capturer.onRemoved.stream.listen((source) {
          _byId.remove(source.id);
          _emit();
        }),
      )
      ..add(capturer.onNameChanged.stream.listen((_) => _emit()))
      ..add(capturer.onThumbnailChanged.stream.listen((_) => _emit()));

    _refresh = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        await capturer.updateSources(types: _types);
      } on Object {
        // The next look will do.
      }
    });

    _emit();
  }

  void _emit() {
    if (_disposed) return;
    _current = [
      for (final source in _byId.values)
        VoiceScreenSource(
          id: source.id,
          name: source.name,
          kind: source.type == rtc.SourceType.Window
              ? VoiceScreenSourceKind.window
              : VoiceScreenSourceKind.screen,
          thumbnail: source.thumbnail,
        ),
    ];
    _sources.add(_current);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _refresh?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _sources.close();
  }
}

/// Keeps a running share inside the 1080p box.
///
/// The only thing that actually enforces the cap. livekit_client cannot: on
/// desktop it works out a share's encodings from the size it *asked* the
/// capturer for, not the size it got (`getSettings()` is read on web and
/// mobile only — `participant/local.dart` in 2.13.0), and it never scales the
/// top layer below the source anyway. The desktop capturers ignore size
/// constraints too. Left alone, a 4K screen goes out at 4K.
///
/// So this reads the size actually being captured from the sender's own
/// statistics and scales every layer down by [screenShareScale] — and again
/// whenever that size changes, since windows are resized and displays change
/// mode. For the first quarter of a second or so the source can go out
/// unscaled; [screenShareMaxBitrate] bounds the bandwidth even then.
class _ScreenSizeGuard {
  _ScreenSizeGuard(this._track);

  final LocalVideoTrack _track;
  Timer? _timer;
  bool _stopped = false;
  bool _busy = false;

  /// Each layer's own scale as LiveKit set it, by rid, read once — so what is
  /// applied is always LiveKit's layer times the cap, never compounded.
  Map<String?, double>? _layers;

  /// The cap last applied; 0 until the first.
  double _applied = 0;

  /// Quickly at first, to catch the first frames; once the size is known,
  /// only a change matters, and that can wait a little.
  static const _searching = Duration(milliseconds: 250);
  static const _watching = Duration(seconds: 2);

  void start() {
    _timer = Timer.periodic(_searching, (_) => unawaited(_tick()));
  }

  void stop() {
    _stopped = true;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    final sender = _track.sender;
    if (_stopped || _busy || sender == null) return;

    _busy = true;
    try {
      final size = _sourceSize(await sender.getStats());
      if (size == null || _stopped) return;

      if (_applied == 0) {
        _timer?.cancel();
        _timer = Timer.periodic(_watching, (_) => unawaited(_tick()));
      }

      final scale = screenShareScale(width: size.width, height: size.height);
      if (_applied != 0 && (scale - _applied).abs() / _applied < 0.01) return;

      final parameters = sender.parameters;
      final encodings = parameters.encodings;
      if (encodings == null || encodings.isEmpty) return;

      final layers = _layers ??= {
        for (final encoding in encodings)
          encoding.rid: encoding.scaleResolutionDownBy ?? 1.0,
      };
      for (final encoding in encodings) {
        encoding.scaleResolutionDownBy = (layers[encoding.rid] ?? 1.0) * scale;
      }

      if (await sender.setParameters(parameters)) _applied = scale;
    } on Object {
      // Statistics or parameters not ready yet: the next tick tries again.
    } finally {
      _busy = false;
    }
  }

  /// The size being captured: the `media-source` statistic, which is the
  /// capturer's own output. Failing that, the largest layer being encoded,
  /// scaled back up by what has been applied to it.
  ({int width, int height})? _sourceSize(List<rtc.StatsReport> reports) {
    for (final report in reports) {
      if (report.type != 'media-source') continue;
      final width = _whole(report.values['width']);
      final height = _whole(report.values['height']);
      if (width != null && height != null) {
        return (width: width, height: height);
      }
    }

    ({int width, int height})? largest;
    var scaledBy = 1.0;
    for (final report in reports) {
      if (report.type != 'outbound-rtp') continue;
      final width = _whole(report.values['frameWidth']);
      final height = _whole(report.values['frameHeight']);
      if (width == null || height == null) continue;
      if (largest != null && width * height <= largest.width * largest.height) {
        continue;
      }
      largest = (width: width, height: height);
      final rid = report.values['rid'];
      scaledBy =
          (_layers?[rid is String ? rid : null] ?? 1.0) *
          (_applied == 0 ? 1.0 : _applied);
    }

    if (largest == null) return null;
    return (
      width: (largest.width * scaledBy).round(),
      height: (largest.height * scaledBy).round(),
    );
  }

  static int? _whole(Object? value) =>
      value is num && value > 0 ? value.round() : null;
}

/// Notices that the window being shared has closed.
///
/// The desktop capturers do not say so — their stop and error callbacks only
/// log — and watching for frames to stop would be wrong for a screen, which on
/// macOS sends nothing at all while nothing on it changes. A window that has
/// closed drops out of the window list, so that is what is watched.
class _ShareEndWatch {
  _ShareEndWatch(this._sourceId, this._onGone);

  final String _sourceId;
  final void Function() _onGone;
  Timer? _timer;
  StreamSubscription<rtc.DesktopCapturerSource>? _removed;
  bool _done = false;

  void start() {
    _removed = rtc.desktopCapturer.onRemoved.stream.listen((source) {
      if (source.id == _sourceId) _gone();
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        await rtc.desktopCapturer.updateSources(types: [rtc.SourceType.Window]);
      } on Object {
        // The next look will do.
      }
    });
  }

  void _gone() {
    if (_done) return;
    stop();
    _onGone();
  }

  void stop() {
    _done = true;
    _timer?.cancel();
    unawaited(_removed?.cancel());
  }
}

/// LiveKit's key provider, made to remember which slot the shared key is in.
///
/// Every frame cryptor LiveKit creates — one per track, at the moment it is
/// published — starts on `getLatestIndex`. In shared-key mode
/// [BaseKeyProvider.setSharedKey] never records the slot it was given, so that
/// answer is always 0. The call's key sits in slot `epoch mod 16`, so a camera
/// or a screen share started after joining was encrypting with an empty slot:
/// every frame was dropped as `kMissingKey`, nothing reached the media server,
/// and nobody else ever saw the track. `E2EEManager.setKeyIndex` cannot cover
/// it, because it only reaches the cryptors that already exist when it runs.
class _SharedKeyProvider extends BaseKeyProvider {
  _SharedKeyProvider.from(BaseKeyProvider base)
    : super(base.keyProvider, base.options);

  int _index = 0;

  @override
  int getLatestIndex(String participantId) => _index;

  @override
  Future<void> setSharedKey(String key, {int? keyIndex}) async {
    await super.setSharedKey(key, keyIndex: keyIndex);
    _index = keyIndex ?? 0;
  }
}
