import UIKit
import Flutter
// ⛔ import GoogleMaps // 1. HAPUS BARIS INI

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ⛔ GMSServices.provideAPIKey("API_KEY_ANDA_DISINI") // 2. HAPUS BARIS INI

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}