import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      if let registrar = self.registrar(forPlugin: "io.flutter.plugin.platform_view"){
          if #available(iOS 18.0, *) {
              let factory = AvatarViewFactory(messenger: registrar.messenger(), registrar:registrar)
            
              registrar.register(factory, withId: "AvatarView")
          } else {
              
          }
      }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
