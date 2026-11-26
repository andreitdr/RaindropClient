import AppIntents
import Foundation

/// Hands a control pressed on the Live Activity to the app.
///
/// A `LiveActivityIntent` runs in the app's process, whichever process drew
/// its button, so the intents below are compiled into both: the widget
/// extension only refers to them, and the app runs them. The app sets [send]
/// (`Runner/CallActivity.swift`); in the extension it stays nil and is never
/// reached.
enum CallActivityRelay {
  /// Sends an action, by the name Dart's `CallSessionAction` knows it by.
  @MainActor static var send: ((String) -> Void)?
}

@available(iOS 17.0, *)
struct ToggleMuteCallIntent: LiveActivityIntent {
  static let title: LocalizedStringResource = "Mute or Unmute"

  init() {}

  func perform() async throws -> some IntentResult {
    await MainActor.run { CallActivityRelay.send?("toggleMute") }
    return .result()
  }
}

@available(iOS 17.0, *)
struct ToggleDeafenCallIntent: LiveActivityIntent {
  static let title: LocalizedStringResource = "Deafen or Undeafen"

  init() {}

  func perform() async throws -> some IntentResult {
    await MainActor.run { CallActivityRelay.send?("toggleDeafen") }
    return .result()
  }
}

@available(iOS 17.0, *)
struct LeaveCallIntent: LiveActivityIntent {
  static let title: LocalizedStringResource = "Leave Call"

  init() {}

  func perform() async throws -> some IntentResult {
    await MainActor.run { CallActivityRelay.send?("leave") }
    return .result()
  }
}
