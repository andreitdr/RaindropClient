import Foundation

/// The call as Dart describes it — `CallSessionDescription.toMap()` in
/// `lib/core/voice/call_session_host.dart` — for the notch and the menu bar.
///
/// Read leniently: a key this build does not know is ignored, and a missing
/// one reads as the quiet default, so a newer Dart side never breaks an older
/// shell or the other way round.
struct CallDescription: Equatable {
  /// "In <channel>", or "In a voice call" while the app is locked.
  var title: String

  /// The server's name; empty while the app is locked.
  var body: String

  /// When the call first connected. The timer is drawn from this; nothing
  /// ticks on the Dart side.
  var connectedAt: Date?

  /// Whether anybody can hear this member.
  var micOn: Bool
  var deafened: Bool
  var reconnecting: Bool
  var participants: Int
  var sharingScreen: Bool
  var encrypted: Bool

  /// The app is locked: [title] and [body] are already generic, and nothing
  /// else that names anybody may be shown.
  var concealed: Bool

  init?(_ arguments: Any?) {
    guard let map = arguments as? [String: Any] else { return nil }
    title = map["title"] as? String ?? "In a voice call"
    body = map["body"] as? String ?? ""
    if let milliseconds = map["connectedAt"] as? NSNumber {
      connectedAt = Date(timeIntervalSince1970: milliseconds.doubleValue / 1000)
    } else {
      connectedAt = nil
    }
    micOn = map["micOn"] as? Bool ?? true
    deafened = map["deafened"] as? Bool ?? false
    reconnecting = map["reconnecting"] as? Bool ?? false
    participants = (map["participants"] as? NSNumber)?.intValue ?? 0
    sharingScreen = map["sharingScreen"] as? Bool ?? false
    encrypted = map["encrypted"] as? Bool ?? false
    concealed = map["concealed"] as? Bool ?? false
  }

  /// The SF Symbol for whether this member is heard: the strongest of
  /// deafened, muted and talking.
  var microphoneSymbol: String {
    if deafened { return "speaker.slash.fill" }
    return micOn ? "mic.fill" : "mic.slash.fill"
  }

  /// How long the call has run, as a clock reads it: `4:07`, or `1:02:33`
  /// past the hour.
  func elapsed(at now: Date) -> String {
    guard let connectedAt else { return "0:00" }
    let seconds = max(0, Int(now.timeIntervalSince(connectedAt)))
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let rest = seconds % 60
    return hours > 0
      ? String(format: "%d:%02d:%02d", hours, minutes, rest)
      : String(format: "%d:%02d", minutes, rest)
  }
}

/// A control pressed outside the app, by the name Dart's `CallSessionAction`
/// knows it by.
enum CallAction: String {
  case toggleMute
  case toggleDeafen
  case leave
}
