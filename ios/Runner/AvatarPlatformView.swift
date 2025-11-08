import Flutter
import UIKit
import SceneKit

final class AvatarPlatformView: NSObject, FlutterPlatformView {
    private let scnView = SCNView()
    private var channel: FlutterMethodChannel!
    private var pendingBackgroundPath: String?
    private let registrar: FlutterPluginRegistrar
    
    private var cameraCtl: AvatarCameraController!
    private var rig: AvatarRig?
    private var audioPlayer: AvatarAudioPlayer!
    private var scheduler: VisemeScheduler?
    private var displayLink: CADisplayLink?
    private var blinkCtl: BlinkController?
    
    private var animCtl: AvatarAnimationController?
    


    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, backgroundImagePath: String?, registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
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
        cameraCtl = AvatarCameraController(scnView: scnView, registrar: registrar)
        
        pendingBackgroundPath = backgroundImagePath

        // Channel
        channel = FlutterMethodChannel(name: "AvatarView/\(viewId)", binaryMessenger: messenger)
        channel.setMethodCallHandler(handleCall)

        // DisplayLink
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
        
        loadAvatarAndSetupCamera()
    }
    
    private func applyPendingBackgroundIfAny() {
        print("back", pendingBackgroundPath)
          if let p = pendingBackgroundPath {
              cameraCtl.setBackgroundImage(named: p)
              pendingBackgroundPath = nil
          }
      }
    func loadAndPlayCombinedAnimation(from daeName: String, on rootNode: SCNNode) {
        guard let sceneURL = Bundle.main.url(forResource: daeName, withExtension: "dae") else {
            print("DAE file not found.")
            return
        }

        guard let sceneSource = SCNSceneSource(url: sceneURL, options: nil) else {
            print("Failed to load SCNSceneSource.")
            return
        }

        let animationIDs = sceneSource.identifiersOfEntries(withClass: CAAnimation.self)
        print("Gefundene Animationen: \(animationIDs)")

        // Leere Gruppe, um alle Einzelanimationen zusammenzufassen
        let animationGroup = CAAnimationGroup()
        var animations: [CAAnimation] = []

        for id in animationIDs where id.hasSuffix("-anim") {
            if let anim = sceneSource.entryWithIdentifier(id, withClass: CAAnimation.self) {
                anim.fillMode = .forwards
                anim.isRemovedOnCompletion = false
                anim.repeatCount = .infinity
                animations.append(anim)
            }
        }

        animationGroup.animations = animations
        animationGroup.duration = animations.map { $0.duration }.max() ?? 1.0
        animationGroup.repeatCount = .infinity
        animationGroup.fillMode = .forwards
        animationGroup.isRemovedOnCompletion = false

        rootNode.addAnimation(animationGroup, forKey: "combinedIdle")
    }


    
    private func loadAvatarAndSetupCamera() {
        
        let url = Bundle.main.url(forResource: "Clara_Avatar_NoA", withExtension: "usdz")
        //let url = Bundle.main.url(forResource: "avatar_new2", withExtension: "usdz")
        guard let modelURL = url else {
            print("avatar_new.usdz/usdc not found in bundle")
            return
        }

        do {
            // Avatar Rig
            let loadedRig = try AvatarRig(modelURL: modelURL)
            
            

            self.rig = loadedRig

            scnView.scene = loadedRig.scene
            
            loadAndPlayCombinedAnimation(from: "Idle", on: loadedRig.scene.rootNode)
            

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
            
            applyPendingBackgroundIfAny()
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
                 self.cameraCtl.frame(of: loadedRig.wrapper, showTopFraction: 0.45)
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

