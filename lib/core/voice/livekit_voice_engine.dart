/// [VoiceEngine] on LiveKit. The only file in the app that imports
/// `livekit_client` or `flutter_webrtc`.
library;

import 'dart:async';

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
  final _canSpeak = StreamController<bool>.broadcast();
  final _encryption = StreamController<VoiceEncryption>.broadcast();
  final _warnings = StreamController<String>.broadcast();

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
  Stream<bool> get canSpeakChanges => _canSpeak.stream;

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
    await _canSpeak.close();
    await _encryption.close();
    await _warnings.close();
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
        _reportEncryption();
      })
      ..on<ActiveSpeakersChangedEvent>(
        (event) => _activeSpeakers.add({
          for (final speaker in event.speakers) speaker.identity,
        }),
      )
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
            if (!trusted) await publication.unsubscribe();
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
        _reportEncryption();
        if (!_warnings.isClosed) {
          _warnings.add(
            'Your camera could not be encrypted, so it was turned off.',
          );
        }
      })
      ..on<LocalTrackUnpublishedEvent>(
        (event) => _failing.remove(event.publication.sid),
      )
      ..on<TrackUnsubscribedEvent>(
        (event) => _failing.remove(event.publication.sid),
      )
      ..on<ParticipantPermissionsUpdatedEvent>((event) async {
        if (event.participant != room.localParticipant) return;
        _canSpeak.add(event.permissions.canPublish);
        // Given the microphone back after a mute for everyone: send again if
        // this participant had it on.
        if (event.permissions.canPublish && !event.oldPermissions.canPublish) {
          await _applyMic();
        }
      });
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

    if (_micWanted && !local.permissions.canPublish) return;
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
