import Flutter
import UIKit

@available(iOS 18.0, *)
public class AvatarViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    private let registrar: FlutterPluginRegistrar
    

    init(messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar) {
        self.messenger = messenger
        self.registrar = registrar
        super.init()
    }

    public func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol) {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    public func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
    
        
        let params = args as? [AnyHashable: Any]

        let bgPath = params?["backgroundImagePath"] as? String
        
        let avatarName = params?["avatarName"] as? String
        
        let cornerRadius = (params?["borderRadius"] as? NSNumber)?.doubleValue ?? 0.0
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
