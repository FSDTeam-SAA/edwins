import Flutter
import UIKit
import SceneKit

final class AvatarPlatformView: NSObject, FlutterPlatformView {
    private let scnView = SCNView()
    private var channel: FlutterMethodChannel!
    
    private var cameraCtl: AvatarCameraController!
    private var rig: AvatarRig?
    private var audioPlayer: AvatarAudioPlayer!
    private var scheduler: VisemeScheduler?
    private var displayLink: CADisplayLink?
    private var blinkCtl: BlinkController?

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger) {
        super.init()
        
        // SCNView setup
        scnView.frame = frame
        scnView.backgroundColor = .clear
        scnView.scene = SCNScene()
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false
        scnView.scene?.lightingEnvironment.intensity = 1.0

        // Audio
        do { audioPlayer = try AvatarAudioPlayer() }
        catch { print("AvatarAudioPlayer init failed: \(error)") }
        
        // Camera
        cameraCtl = AvatarCameraController(scnView: scnView)

        // Channel
        channel = FlutterMethodChannel(name: "AvatarView/\(viewId)", binaryMessenger: messenger)
        channel.setMethodCallHandler(handleCall)

        // DisplayLink
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
        
        loadAvatarAndSetupCamera()
    }
    
    private func loadAvatarAndSetupCamera() {
        
        let url = Bundle.main.url(forResource: "avatar_new2", withExtension: "usdz")

        guard let modelURL = url else {
            print("avatar_new.usdz/usdc not found in bundle")
            return
        }

        do {
            // Avatar Rig
            let loadedRig = try AvatarRig(modelURL: modelURL)
            self.rig = loadedRig

            scnView.scene = loadedRig.scene

            // set light
            let ambient = SCNNode()
            ambient.light = SCNLight()
            ambient.light?.type = .ambient
            ambient.light?.intensity = 200
            loadedRig.scene.rootNode.addChildNode(ambient)

            let key = SCNNode()
            key.light = SCNLight()
            key.light?.type = .directional
            key.light?.intensity = 700
            key.eulerAngles = SCNVector3(-Float.pi/6, Float.pi/8, 0)
            loadedRig.scene.rootNode.addChildNode(key)

            // set camera
            cameraCtl.configureDefaults(in: loadedRig.scene)
            
            // blinking setup
            if let rig,
               let left = rig.index(of: "eyeBlinkLeft"),
               let right = rig.index(of: "eyeBlinkRight")
            {
                blinkCtl = BlinkController(
                    morpher: rig,
                    leftIdx: left,
                    rightIdx: right
                )
            }

            // focus on face and upper body
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.cameraCtl.frame(of: loadedRig.scene.rootNode, showTopFraction: 0.45)
            }

        } catch {
            print("USD load failed: \(error)")
        }
    }


    func view() -> UIView { scnView }

    private func handleCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "playAudioViseme":
            guard
                let args = call.arguments as? [String: Any],
                let audioPath = args["audioPath"] as? String
            else { result(FlutterError(code: "bad_args", message: "audioPath missing", details: nil)); return }

            do {
                try audioPlayer.play(path: audioPath)
                // Scheduler erst erstellen, wenn Clock vorhanden
                if scheduler == nil, let rig, let clock = audioPlayer.clock {
                    scheduler = VisemeScheduler(clock: clock, morpher: rig)
                }
                // enqueue visemes 
                if let list = args["visemes"] as? [[String:Any]] { enqueueVisemes(list) }
                result(nil)
            } catch {
                result(FlutterError(code: "audio_failed", message: error.localizedDescription, details: nil))
            }
        case "stopAudioViseme":
            scheduler?.clear()
            audioPlayer.stop()
            
        default: result(FlutterMethodNotImplemented)
        }
    }

    private func enqueueVisemes(_ list: [[String: Any]]) {
        guard let scheduler, let rig, let sr = audioPlayer?.sampleRate else { return }
        var batch: [VisemeEvent] = []
        for item in list {
            guard let id = item["id"] as? String,
                  let startSec = item["startSec"] as? Double,
                  let endSec = item["endSec"] as? Double,
                  let idx = rig.index(of: id) else { continue }
            let start = Int64((startSec * sr).rounded())
            let end   = Int64((endSec   * sr).rounded())
            batch.append(VisemeEvent(index: idx, start: start, end: end, weight: CGFloat((item["weight"] as? Double) ?? 0.9)))
        }
        scheduler.enqueue(batch)
    }

    @objc private func tick() {
        // viseme tick
        scheduler?.tick()
        
        // blink tick
        let dt = CGFloat(displayLink?.duration ?? 1.0/60.0)
        let now = CACurrentMediaTime()
        blinkCtl?.tick(dt: dt, now: now)
    }
    
    
}

