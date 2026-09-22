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

  /// Set when the call is end-to-end encrypted.
  BaseKeyProvider? _keyProvider;

  /// Participants who published audio without encryption in an encrypted
  /// call. Kept silent for as long as they are in it, whatever the keys do.
  final _unencrypted = <String>{};

  /// Participants whose frames currently fail to decrypt. Usually a key
  /// change one side has not made yet, so this clears on the next key change
  /// or the first frame that decrypts; the cryptor drops those frames anyway.
  final _failing = <String>{};

  /// The key ring LiveKit keeps per call: this many past keys stay usable, so
  /// frames sent just before a key change still decrypt after it.
  static const keyRingSize = 16;

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
    // A participant whose frames failed may simply have been ahead of us.
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
      if (track != null) await _setTrackVolume(track, _gate(identity, clamped));
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
        if (track != null) {
          await _setTrackVolume(
            track,
            _gate(participant.identity, _defaultVolume),
          );
        }
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
        _failing.remove(event.participant.identity);
        _reportEncryption();
      })
      ..on<ActiveSpeakersChangedEvent>(
        (event) => _activeSpeakers.add({
          for (final speaker in event.speakers) speaker.identity,
        }),
      )
      ..on<TrackSubscribedEvent>((event) async {
        final track = event.track;
        if (track is! RemoteAudioTrack) return;
        final identity = event.participant.identity;
        // Fail closed: in an encrypted call, audio published without
        // encryption is from somebody not using the group's key — the media
        // server itself, or a client that is not a member. It stays silent.
        if (_keyProvider != null &&
            event.publication.encryptionType == EncryptionType.kNone) {
          _unencrypted.add(identity);
          _reportEncryption();
        }
        await _setTrackVolume(
          track,
          _gate(identity, _volumes[identity] ?? _defaultVolume),
        );
      })
      ..on<TrackE2EEStateEvent>((event) async {
        final identity = event.participant.identity;
        switch (event.state) {
          case E2EEState.kOk:
            if (_failing.remove(identity)) await _reapplyVolumes();
          case E2EEState.kDecryptionFailed ||
              E2EEState.kMissingKey ||
              E2EEState.kEncryptionFailed ||
              E2EEState.kInternalError:
            if (_failing.add(identity)) await _reapplyVolumes();
          case E2EEState.kNew || E2EEState.kKeyRatcheted:
        }
        _reportEncryption();
      })
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

  /// A participant's volume, or silence while their audio is not trusted.
  double _gate(String identity, double volume) =>
      _unencrypted.contains(identity) || _failing.contains(identity)
      ? 0
      : volume;

  Future<void> _reapplyVolumes() async {
    for (final participant
        in _room?.remoteParticipants.values ?? const <RemoteParticipant>[]) {
      final volume = _gate(
        participant.identity,
        _volumes[participant.identity] ?? _defaultVolume,
      );
      for (final publication in participant.audioTrackPublications) {
        final track = publication.track;
        if (track != null) await _setTrackVolume(track, volume);
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
