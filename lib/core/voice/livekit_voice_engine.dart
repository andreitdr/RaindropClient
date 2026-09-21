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

  @override
  Stream<VoiceConnectionState> get connectionStates => _connectionStates.stream;

  @override
  Stream<Set<String>> get activeSpeakers => _activeSpeakers.stream;

  @override
  Stream<VoiceDisconnectReason> get disconnects => _disconnects.stream;

  @override
  Stream<bool> get canSpeakChanges => _canSpeak.stream;

  @override
  Future<void> connect(
    Uri url,
    String token, {
    required bool micEnabled,
    required VoiceAudioProcessing processing,
    String? inputDeviceId,
    String? outputDeviceId,
  }) async {
    _micWanted = micEnabled;
    _processing = processing;
    _connectionStates.add(VoiceConnectionState.connecting);

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
      ),
    );
    _room = room;
    _listen(room);

    await room.connect(url.toString(), token);
    _connectionStates.add(VoiceConnectionState.connected);

    if (outputDeviceId != null) await _selectOutput(outputDeviceId);
    await _applyMic();
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
      if (track != null) await _setTrackVolume(track, clamped);
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
        if (track != null) await _setTrackVolume(track, _defaultVolume);
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
      ..on<ActiveSpeakersChangedEvent>(
        (event) => _activeSpeakers.add({
          for (final speaker in event.speakers) speaker.identity,
        }),
      )
      ..on<TrackSubscribedEvent>((event) async {
        final track = event.track;
        if (track is! RemoteAudioTrack) return;
        await _setTrackVolume(
          track,
          _volumes[event.participant.identity] ?? _defaultVolume,
        );
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
