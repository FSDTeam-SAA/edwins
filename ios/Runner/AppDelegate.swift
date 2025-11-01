import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      if let registrar = self.registrar(forPlugin: "AvatarPlatformView") {
        let factory = AvatarViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "AvatarView") // <- diese ID merken
      }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
