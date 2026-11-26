import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // The call as a Live Activity — see CallActivity.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RaindropCallActivity") {
      CallActivity.shared.attach(messenger: registrar.messenger())
    }
  }

  /// Swiping the app away ends the call (Dart leaves it on its way out) and so
  /// its Live Activity, which iOS would otherwise leave on the Lock Screen.
  override func applicationWillTerminate(_ application: UIApplication) {
    CallActivity.endAllBeforeExit()
    super.applicationWillTerminate(application)
  }
}
