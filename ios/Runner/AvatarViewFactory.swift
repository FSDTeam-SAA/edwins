import Flutter
import UIKit

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
        print("➡️ create() aufgerufen mit args: \(String(describing: args))")

        
        let params = args as? [AnyHashable: Any]

        let bgPath = params?["backgroundImagePath"] as? String

        return AvatarPlatformView(
            frame: frame,
            viewId: viewId,
            messenger: messenger,
            backgroundImagePath: bgPath,
            registrar: registrar
        )
    }
}
