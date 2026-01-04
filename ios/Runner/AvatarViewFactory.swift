import Flutter
import UIKit

// ✅ FIXED: Removed iOS 18.0 requirement - works on iOS 13+
public class AvatarViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    private let registrar: FlutterPluginRegistrar
    
    init(messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar) {
        self.messenger = messenger
        self.registrar = registrar
        super.init()
        print("🏭 [NATIVE] AvatarViewFactory initialized")
    }

    public func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol) {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    public func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        
        print("🎬 [NATIVE] AvatarViewFactory.create() called - viewId: \(viewId)")
        
        let params = args as? [AnyHashable: Any]
        let bgPath = params?["backgroundImagePath"] as? String
        let avatarName = params?["avatarName"] as? String
        let cornerRadius = (params?["borderRadius"] as? NSNumber)?.doubleValue ?? 0.0
        
        print("📦 [NATIVE] Creating avatar: \(avatarName ?? "Karl")")
        
        let view = AvatarPlatformView(
            frame: frame,
            viewId: viewId,
            messenger: messenger,
            backgroundImagePath: bgPath,
            cornerRadius: CGFloat(cornerRadius),
            registrar: registrar,
            avatarName: avatarName ?? "Karl"
        )
        
        return view
    }
}