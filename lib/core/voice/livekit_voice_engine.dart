/// [VoiceEngine] on LiveKit. The only file in the app that imports
/// `livekit_client` or `flutter_webrtc`.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';

import 'voice_engine.dart';

class LiveKitVoiceEngine implements VoiceEngine {
  /// The transport name the server uses for LiveKit.
  static const transportName = 'livekit';

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
  final _encryption = StreamController<VoiceEncryption>.broadcast();
  final _warnings = StreamController<String>.broadcast();
  final _cameraStates = StreamController<bool>.broadcast();
  final _videoFeeds = StreamController<List<VoiceVideoFeed>>.broadcast();
  final _untrustedVideo = StreamController<Set<String>>.broadcast();

  /// What the server currently lets this participant send. Kept rather than
  /// derived on demand, because the camera handshake has to know whether a
  /// grant is already in place before it decides to wait for one.
  VoicePublishRights _rights = VoicePublishRights.none;

  /// What the camera was last asked to be, and with what. Remembered so a
  /// track republished after a reconnect comes back with the same choice.
  bool _cameraWanted = false;
  VoiceCameraOptions _camera = const VoiceCameraOptions();

  /// Whether the chosen camera faces the user, which is the only thing that
  /// decides whether their own picture is mirrored. Resolved from the device
  /// list when the camera is chosen, since a capture track does not say.
  bool _frontCamera = true;

  /// Participants whose camera this device is not to receive. A wish, not a
  /// state: it is re-applied whenever they publish, so hiding somebody does not
  /// leak the moment they turn their camera off and on again.
  final _videoHidden = <String>{};

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
  Stream<VoiceEncryption> get encryptionChanges => _encryption.stream;

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
      final provider = await BaseKeyProvider.create(
        sharedKey: true,
        ratchetWindowSize: 0,
        failureTolerance: -1,
        keyRingSize: keyRingSize,
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
        // Audio only: nothing to adapt or dynacast.
        adaptiveStream: false,
        dynacast: false,
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
    await _room?.disconnect();
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

    for (final publication in participant.audioTrackPublications) {
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

    for (final participant
        in _room?.remoteParticipants.values ?? const <RemoteParticipant>[]) {
      if (_volumes.containsKey(participant.identity)) continue;
      for (final publication in participant.audioTrackPublications) {
        final track = publication.track;
        if (track == null) continue;
        await _setTrackVolume(
          track,
          _gateAudio(participant.identity, publication.sid, _defaultVolume),
        );
      }
    }
  }

  @override
  Future<bool> setCameraEnabled(bool enabled, {VoiceCameraOptions? options}) async {
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

    for (final publication in participant.videoTrackPublications) {
      await _applyVisibility(publication, visible);
    }

    _reportFeeds();
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
    await _listener?.dispose();
    _listener = null;
    await _room?.disconnect();
    await _room?.dispose();
    _room = null;
    await _connectionStates.close();
    await _activeSpeakers.close();
    await _disconnects.close();
    await _publishRights.close();
    await _encryption.close();
    await _warnings.close();
    await _cameraStates.close();
    await _videoFeeds.close();
    await _untrustedVideo.close();
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
    if (name.contains('back') || name.contains('rear') || name.contains('environment')) {
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
        _unencrypted.remove(event.participant.identity);
        _failing.removeAll(event.participant.trackPublications.keys);
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
        // or who joins after they were hidden, must not come back visible.
        if (event.publication.kind != TrackType.VIDEO) return;
        if (_videoHidden.contains(event.participant.identity)) {
          await _applyVisibility(event.publication, false);
        }
      })
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

        switch (event.track) {
          case final RemoteAudioTrack track:
            // Untrusted audio arrives and is kept silent, rather than
            // refused: silence is the whole guarantee, and dropping the
            // subscription would lose the speaking indicator with it.
            await _setTrackVolume(
              track,
              _gateAudio(
                identity,
                publication.sid,
                _volumes[identity] ?? _defaultVolume,
              ),
            );
          case RemoteVideoTrack _:
            // Untrusted video is never drawn, so it should not cost bandwidth
            // either — unlike audio there is nothing to keep it around for.
            if (!trusted) {
              await publication.unsubscribe();
            } else if (_videoHidden.contains(identity)) {
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
        if (publication.kind != TrackType.VIDEO) return;

        // Fail closed on the way out, which matters more than on the way in:
        // the receive side can only keep somebody else's mistake quiet, but
        // this is the only thing standing between a camera and the media
        // server seeing it. A publication the frame cryptor did not take —
        // a blocked codec, or encryption that never came up — is withdrawn
        // rather than left sending in the clear.
        final codec = publication.track?.codec ?? publication.mimeType;
        if (!isBlockedVideoCodec(codec) &&
            publication.encryptionType != EncryptionType.kNone) {
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
        _reportFeeds();
      })
      ..on<TrackUnsubscribedEvent>((event) {
        _failing.remove(event.publication.sid);
        _reportFeeds();
      })
      ..on<ParticipantPermissionsUpdatedEvent>((event) async {
        if (event.participant != room.localParticipant) return;

        final before = _rights;
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
        if (_rights.camera && !before.camera && _cameraWanted) {
          await _applyCamera();
        }
        // And taken away: stop, rather than leave a track the media server has
        // stopped accepting.
        if (!_rights.camera && before.camera) await _stopCamera();
      });
  }

  // ── The camera ─────────────────────────────────────────────────────────────

  /// LiveKit reads an **empty** `canPublishSources` as "every source", so an
  /// empty list with `canPublish` true means both are allowed. Raindrop's own
  /// tokens never send one empty, but a token LiveKit refreshed for a connected
  /// participant is not ours to assume about.
  static VoicePublishRights _rightsOf(ParticipantPermissions permissions) {
    if (!permissions.canPublish) return VoicePublishRights.none;

    if (permissions.canPublishSources.isEmpty) {
      return const VoicePublishRights(microphone: true, camera: true);
    }

    return VoicePublishRights(
      microphone: _allows(permissions, _sourceMicrophone),
      camera: _allows(permissions, _sourceCamera),
    );
  }

  /// LiveKit's own `TrackSource` numbers.
  ///
  /// Compared by number rather than by name because the enum
  /// `ParticipantPermissions.canPublishSources` carries is the protobuf one,
  /// which `livekit_client` does not export — the public `TrackSource` is its
  /// own, differently-spelled type. These are LiveKit's wire protocol, the same
  /// numbers vendored on the server side in
  /// `RaindropServer.Voice.LiveKit/Protos/livekit_room_service.proto`.
  static const _sourceCamera = 1;
  static const _sourceMicrophone = 2;

  static bool _allows(ParticipantPermissions permissions, int source) =>
      permissions.canPublishSources.any((s) => s.value == source);

  Future<void> _applyCamera() async {
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

  /// Installs or removes the effects on a camera that is already running.
  ///
  /// Nothing happens here yet: the effects need a hook into the capture
  /// pipeline that the media library does not expose, so `canUseCameraEffects`
  /// is false everywhere and the sheet says so. The chosen effect is still
  /// carried and persisted, so when that hook lands this is the one method that
  /// changes.
  Future<void> _applyEffect() async {}

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
        feeds.add(
          _LiveKitVideoFeed(
            identity: local.identity,
            track: track,
            isLocal: true,
            mirror: _frontCamera,
          ),
        );
      }
    }

    for (final participant in room.remoteParticipants.values) {
      if (_videoHidden.contains(participant.identity)) continue;
      if (_unencrypted.contains(participant.identity)) continue;

      for (final publication in participant.videoTrackPublications) {
        final track = publication.track;
        if (track == null) continue;
        if (_failing.contains(publication.sid)) continue;
        if (!publication.subscribed || !publication.enabled) continue;

        feeds.add(
          _LiveKitVideoFeed(
            identity: participant.identity,
            track: track,
            isLocal: false,
          ),
        );
      }
    }

    _videoFeeds.add(feeds);
    _reportUntrustedVideo();
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
        if (_unencrypted.contains(participant.identity) ||
            _failing.contains(publication.sid)) {
          untrusted.add(participant.identity);
        }
      }
    }

    _untrustedVideo.add(untrusted);
  }

  /// One publication's volume, or silence while it is not trusted.
  double _gateAudio(String identity, String sid, double volume) => gatedVolume(
    volume: volume,
    unencrypted: _unencrypted.contains(identity),
    undecryptable: _failing.contains(sid),
  );

  Future<void> _reapplyVolumes() async {
    for (final participant
        in _room?.remoteParticipants.values ?? const <RemoteParticipant>[]) {
      final wanted = _volumes[participant.identity] ?? _defaultVolume;
      for (final publication in participant.audioTrackPublications) {
        final track = publication.track;
        if (track == null) continue;
        await _setTrackVolume(
          track,
          _gateAudio(participant.identity, publication.sid, wanted),
        );
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

  Future<void> _applyMic() async {
    final local = _room?.localParticipant;
    if (local == null) return;

    if (_micWanted && !_rights.microphone) return;
    await local.setMicrophoneEnabled(_micWanted);
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
    this.mirror = false,
  });

  final VideoTrack track;

  @override
  final String identity;

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
        mirrorMode: mirror ? VideoViewMirrorMode.mirror : VideoViewMirrorMode.off,
      );
}

/// A camera running outside a call, for the camera-and-effects sheet.
///
/// It publishes nothing and touches no room: the sheet is reachable from
/// settings with no call in progress, and opening a preview must not need one.
class _LiveKitCameraPreview implements VoiceCameraPreview {
  LocalVideoTrack? _track;
  VoiceCameraOptions _options = const VoiceCameraOptions();
  bool _front = true;

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
    // or quality reopens it. There is nothing to apply for the effect itself
    // yet — see LiveKitVoiceEngine._applyEffect.
    if (_track != null && !previous.needsRestartFor(options)) return;

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
  }

  @override
  Future<void> dispose() => _stop();

  Future<void> _stop() async {
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
