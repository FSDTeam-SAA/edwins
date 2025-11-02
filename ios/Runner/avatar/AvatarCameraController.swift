// Ava// AvatarCameraController.swift
import SceneKit
import UIKit

final class AvatarCameraController {
    private weak var scnView: SCNView?
    private(set) var cameraNode: SCNNode?
    private var lookAtNode: SCNNode?

    init(scnView: SCNView) { self.scnView = scnView }

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
    func setBackgroundImage(named: String) {
        guard let v = scnView else { return }
        v.isOpaque = true
        v.backgroundColor = .black
        v.scene?.background.contents = UIImage(named: named)
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


