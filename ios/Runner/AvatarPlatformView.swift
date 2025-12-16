
import SceneKit
import Flutter

final class AvatarPlatformView: NSObject, FlutterPlatformView {
    private let scnView = SCNView()
    private var channel: FlutterMethodChannel!
    private var pendingBackgroundPath: String?
    private let registrar: FlutterPluginRegistrar
    
    private var cameraController: AvatarCameraController!
    private var rig: AvatarRig?
    private var audioPlayer: AvatarAudioPlayer!
    private var scheduler: VisemeScheduler?
    private var displayLink: CADisplayLink?
    private var blinkCtl: BlinkController?
    
    private var animCtl: AvatarAnimationController?
    
    private let cornerRadius: CGFloat
    


    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, backgroundImagePath: String?,cornerRadius: CGFloat, registrar: FlutterPluginRegistrar, avatarName: String) {
        self.registrar = registrar
        self.cornerRadius = cornerRadius
 
        super.init()
        
        // SCNView setup
        scnView.frame = frame
        scnView.backgroundColor = .clear
        scnView.scene = SCNScene()
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false
        scnView.scene?.lightingEnvironment.intensity = 1.0
    
        
        scnView.layer.cornerRadius = cornerRadius
         scnView.layer.masksToBounds = true
         if #available(iOS 13.0, *) {
             scnView.layer.cornerCurve = .continuous
         }

        // Audio
        do { audioPlayer = try AvatarAudioPlayer() }
        catch { print("AvatarAudioPlayer init failed: \(error)") }
        
        // Camera
        cameraController = AvatarCameraController(scnView: scnView, registrar: registrar)
        
        pendingBackgroundPath = backgroundImagePath

        // Channel
        channel = FlutterMethodChannel(name: "AvatarView/\(viewId)", binaryMessenger: messenger)
        channel.setMethodCallHandler(handleCall)

        // DisplayLink
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
        
        loadAvatarAndSetupCamera(avatarName: avatarName)
    }
    
    private func applyPendingBackgroundIfAny() {
          if let p = pendingBackgroundPath {
              cameraController.setBackgroundImage(named: p)
              pendingBackgroundPath = nil
          }
      }
    
    func loadAndPlayCombinedAnimation(from daeName: String,on rootNode: SCNNode) {
        guard let sceneURL = Bundle.main.url(forResource: daeName, withExtension: "dae",) else { print("DAE file not found."); return
        }
        guard let sceneSource = SCNSceneSource(url: sceneURL, options: nil) else { print("Failed to load SCNSceneSource."); return }

        let animationIDs = sceneSource.identifiersOfEntries(withClass: CAAnimation.self)
        //print("Gefundene Animationen: \(animationIDs)")

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


    
    
    private func loadAvatarAndSetupCamera(avatarName: String) {
        
        let avatarFile = "\(avatarName)Avatar"
        guard let modelURL = Bundle.main.url(
            forResource: avatarFile,
            withExtension: "usdz"
        ) else {
            print("❌ \(avatarFile).usdz not found")
            return
        }

        do {
            let loadedRig = try AvatarRig(modelURL: modelURL)
            self.rig = loadedRig

            let scene = loadedRig.scene
            scnView.scene = scene
            scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            // Sicherstellen, dass das Lighting nicht unser Problem ist
            scnView.autoenablesDefaultLighting = true

            // Debug-Hintergrund, damit wir sicher sehen, dass gerendert wird
            scene.background.contents = UIColor.black
            print("\(avatarName)Idle")

        
            // Idle-Animation, Licht, Blink wie bisher
            loadAndPlayCombinedAnimation(from: "\(avatarName)Idle", on: scene.rootNode)

            let ambient = SCNNode()
            ambient.light = SCNLight()
            ambient.light?.type = .ambient
            ambient.light?.intensity = 200
            scene.rootNode.addChildNode(ambient)

            let key = SCNNode()
            key.light = SCNLight()
            key.light?.type = .directional
            key.light?.intensity = 700
            key.eulerAngles = SCNVector3(-Float.pi/6, Float.pi/8, 0)
            scene.rootNode.addChildNode(key)

            if let rig = self.rig,
               let left = rig.index(of: "eyeBlinkLeft"),
               let right = rig.index(of: "eyeBlinkRight") {
                blinkCtl = BlinkController(
                    morpher: rig,
                    leftIdx: left,
                    rightIdx: right
                )
            }

            let wrapper = loadedRig.wrapper
            let localSphere = wrapper.boundingSphere
            let radius = max(0.01, localSphere.radius)

            // Wir wollen eher auf den Kopf zielen, nicht auf die Mitte
            // Füße sind bei ~0, Kopf ca. bei ~2 * radius
            let headY = radius * 150.6          // bisschen unter der Spitze
            let target = SCNVector3(0, headY, 0)

            // Kamera etwas über Kopfhöhe, davor
            let distance: Float = radius * 110.0

            let cameraNode = SCNNode()
            let camera = SCNCamera()
            cameraNode.camera = camera

            camera.zNear = 0.01
            camera.zFar  = 1000
            camera.fieldOfView = 35

            cameraNode.position = SCNVector3(0, headY + radius * 0.2, distance)
            cameraNode.look(at: target)

            wrapper.addChildNode(cameraNode)
            scnView.pointOfView = cameraNode
            scnView.allowsCameraControl = false

            // Wenn das funktioniert, kannst du hier wieder dein Bild setzen
            applyPendingBackgroundIfAny()

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
        case "dispose":
            print("[NATIVE] AvatarPlatformView.dispose() called")
            dispose()
            result(nil)

            
        default: result(FlutterMethodNotImplemented)
        }
    }
    private func dispose() {
        print("dispose")
            // Wichtig: DisplayLink invalidieren (sonst starker Retain-Cycle!)
            displayLink?.invalidate()
            displayLink = nil

            // Audio & Scheduler stoppen
            scheduler?.clear()
            scheduler = nil
            //audioPlayer?.stop()
            //audioPlayer = nil

            // Blinker & Controller lösen
            blinkCtl = nil

            // Scene freigeben
            scnView.scene = nil
            scnView.delegate = nil
            scnView.isPlaying = false
            scnView.removeFromSuperview()

            // Channel lösen
            channel.setMethodCallHandler(nil)
            rig = nil
            cameraController = nil
        }

        deinit {
            print("[NATIVE] AvatarPlatformView.deinit")
            // Fallback, falls dispose nicht manuell aufgerufen wurde
            dispose()
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

