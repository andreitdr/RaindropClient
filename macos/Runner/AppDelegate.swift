import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  /// The last window closing quits only when the app is not to keep running
  /// with its window closed — and then it is a real close, because
  /// `RaindropShell` hides the window instead while it is. Either way, a quit
  /// goes through Flutter's exit request, where the call is left first.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return !RaindropShell.shared.keepRunning
  }

  /// Clicking the Dock icon with the window hidden brings it back.
  override func applicationShouldHandleReopen(
    _ sender: NSApplication, hasVisibleWindows flag: Bool
  ) -> Bool {
    if !flag { RaindropShell.shared.showWindow() }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
