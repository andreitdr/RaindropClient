import Cocoa
import FlutterMacOS

/// Raindrop outside its window, on the Mac: what closing the window does, the
/// menu bar item, and the call shown at the notch or in the menu bar.
///
/// Dart decides; this only carries it out. Two channels:
///
/// * `raindrop/residency` — `setKeepRunning` (whether closing the window hides
///   it rather than quitting) from Dart, and `command` (`openSettings`) back.
///   See `lib/core/platform/app_residency.dart`.
/// * `raindrop/call_session` — `begin`/`update` with the call's description,
///   and `end`, from Dart; `action` (`toggleMute`, `toggleDeafen`, `leave`)
///   back. See `lib/core/voice/call_session_host.dart`.
///
/// **Nothing here quits or hangs up by itself.** Quit is `NSApp.terminate`,
/// which Flutter turns into its exit request — where the call controller
/// leaves the call first — and Leave is sent to Dart like a button press.
@MainActor
final class RaindropShell: NSObject, NSWindowDelegate, NSMenuDelegate {
  static let shared = RaindropShell()

  /// Whether closing the window hides it. On until Dart says otherwise,
  /// which it does at startup: that is the setting's default, so a window
  /// closed in the moment before is not a surprise quit.
  private(set) var keepRunning = true

  private weak var window: NSWindow?
  private var residency: FlutterMethodChannel?
  private var callChannel: FlutterMethodChannel?

  /// The call in progress, as Dart last described it.
  private var call: CallDescription?

  private var statusItem: NSStatusItem?
  private let notch = NotchController()

  /// Redraws the menu bar's call timer once a second while it shows one.
  private var pillClock: Task<Void, Never>?

  /// Keeps App Nap off while the app works out of sight — see [updateActivity].
  private var activity: NSObjectProtocol?

  // ── Setting up ────────────────────────────────────────────────────────────

  func attach(window: NSWindow, messenger: FlutterBinaryMessenger) {
    self.window = window
    window.delegate = self

    let residency = FlutterMethodChannel(name: "raindrop/residency", binaryMessenger: messenger)
    residency.setMethodCallHandler { [weak self] call, result in
      MainActor.assumeIsolated { self?.handleResidency(call, result: result) }
    }
    self.residency = residency

    let callChannel = FlutterMethodChannel(
      name: "raindrop/call_session", binaryMessenger: messenger)
    callChannel.setMethodCallHandler { [weak self] call, result in
      MainActor.assumeIsolated { self?.handleCall(call, result: result) }
    }
    self.callChannel = callChannel

    // A display plugged in or out, or the main one changed: the notch may
    // have come or gone.
    NotificationCenter.default.addObserver(
      self, selector: #selector(screensChanged),
      name: NSApplication.didChangeScreenParametersNotification, object: nil)

    render()
  }

  private func handleResidency(_ call: FlutterMethodCall, result: FlutterResult) {
    switch call.method {
    case "setKeepRunning":
      let arguments = call.arguments as? [String: Any]
      keepRunning = arguments?["keep"] as? Bool ?? true
      render()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleCall(_ method: FlutterMethodCall, result: FlutterResult) {
    switch method.method {
    case "begin", "update":
      call = CallDescription(method.arguments)
      render()
      result(nil)
    case "end":
      call = nil
      render()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @objc private func screensChanged() { render() }

  // ── The window ────────────────────────────────────────────────────────────

  /// Closing the window — its button, Cmd+W — hides it while the app is to
  /// keep running, and closes it otherwise, which quits (see
  /// `AppDelegate.applicationShouldTerminateAfterLastWindowClosed`).
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    guard keepRunning else { return true }
    sender.orderOut(nil)
    updateActivity()
    return false
  }

  /// Brings the window back: from the Dock, the menu bar item, or the island.
  func showWindow() {
    guard let window else { return }
    if window.isMiniaturized { window.deminiaturize(nil) }
    window.makeKeyAndOrderFront(nil)
    if #available(macOS 14.0, *) {
      NSApp.activate()
    } else {
      NSApp.activate(ignoringOtherApps: true)
    }
    updateActivity()
  }

  // ── What shows ────────────────────────────────────────────────────────────

  /// Puts everything outside the window in step with [keepRunning] and
  /// [call]: the island at the notch when the menu bar's screen has one, the
  /// menu bar item when the app keeps running or the call has nowhere else to
  /// show.
  private func render() {
    let geometry = NSScreen.screens.first.flatMap(NotchGeometry.of)

    if let call, let geometry {
      notch.show(
        call, on: geometry,
        onAction: { [weak self] action in self?.send(action) },
        onOpen: { [weak self] in self?.showWindow() })
    } else {
      notch.hide()
    }

    let callInMenuBar = call != nil && !notch.isShowing
    if keepRunning || callInMenuBar {
      let item = statusItem ?? makeStatusItem()
      statusItem = item
      drawStatusItem(item, call: callInMenuBar ? call : nil)
    } else if let item = statusItem {
      NSStatusBar.system.removeStatusItem(item)
      statusItem = nil
    }

    if callInMenuBar {
      startPillClock()
    } else {
      pillClock?.cancel()
      pillClock = nil
    }

    updateActivity()
  }

  private func makeStatusItem() -> NSStatusItem {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu = NSMenu()
    menu.delegate = self
    item.menu = menu
    item.button?.font = NSFont.monospacedDigitSystemFont(
      ofSize: NSFont.systemFontSize, weight: .regular)
    return item
  }

  /// The item as Raindrop's mark, or — when the call shows nowhere else — as
  /// a pill with the microphone and the timer, the way the menu bar shows
  /// other live activities.
  private func drawStatusItem(_ item: NSStatusItem, call: CallDescription?) {
    guard let button = item.button else { return }
    if let call {
      let image = NSImage(
        systemSymbolName: call.microphoneSymbol,
        accessibilityDescription: call.micOn ? "In a call" : "In a call, muted")
      image?.isTemplate = true
      button.image = image
      button.imagePosition = .imageLeading
      button.title = " " + (call.reconnecting ? "Reconnecting…" : call.elapsed(at: Date()))
      button.toolTip = call.body.isEmpty ? call.title : "\(call.title) — \(call.body)"
    } else {
      let image = NSImage(named: "MenuBarIcon")
      image?.isTemplate = true
      image?.accessibilityDescription = "Raindrop"
      button.image = image
      button.imagePosition = .imageOnly
      button.title = ""
      button.toolTip = "Raindrop"
    }
  }

  private func startPillClock() {
    guard pillClock == nil else { return }
    pillClock = Task { @MainActor [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        guard let self, !Task.isCancelled, let item = self.statusItem, let call = self.call else {
          return
        }
        self.drawStatusItem(item, call: call)
      }
    }
  }

  /// App Nap slows a Mac app nobody can see — its timers, and with them the
  /// heartbeat that keeps this member online and the call's own timers. So
  /// while the window is hidden, or a call is up, the app says it is doing
  /// something the person asked for. The display and the Mac may still sleep.
  private func updateActivity() {
    let working = call != nil || (keepRunning && window?.isVisible == false)
    if working, activity == nil {
      activity = ProcessInfo.processInfo.beginActivity(
        options: .userInitiatedAllowingIdleSystemSleep,
        reason: "Staying connected while Raindrop's window is closed, or in a call")
    } else if !working, let current = activity {
      ProcessInfo.processInfo.endActivity(current)
      activity = nil
    }
  }

  // ── The menu bar item's menu ──────────────────────────────────────────────

  func menuNeedsUpdate(_ menu: NSMenu) {
    menu.removeAllItems()
    menu.addItem(item("Open Raindrop", #selector(openWindow)))

    if let call {
      menu.addItem(.separator())
      let heading = NSMenuItem(title: call.title, action: nil, keyEquivalent: "")
      heading.isEnabled = false
      menu.addItem(heading)
      if !call.body.isEmpty {
        let server = NSMenuItem(title: call.body, action: nil, keyEquivalent: "")
        server.isEnabled = false
        menu.addItem(server)
      }
      menu.addItem(item(call.micOn ? "Mute" : "Unmute", #selector(toggleMute)))
      menu.addItem(item(call.deafened ? "Undeafen" : "Deafen", #selector(toggleDeafen)))
      menu.addItem(item("Leave Call", #selector(leaveCall)))
    }

    menu.addItem(.separator())
    menu.addItem(item("Settings…", #selector(openSettings), key: ","))
    menu.addItem(item("Quit Raindrop", #selector(quit), key: "q"))
  }

  private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
    item.target = self
    return item
  }

  @objc private func openWindow() { showWindow() }
  @objc private func toggleMute() { send(.toggleMute) }
  @objc private func toggleDeafen() { send(.toggleDeafen) }
  @objc private func leaveCall() { send(.leave) }

  @objc private func openSettings() {
    showWindow()
    residency?.invokeMethod("command", arguments: "openSettings")
  }

  /// Through Flutter's exit request, like Cmd+Q: the call is left first.
  @objc private func quit() { NSApp.terminate(nil) }

  private func send(_ action: CallAction) {
    callChannel?.invokeMethod("action", arguments: action.rawValue)
  }
}
