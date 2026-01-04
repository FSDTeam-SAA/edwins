import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        print("🚀 [NATIVE] AppDelegate starting...")
        
        // ✅ FIXED: Removed iOS 18.0 check - now works on iOS 13+
        if let registrar = self.registrar(forPlugin: "io.flutter.plugin.platform_view") {
            let factory = AvatarViewFactory(messenger: registrar.messenger(), registrar: registrar)
            registrar.register(factory, withId: "AvatarView")
            print("✅ [NATIVE] AvatarViewFactory registered successfully")
        } else {
            print("❌ [NATIVE] Failed to get registrar")
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}