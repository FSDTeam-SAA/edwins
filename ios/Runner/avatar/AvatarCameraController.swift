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

    func frame(of root: SCNNode,
                       showTopFraction: CGFloat = 0.6) {  // 0.6 = upper 60% visible
        guard let v = scnView else { return }
        if v.bounds.width <= 0 || v.bounds.height <= 0 {
            DispatchQueue.main.async { [weak self] in
                self?.frame(of: root, showTopFraction: showTopFraction)
            }
            return
        }
        if cameraNode == nil, let scene = v.scene { ensureCamera(in: scene) }
        guard let cam = cameraNode?.camera, let scene = v.scene else { return }

        cam.usesOrthographicProjection = true
        cam.wantsExposureAdaptation = false
        cam.zNear = 0.001
        cam.zFar  = 10000


        let (minB, maxB) = root.boundingBox
        let corners = [
            SCNVector3(minB.x, minB.y, minB.z), SCNVector3(maxB.x, minB.y, minB.z),
            SCNVector3(minB.x, maxB.y, minB.z), SCNVector3(maxB.x, maxB.y, minB.z),
            SCNVector3(minB.x, minB.y, maxB.z), SCNVector3(maxB.x, minB.y, maxB.z),
            SCNVector3(minB.x, maxB.y, maxB.z), SCNVector3(maxB.x, maxB.y, maxB.z),
        ].map { root.convertPosition($0, to: scene.rootNode) }

        var minW = corners[0], maxW = corners[0]
        for c in corners {
            minW.x = min(minW.x, c.x); minW.y = min(minW.y, c.y); minW.z = min(minW.z, c.z)
            maxW.x = max(maxW.x, c.x); maxW.y = max(maxW.y, c.y); maxW.z = max(maxW.z, c.z)
        }
        let size  = SCNVector3(maxW.x - minW.x, maxW.y - minW.y, maxW.z - minW.z)
        let midX  = (minW.x + maxW.x)/2
        let midZ  = (minW.z + maxW.z)/2

        
        let h = CGFloat(size.y)
        let frac = max(0.1, min(1.0, showTopFraction))
        let visibleH = h * frac
        
        
        let yCenter = minW.y + Float(h - visibleH * 0.5)

        
        cam.orthographicScale = Double(visibleH * 0.5)

        
        let focus = SCNVector3(midX, yCenter, midZ)
        lookAtNode?.position = focus
        cameraNode?.position = SCNVector3(focus.x, focus.y, midZ + max(1.0, size.z + 0.5))

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


