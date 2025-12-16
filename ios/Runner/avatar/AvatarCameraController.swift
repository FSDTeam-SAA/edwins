import SceneKit
import simd

/*

final class AvatarCameraController {

    enum CameraPreset {
        case fullBody
        case hipsToHead
        case headCloseUp
    }

    private let cameraEntity = PerspectiveCamera()
    private let anchor = AnchorEntity(world: .zero)
    private weak var arView: ARView?

    init(arView: ARView) {
        self.arView = arView
        arView.scene.addAnchor(anchor)
        anchor.addChild(cameraEntity)
    }

    func applyPreset(_ preset: CameraPreset, avatar: Entity) {
        let pos: SIMD3<Float>
        let focus: SIMD3<Float>

        switch preset {
        case .fullBody:
            pos   = [0, 1.4, 3.5]
            focus = [0, 1.0, 0]
        case .hipsToHead:
            pos   = [0, 1.6, 2.5]
            focus = [0, 1.4, 0]
        case .headCloseUp:
            pos   = [0, 1.65, 0.8]
            focus = [0, 1.55, 0]
        }

        cameraEntity.position = pos
        cameraEntity.look(at: focus, from: pos, relativeTo: nil)
    }

    // 🔹 NEU: Hintergrund an die Kamera hängen
    func setBackground(assetOrPath: String, registrar: FlutterPluginRegistrar?) {
        AvatarBackground.attachImagePlane(
            assetOrPath: assetOrPath,
            to: cameraEntity,
            registrar: registrar,
            distance: 5.0
        )
    }
}



*/
/*
enum AvatarCameraPreset {
    case fullBody      // (1) full avatar
    case hipsToHead    // (2) hip + head
    case headCloseup   // (3) less hip, more head
}

final class AvatarCameraController {
    private weak var scnView: SCNView?
    private(set) var cameraNode: SCNNode?
    private var lookAtNode: SCNNode?
    private let registrar: FlutterPluginRegistrar?

    init(scnView: SCNView, registrar: FlutterPluginRegistrar? = nil) { self.scnView = scnView
        self.registrar = registrar
        applyPreset(.headCloseup)
    }
    
    func applyPreset(_ preset: AvatarCameraPreset) {
        guard let v = scnView, let scene = v.scene else { return }
        if cameraNode == nil { ensureCamera(in: scene) }
        guard let camNode = cameraNode else { return }

        let cam = camNode.camera!

        cam.usesOrthographicProjection = true
        cam.zNear = 0.001
        cam.zFar  = 10000

        switch preset {
        case .fullBody:
            cam.orthographicScale = 1.0
            lookAtNode?.position = SCNVector3(0, 1.0, 0)
            camNode.position     = SCNVector3(0, 1.0, 3.0)

        case .hipsToHead:
            cam.orthographicScale = 0.7
            lookAtNode?.position = SCNVector3(0, 1.3, 0)
            camNode.position     = SCNVector3(0, 1.3, 2.3)

        case .headCloseup:
            cam.orthographicScale = 0.45
            lookAtNode?.position = SCNVector3(0, 1.6, 0)
            camNode.position     = SCNVector3(0, 1.6, 2.0)
        }

        // constraints as before...
    }


    func configureDefaults(in scene: SCNScene) {
        ensureCamera(in: scene)
        scnView?.allowsCameraControl = false
        setBackgroundClear()
    }

    func ensureCamera(in scene: SCNScene) {
        if cameraNode == nil {
            let cam = SCNCamera()
            cam.fieldOfView = 35
            cam.wantsHDR = true
            cam.wantsExposureAdaptation = false
            cam.minimumExposure = 0.9
            cam.maximumExposure = 0.9
            cam.exposureOffset = 0.0
            cam.zNear = 0.001
            cam.zFar  = 10000

            let camNode = SCNNode()
            camNode.camera = cam
            scene.rootNode.addChildNode(camNode)
            cameraNode = camNode
        }
        if lookAtNode == nil {
            let l = SCNNode(); scene.rootNode.addChildNode(l); lookAtNode = l
        }
        if let look = lookAtNode {
            let c = SCNLookAtConstraint(target: look); c.isGimbalLockEnabled = true
            cameraNode?.constraints = [c]
        }
        scnView?.pointOfView = cameraNode
    }

    
 
    func frame(of root: SCNNode, showTopFraction: CGFloat = 0.6) {
        guard let v = scnView else { return }
        if v.bounds.width <= 0 || v.bounds.height <= 0 {
            DispatchQueue.main.async { [weak self] in
                self?.frame(of: root, showTopFraction: showTopFraction)
            }
            return
        }
        if cameraNode == nil, let scene = v.scene { ensureCamera(in: scene) }
        guard let cam = cameraNode?.camera, let scene = v.scene else { return }

        // Ortho-Kamera (Zoom nur über orthographicScale)
        cam.usesOrthographicProjection = true
        cam.zNear = 0.001
        cam.zFar  = 10000

        // 1) Robuste Bounds
        // Wichtig: der 'root' hier sollte der Node sein, der alle Meshes enthält (nicht nur die Armature)!
        let sphere = root.presentation.boundingSphere   // (center: SCNVector3, radius: CGFloat)
        let center = sphere.center
        let radius = max(0.001, sphere.radius)

        // 2) Sichtbarer Anteil der Höhe
        let frac = max(0.1, min(1.0, showTopFraction))
        let visibleHeight = CGFloat(radius) * 2.0 * frac

        // SceneKit: orthographicScale = halbe Sicht-Höhe
        cam.orthographicScale = Double(visibleHeight * 0.5)

        // 3) Fokus: leicht oberhalb der Mitte, damit oben mehr sichtbar ist
        let yCenter = center.y + Float(radius * (1.0 - Float(frac)))
        let focus   = SCNVector3(center.x, yCenter, center.z)

        // 4) Kamera-Position: einfach vor das Modell (Distanz > Radius, Ortho ist egal)
        let distance: Float = Float(radius * 3.0 + 0.25) // sicher außerhalb der Kugel
        lookAtNode?.position = focus
        cameraNode?.position = SCNVector3(focus.x, focus.y, focus.z + distance)

        // Optional: Up-Vektor stabilisieren
        let up = SCNBillboardConstraint() // verhindert Roll; alternativ SCNTransformConstraint mit fixem Up
        up.freeAxes = []
        cameraNode?.constraints = [
            {
                let c = SCNLookAtConstraint(target: lookAtNode!)
                c.isGimbalLockEnabled = true
                return c
            }(),
            up
        ]

        scnView?.pointOfView = cameraNode
    }





    func setBackgroundClear() {
        guard let v = scnView else { return }
        v.isOpaque = false
        v.backgroundColor = .clear
        v.scene?.background.contents = UIColor.clear
    }
    func setBackgroundColor(hex: String) {
        guard let v = scnView else { return }
        v.isOpaque = true
        v.backgroundColor = .clear
        v.scene?.background.contents = colorFromHex(hex)
    }
    
    func setBackgroundImage(named assetOrPath: String) {
        print("setbackground")
        guard let v = scnView else { return }
        v.isOpaque = false
        v.backgroundColor = .black

        // 1) Filepfad direkt?
        if assetOrPath.hasPrefix("/") || assetOrPath.hasPrefix("file://") {
            var p = assetOrPath
            if p.hasPrefix("file://"), let url = URL(string: p) { p = url.path }
            if let img = UIImage(contentsOfFile: p) {
                v.scene?.background.contents = img
                return
            } else {
                print("⚠️ BG: Disk image not found at \(p)")
            }
        }

        // 2) Flutter-Asset laden
        let key = registrar?.lookupKey(forAsset: assetOrPath) ?? assetOrPath
        let bundle = Bundle.main

        // a) Bevorzugt: über `flutter_assets`-Unterverzeichnis
        if let url = bundle.url(forResource: key, withExtension: nil, subdirectory: "flutter_assets"),
           let img = UIImage(contentsOfFile: url.path) {
            v.scene?.background.contents = img
            return
        }

        // b) Alternativ: manueller Pfadbau
        if let root = bundle.resourceURL {
            let url = root.appendingPathComponent("flutter_assets").appendingPathComponent(key)
            if FileManager.default.fileExists(atPath: url.path),
               let img = UIImage(contentsOfFile: url.path) {
                v.scene?.background.contents = img
                return
            }
        }

        // c) Letzter Versuch (selten erfolgreich, aber schadet nicht)
        if let img = UIImage(named: key, in: bundle, compatibleWith: nil) {
            v.scene?.background.contents = img
            return
        }

        print("❌ BG: Flutter-Asset nicht gefunden. key='\(key)' (original='\(assetOrPath)')")
        v.scene?.background.contents = UIColor.clear
    }


    private func colorFromHex(_ hex: String) -> UIColor {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0; Scanner(string: s).scanHexInt64(&rgb)
        switch s.count {
        case 6:
            return UIColor(
                red: CGFloat((rgb & 0xFF0000) >> 16)/255,
                green: CGFloat((rgb & 0x00FF00) >> 8)/255,
                blue: CGFloat(rgb & 0x0000FF)/255,
                alpha: 1.0
            )
        case 8:
            let a = CGFloat((rgb & 0xFF000000) >> 24)/255
            let r = CGFloat((rgb & 0x00FF0000) >> 16)/255
            let g = CGFloat((rgb & 0x0000FF00) >> 8)/255
            let b = CGFloat(rgb & 0x000000FF)/255
            return UIColor(red: r, green: g, blue: b, alpha: a)
        default:
            return .black
        }
    }
}

*/
import Foundation
import SceneKit
import UIKit
import Flutter


final class AvatarCameraController {

    private weak var scnView: SCNView?
    private let registrar: FlutterPluginRegistrar?


    init(scnView: SCNView, registrar: FlutterPluginRegistrar? = nil) {
        self.scnView = scnView
        self.registrar = registrar
        
     
    }




    func setBackgroundClear() {
        guard let v = scnView else { return }
        v.isOpaque = false
        v.backgroundColor = .clear
        v.scene?.background.contents = UIColor.clear
    }

    func setBackgroundColor(hex: String) {
        guard let v = scnView else { return }
        v.isOpaque = true
        v.backgroundColor = .clear
        v.scene?.background.contents = colorFromHex(hex)
    }

    func setBackgroundImage(named assetOrPath: String) {
        print("setbackground")
        guard let v = scnView else { return }
        v.isOpaque = false
        v.backgroundColor = .black

        // 1) Filepfad direkt?
        if assetOrPath.hasPrefix("/") || assetOrPath.hasPrefix("file://") {
            var p = assetOrPath
            if p.hasPrefix("file://"), let url = URL(string: p) { p = url.path }
            if let img = UIImage(contentsOfFile: p) {
                v.scene?.background.contents = img
                return
            } else {
                print("⚠️ BG: Disk image not found at \(p)")
            }
        }

        // 2) Flutter-Asset laden
        let key = registrar?.lookupKey(forAsset: assetOrPath) ?? assetOrPath
        let bundle = Bundle.main

        // a) Bevorzugt: über `flutter_assets`-Unterverzeichnis
        if let url = bundle.url(forResource: key, withExtension: nil, subdirectory: "flutter_assets"),
           let img = UIImage(contentsOfFile: url.path) {
            v.scene?.background.contents = img
            return
        }

        // b) Alternativ: manueller Pfadbau
        if let root = bundle.resourceURL {
            let url = root
                .appendingPathComponent("flutter_assets")
                .appendingPathComponent(key)
            if FileManager.default.fileExists(atPath: url.path),
               let img = UIImage(contentsOfFile: url.path) {
                v.scene?.background.contents = img
                return
            }
        }

        // c) Letzter Versuch
        if let img = UIImage(named: key, in: bundle, compatibleWith: nil) {
            v.scene?.background.contents = img
            return
        }

        print("❌ BG: Flutter-Asset nicht gefunden. key='\(key)' (original='\(assetOrPath)')")
        v.scene?.background.contents = UIColor.clear
    }

    // MARK: - Helpers

    private func colorFromHex(_ hex: String) -> UIColor {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        switch s.count {
        case 6:
            return UIColor(
                red:   CGFloat((rgb & 0xFF0000) >> 16)/255.0,
                green: CGFloat((rgb & 0x00FF00) >> 8)/255.0,
                blue:  CGFloat(rgb & 0x0000FF)/255.0,
                alpha: 1.0
            )
        case 8:
            let a = CGFloat((rgb & 0xFF000000) >> 24)/255.0
            let r = CGFloat((rgb & 0x00FF0000) >> 16)/255.0
            let g = CGFloat((rgb & 0x0000FF00) >> 8)/255.0
            let b = CGFloat(rgb & 0x000000FF)/255.0
            return UIColor(red: r, green: g, blue: b, alpha: a)
        default:
            return .black
        }
    }
}
