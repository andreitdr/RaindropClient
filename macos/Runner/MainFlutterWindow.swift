import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // What closing this window does, the menu bar item, and the call at the
    // notch — see RaindropShell.
    RaindropShell.shared.attach(
      window: self, messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}
