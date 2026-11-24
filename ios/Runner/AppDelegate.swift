import Flutter
import UIKit
import WatchConnectivity
import flutter_foreground_task

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let watch = WatchSender()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The foreground task runs its Dart handler in its own engine: register the plugins there too.
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    // Notifications (flutter_local_notifications, flutter_foreground_task) show and report taps.
    UNUserNotificationCenter.current().delegate = self
    watch.activate()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // The favourite stops for the Apple Watch app (lib/background/watch_sync.dart, docs/WATCH.md).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StaseisWatchSync") {
      let channel = FlutterMethodChannel(name: "gr.staseis.app/watch", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "sync" else { return result(FlutterMethodNotImplemented) }
        guard let json = call.arguments as? String, json.utf8.count <= 16_000 else {
          return result(FlutterError(code: "bad", message: "payload", details: nil))
        }
        self?.watch.send(json)
        result(nil)
      }
    }
  }
}

/// Sends the favourites to the watch as the application context: the watch gets the latest one when it
/// next runs, even if it was not reachable now. Without a paired watch it does nothing.
final class WatchSender: NSObject, WCSessionDelegate {
  private var pending: String?

  func activate() {
    guard WCSession.isSupported() else { return }
    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  func send(_ json: String) {
    guard WCSession.isSupported() else { return }
    let s = WCSession.default
    guard s.activationState == .activated else { pending = json; return } // sent once activation completes
    guard s.isPaired, s.isWatchAppInstalled else { return }
    try? s.updateApplicationContext(["json": json])
  }

  func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
    guard state == .activated, let json = pending else { return }
    pending = nil
    DispatchQueue.main.async { self.send(json) }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {}

  func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() } // a new watch was paired
}
