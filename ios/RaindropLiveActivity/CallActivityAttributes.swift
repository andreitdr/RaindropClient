import ActivityKit
import Foundation

/// The call, as its Live Activity carries it — the Dynamic Island, and the
/// Lock Screen on every iPhone.
///
/// Compiled into both the app, which starts, updates and ends the activity
/// (`Runner/CallActivity.swift`), and the widget extension, which draws it
/// (`RaindropLiveActivity.swift`). It mirrors Dart's `CallSessionDescription`
/// (`lib/core/voice/call_session_host.dart`), less what the surface does not
/// show. Nothing in it ticks: the timer is drawn by the system from
/// `connectedAt`, so the activity is only updated when the call changes.
@available(iOS 16.1, *)
struct CallActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    /// "In <channel>", or "In a voice call" while the app is locked.
    var title: String

    /// The server's name; empty while the app is locked.
    var body: String

    /// When the call first connected, kept across a rejoin.
    var connectedAt: Date?

    /// Whether anybody can hear this member.
    var micOn: Bool
    var deafened: Bool
    var reconnecting: Bool
    var participants: Int
    var sharingScreen: Bool
    var encrypted: Bool

    /// The app is locked: [title] and [body] are already generic, and nothing
    /// that names anybody may be drawn — this is the Lock Screen.
    var concealed: Bool

    /// The SF Symbol for whether this member is heard: the strongest of
    /// deafened, muted and talking.
    var microphoneSymbol: String {
      if deafened { return "speaker.slash.fill" }
      return micOn ? "mic.fill" : "mic.slash.fill"
    }
  }
}
