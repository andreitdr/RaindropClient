/// The audio half of a voice call, behind one interface so the rest of the
/// app never names the media library. The server says which transport to use
/// when a call is joined (`VoiceJoinResult.transport`); [createVoiceEngine]
/// turns that name into an engine, or null for a transport this build cannot
/// speak.
library;

import 'livekit_voice_engine.dart';

/// Where the media connection is.
enum VoiceConnectionState { connecting, connected, reconnecting, disconnected }

/// Why a call ended from the media side. Only [networkFailure] and [unknown]
/// are worth rejoining automatically after; the others mean somebody decided
/// the call is over for this device, and rejoining would fight them.
enum VoiceDisconnectReason {
  /// This client hung up.
  clientInitiated,

  /// The same account joined the same call from another device.
  replacedByOtherDevice,

  /// The server removed this participant.
  removedByServer,

  /// The call itself was closed.
  callEnded,

  /// The connection could not be kept up.
  networkFailure,

  unknown,
}

/// Echo cancellation, noise suppression and automatic gain — applied to the
/// microphone before it is sent.
class VoiceAudioProcessing {
  const VoiceAudioProcessing({
    this.echoCancellation = true,
    this.noiseSuppression = true,
    this.autoGainControl = true,
  });

  final bool echoCancellation;
  final bool noiseSuppression;
  final bool autoGainControl;

  @override
  bool operator ==(Object other) =>
      other is VoiceAudioProcessing &&
      other.echoCancellation == echoCancellation &&
      other.noiseSuppression == noiseSuppression &&
      other.autoGainControl == autoGainControl;

  @override
  int get hashCode =>
      Object.hash(echoCancellation, noiseSuppression, autoGainControl);
}

/// An audio device the user can pick in settings.
class AudioDevice {
  const AudioDevice({required this.id, required this.label});

  final String id;
  final String label;
}

/// One call's audio. Created per call and disposed when it ends.
///
/// Participants are named by their identity in the call, which is their
/// member UUID on the server.
abstract class VoiceEngine {
  /// Connects and — when [micEnabled] — starts sending the microphone.
  Future<void> connect(
    Uri url,
    String token, {
    required bool micEnabled,
    required VoiceAudioProcessing processing,
    String? inputDeviceId,
    String? outputDeviceId,
  });

  Future<void> disconnect();

  /// Starts or stops sending the microphone. A no-op, not an error, while the
  /// server does not let this participant speak.
  Future<void> setMicEnabled(bool enabled);

  /// How loud [identity] plays here: 0 silent, 1 as sent, above 1 boosted up
  /// to [maximumVolume]. Remembered, so it applies to audio that arrives
  /// later too.
  Future<void> setParticipantVolume(String identity, double volume);

  /// The volume for anybody [setParticipantVolume] has not been told about —
  /// somebody whose audio arrives before the roster names them.
  Future<void> setDefaultVolume(double volume);

  Future<void> setInputDevice(String deviceId);

  Future<void> setOutputDevice(String deviceId);

  /// Re-opens the microphone with different processing.
  Future<void> applyProcessing(VoiceAudioProcessing processing);

  Stream<VoiceConnectionState> get connectionStates;

  /// Who is talking right now, this participant included.
  Stream<Set<String>> get activeSpeakers;

  /// Fires once when the call ends from the media side.
  Stream<VoiceDisconnectReason> get disconnects;

  /// Whether the server currently lets this participant send audio. Changes
  /// when a moderator mutes them for everyone, or their `speak` permission
  /// changes.
  Stream<bool> get canSpeakChanges;

  Future<void> dispose();
}

/// The loudest a participant can be turned up here, as a multiple of how
/// they were sent. The WebRTC source gain this maps onto accepts up to 10,
/// but past 2 speech clips audibly.
const double maximumVolume = 2.0;

/// The engine for a transport the server named, or null when this build does
/// not speak it.
VoiceEngine? createVoiceEngine(String transport) => switch (transport) {
  LiveKitVoiceEngine.transportName => LiveKitVoiceEngine(),
  _ => null,
};

/// The audio devices this machine has, for the settings screen.
Future<List<AudioDevice>> audioInputDevices() => LiveKitVoiceEngine.inputs();

Future<List<AudioDevice>> audioOutputDevices() => LiveKitVoiceEngine.outputs();
