import ActivityKit
import Flutter
import Foundation

/// The call as a Live Activity: started, kept current and ended here, drawn by
/// the RaindropLiveActivity extension.
///
/// Dart decides; this only carries it out, over `raindrop/call_session` —
/// `begin`/`update` with the call's description and `end` from Dart, `action`
/// (`toggleMute`, `toggleDeafen`, `leave`) back, from the activity's buttons.
/// See `lib/core/voice/call_session_host.dart`.
///
/// Three things iOS insists on, and how they are met:
///
/// * **An activity starts only while the app is in the foreground.** Joining
///   always is; a dropped call that is rejoined keeps the activity it has
///   (Dart keeps the session open), so none is ever needed from the
///   background.
/// * **Force-quitting the app does not end its activities.** They are ended
///   on the way out (`AppDelegate.applicationWillTerminate`), as far as iOS
///   lets that finish, and any still there are ended on the next launch.
/// * **The person may turn Live Activities off**, for every app in Settings or
///   for calls in Raindrop's own. Either way the call goes on without one.
@MainActor
final class CallActivity {
  static let shared = CallActivity()

  private var channel: FlutterMethodChannel?

  /// The running activity, as `Activity<CallActivityAttributes>` — held as
  /// `Any` because that type does not exist before iOS 16.2.
  private var current: Any?

  /// The last change sent to the activity: each waits for the one before, so
  /// a quick mute and unmute cannot arrive the wrong way round.
  private var pending: Task<Void, Never>?

  /// The person swiped this call's activity away. It stays away until the
  /// next call: putting it back on the next mute would overrule them.
  private var dismissed = false

  func attach(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "raindrop/call_session", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      MainActor.assumeIsolated { self?.handle(call, result: result) }
    }
    self.channel = channel

    CallActivityRelay.send = { [weak self] action in
      self?.channel?.invokeMethod("action", arguments: action)
    }

    // Left over from a run that was killed: there is no call behind them.
    if #available(iOS 16.2, *) {
      for activity in Activity<CallActivityAttributes>.activities {
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
      }
    }
  }

  private func handle(_ call: FlutterMethodCall, result: FlutterResult) {
    switch call.method {
    case "begin", "update":
      let arguments = call.arguments as? [String: Any] ?? [:]
      // A new call is shown, whatever happened to the last one's activity.
      if call.method == "begin" { dismissed = false }
      if #available(iOS 16.2, *) {
        if arguments["showOutsideApp"] as? Bool ?? true {
          present(CallActivityAttributes.ContentState(arguments))
        } else {
          endCurrent()
        }
      }
      result(nil)
    case "end":
      if #available(iOS 16.2, *) { endCurrent() }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.2, *)
  private func present(_ state: CallActivityAttributes.ContentState) {
    let content = ActivityContent(state: state, staleDate: nil)

    if let activity = current as? Activity<CallActivityAttributes> {
      if activity.activityState == .active {
        let previous = pending
        pending = Task {
          await previous?.value
          await activity.update(content)
        }
        return
      }
      // Gone without the app ending it: the person dismissed it, or iOS
      // ended it after its eight hours.
      current = nil
      dismissed = true
    }

    guard !dismissed, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    do {
      current = try Activity.request(
        attributes: CallActivityAttributes(), content: content, pushType: nil)
    } catch {
      // In the background, or refused: the call goes on without one.
      current = nil
    }
  }

  @available(iOS 16.2, *)
  private func endCurrent() {
    guard let activity = current as? Activity<CallActivityAttributes> else { return }
    current = nil
    let previous = pending
    pending = Task {
      await previous?.value
      await activity.end(nil, dismissalPolicy: .immediate)
    }
  }

  /// Ends every call activity before the process goes, waiting at most a
  /// second: whatever is still running when iOS takes the app away is ended
  /// on the next launch instead.
  nonisolated static func endAllBeforeExit() {
    guard #available(iOS 16.2, *) else { return }
    let done = DispatchSemaphore(value: 0)
    Task.detached {
      for activity in Activity<CallActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
      done.signal()
    }
    _ = done.wait(timeout: .now() + 1)
  }
}

@available(iOS 16.1, *)
extension CallActivityAttributes.ContentState {
  /// Reads Dart's `CallSessionDescription.toMap()` leniently: a key this build
  /// does not know is ignored, and a missing one reads as the quiet default.
  init(_ map: [String: Any]) {
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
}
