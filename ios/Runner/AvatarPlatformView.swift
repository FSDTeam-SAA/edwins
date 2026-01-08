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
    
    private let cornerRadius: CGFloat
    
    // ✅ Animation tracking
    private var handWaveTimer: Timer?
    
    // ✅ Camera tracking
    private var cameraNode: SCNNode?
    private var originalCameraFOV: Double = 35.0
    private var isZoomedOut: Bool = false // ✅ Track zoom state
    
    // ✅ Animation cache
    private var cachedAnimations: [String: [String: CAAnimation]] = [:]
    private var currentAvatarName: String?

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, backgroundImagePath: String?, cornerRadius: CGFloat, registrar: FlutterPluginRegistrar, avatarName: String) {
        self.registrar = registrar
        self.cornerRadius = cornerRadius
 
        super.init()
        
        print("🎯 [NATIVE] AvatarPlatformView.init() - viewId: \(viewId)")
        print("🎯 [NATIVE] Avatar name: \(avatarName)")
        
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
        
        print("✅ [NATIVE] Method channel created: AvatarView/\(viewId)")

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
    
    func loadAndPlayCombinedAnimation(from daeName: String, on rootNode: SCNNode) {
        guard let sceneURL = Bundle.main.url(forResource: daeName, withExtension: "dae") else { 
            print("❌ [NATIVE] Idle animation not found: \(daeName).dae")
            return
        }
        guard let sceneSource = SCNSceneSource(url: sceneURL, options: nil) else { 
            print("❌ [NATIVE] Failed to load SCNSceneSource")
            return 
        }

        let animationIDs = sceneSource.identifiersOfEntries(withClass: CAAnimation.self)
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
        print("✅ [NATIVE] Idle animation loaded: \(daeName)")
    }
    
    private func loadAvatarAndSetupCamera(avatarName: String) {
        currentAvatarName = avatarName // ✅ Store avatar name
        let avatarFile = "\(avatarName)Avatar"
        guard let modelURL = Bundle.main.url(
            forResource: avatarFile,
            withExtension: "usdz"
        ) else {
            print("❌ [NATIVE] \(avatarFile).usdz not found")
            return
        }

        do {
            let loadedRig = try AvatarRig(modelURL: modelURL)
            self.rig = loadedRig

            let scene = loadedRig.scene
            scnView.scene = scene
            scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            scnView.autoenablesDefaultLighting = true
            scene.background.contents = UIColor.black

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

            let headY = radius * 150.6
            let target = SCNVector3(0, headY, 0)
            let distance: Float = radius * 110.0

            let camNode = SCNNode()
            let camera = SCNCamera()
            camNode.camera = camera

            camera.zNear = 0.01
            camera.zFar  = 1000
            camera.fieldOfView = 52.5  // ✅ START zoomed out (was 35)
            originalCameraFOV = 52.5   // ✅ Store as default

            // ✅ Position camera LOWER to see face better
            let lowerY = headY - radius * 0.3  // Move down
            camNode.position = SCNVector3(0, lowerY, distance)
            
            // ✅ Look at face (slightly above center)
            let faceTarget = SCNVector3(0, headY + radius * 0.1, 0)
            camNode.look(at: faceTarget)

            wrapper.addChildNode(camNode)
            scnView.pointOfView = camNode
            scnView.allowsCameraControl = false
            
            self.cameraNode = camNode
            self.isZoomedOut = true  // ✅ Already zoomed out from start
            print("✅ [NATIVE] Camera setup complete (zoomed out + tilted down)")

            applyPendingBackgroundIfAny()

        } catch {
            print("❌ [NATIVE] USD load failed: \(error)")
        }
    }

    // ✅ MAIN: Trigger hand wave animation
    private func triggerHandWave(duration: Double, animationPath: String?, result: @escaping FlutterResult) {
        print("👋 [NATIVE] Hand wave requested for \(duration)s")
        print("🎬 [NATIVE] Animation path: \(animationPath ?? "nil")")
        
        guard let path = animationPath else {
            print("❌ [NATIVE] No animation path provided")
            result(FlutterError(code: "NO_ANIMATION", message: "animationPath required", details: nil))
            return
        }
        
        // ✅ Load and play DAE animation
        loadAndPlayDAEAnimation(from: path, duration: duration)
        
        // ✅ Stop animation IMMEDIATELY when duration ends (no extra delay)
        handWaveTimer?.invalidate()
        handWaveTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.stopHandWaveImmediately()
        }
        
        result(nil)
    }

    // ✅ Camera zoom animation - PERMANENT zoom out
    private func animateCameraZoom(duration: Double) {
        // ✅ Camera already starts zoomed out, no animation needed
        print("📸 [NATIVE] Camera already zoomed out from start")
    }

    // ✅ Load and play DAE animation with caching
    private func loadAndPlayDAEAnimation(from path: String, duration: Double) {
        print("🎬 [NATIVE] Loading DAE animation from: \(path)")
        
        // ✅ Extract filename without extension
        let filename = (path as NSString).lastPathComponent
        let name = (filename as NSString).deletingPathExtension
        
        print("🔍 [NATIVE] Animation name: \(name)")
        
        // ✅ Check cache first
        if let cachedAnims = cachedAnimations[name] {
            print("✅ [NATIVE] Using cached animations (\(cachedAnims.count) animations)")
            playAnimations(cachedAnims, duration: duration)
            animateCameraZoom(duration: duration)
            return
        }
        
        print("📥 [NATIVE] Loading from bundle: \(name).dae")
        
        // ✅ Load from bundle
        guard let sceneURL = Bundle.main.url(forResource: name, withExtension: "dae") else {
            print("❌ [NATIVE] DAE file not found in bundle: \(name).dae")
            return
        }
        
        print("✅ [NATIVE] Found DAE file at: \(sceneURL.lastPathComponent)")
        
        guard let sceneSource = SCNSceneSource(url: sceneURL, options: nil) else {
            print("❌ [NATIVE] Failed to load SCNSceneSource")
            return
        }
        
        let animationIDs = sceneSource.identifiersOfEntries(withClass: CAAnimation.self)
        print("✅ [NATIVE] Found \(animationIDs.count) animations")
        
        // ✅ Cache animations
        var animationsDict: [String: CAAnimation] = [:]
        
        for id in animationIDs where id.hasSuffix("-anim") {
            if let anim = sceneSource.entryWithIdentifier(id, withClass: CAAnimation.self) {
                // Clone animation to avoid reuse issues
                if let clonedAnim = anim.copy() as? CAAnimation {
                    animationsDict[id] = clonedAnim
                    print("📦 [NATIVE] Cached animation: \(id)")
                }
            }
        }
        
        // ✅ Store in cache
        if !animationsDict.isEmpty {
            cachedAnimations[name] = animationsDict
            print("✅ [NATIVE] Cached \(animationsDict.count) animations for \(name)")
        }
        
        // ✅ Play animations
        playAnimations(animationsDict, duration: duration)
        animateCameraZoom(duration: duration)
    }
    
    // ✅ Play cached animations - LOOP for full duration
    private func playAnimations(_ animations: [String: CAAnimation], duration: Double) {
        guard let rootNode = scnView.scene?.rootNode else {
            print("❌ [NATIVE] No root node found")
            return
        }
        
        // ✅ Play all animations with REPEAT
        var playedCount = 0
        for (id, anim) in animations {
            if let playAnim = anim.copy() as? CAAnimation {
                // Get original animation duration
                let originalDuration = playAnim.duration
                
                // ✅ Calculate how many times to repeat
                let repeatCount = Float(duration / originalDuration)
                
                playAnim.duration = originalDuration  // Keep original timing
                playAnim.repeatCount = repeatCount    // ✅ Repeat to fill duration
                playAnim.fillMode = .forwards
                playAnim.isRemovedOnCompletion = false  // ✅ Keep playing
                playAnim.timingFunction = CAMediaTimingFunction(name: .linear)
                
                rootNode.addAnimation(playAnim, forKey: "waveAnimation_\(id)")
                playedCount += 1
                
                print("🔁 [NATIVE] Animation \(id): \(originalDuration)s × \(repeatCount) = \(duration)s")
            }
        }
        
        print("✅ [NATIVE] Playing \(playedCount) animations (looping for \(duration)s)")
    }

    // ✅ Stop hand wave IMMEDIATELY - no fade, no delay
    private func stopHandWaveImmediately() {
        print("🛑 [NATIVE] Stopping hand wave IMMEDIATELY")
        handWaveTimer?.invalidate()
        handWaveTimer = nil
        
        guard let rootNode = scnView.scene?.rootNode else { return }
        
        // ✅ Just remove animations instantly - they auto-remove anyway
        let animationKeys = rootNode.animationKeys.filter { $0.hasPrefix("waveAnimation_") }
        
        for key in animationKeys {
            rootNode.removeAnimation(forKey: key)
        }
        
        print("✅ [NATIVE] \(animationKeys.count) animations removed instantly")
        print("📸 [NATIVE] Camera stays zoomed out")
    }
    
    // ✅ Legacy method for compatibility
    private func stopHandWave() {
        stopHandWaveImmediately()
    }
    
    func view() -> UIView { scnView }
    
    private func handleCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("📞 [NATIVE] Method called: \(call.method)")
        
        switch call.method {
        case "playAudioViseme":
            guard
                let args = call.arguments as? [String: Any],
                let audioPath = args["audioPath"] as? String
            else { 
                result(FlutterError(code: "bad_args", message: "audioPath missing", details: nil))
                return 
            }

            do {
                try audioPlayer.play(path: audioPath)
                if scheduler == nil, let rig, let clock = audioPlayer.clock {
                    scheduler = VisemeScheduler(clock: clock, morpher: rig)
                }
                if let list = args["visemes"] as? [[String:Any]] { 
                    enqueueVisemes(list) 
                }
                result(nil)
            } catch {
                result(FlutterError(code: "audio_failed", 
                                  message: error.localizedDescription, 
                                  details: nil))
            }
            
        case "stopAudioViseme":
            scheduler?.clear()
            audioPlayer.stop()
            result(nil)
            
        case "triggerViseme":
            guard let args = call.arguments as? [String: Any],
                  let visemeName = args["visemeName"] as? String,
                  let duration = args["duration"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", 
                                  message: "visemeName and duration required", 
                                  details: nil))
                return
            }
            
            if scheduler == nil, let rig = self.rig {
                let ttsClock = TTSClock()
                scheduler = VisemeScheduler(clock: ttsClock, morpher: rig)
            }
            
            scheduler?.triggerViseme(name: visemeName, duration: duration)
            result(nil)
            
        case "resetToNeutral":
            scheduler?.clear()
            result(nil)
            
        case "triggerHandWave":
            print("📞 [NATIVE] triggerHandWave called")
            guard let args = call.arguments as? [String: Any],
                  let duration = args["duration"] as? Double else {
                print("❌ [NATIVE] Invalid arguments for triggerHandWave")
                result(FlutterError(code: "INVALID_ARGS", 
                                  message: "duration required", 
                                  details: nil))
                return
            }
            
            let animationPath = args["animationPath"] as? String
            print("⏱️ [NATIVE] Duration: \(duration)")
            print("🎬 [NATIVE] Animation path: \(animationPath ?? "nil")")
            
            triggerHandWave(duration: duration, animationPath: animationPath, result: result)
            
        case "stopHandWave":
            stopHandWave()
            result(nil)
            
        case "dispose":
            print("[NATIVE] AvatarPlatformView.dispose() called")
            dispose()
            result(nil)
            
        default: 
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func dispose() {
        print("🧹 Disposing AvatarPlatformView")
        displayLink?.invalidate()
        displayLink = nil

        scheduler?.clear()
        scheduler = nil

        blinkCtl = nil
        
        handWaveTimer?.invalidate()
        handWaveTimer = nil
        cameraNode = nil
        isZoomedOut = false // ✅ Reset zoom state
        cachedAnimations.removeAll() // ✅ Clear cache
        currentAvatarName = nil

        scnView.scene = nil
        scnView.delegate = nil
        scnView.isPlaying = false
        scnView.removeFromSuperview()

        channel.setMethodCallHandler(nil)
        rig = nil
        cameraController = nil
    }

    deinit {
        print("[NATIVE] AvatarPlatformView.deinit")
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
            batch.append(VisemeEvent(
                index: idx, 
                start: start, 
                end: end, 
                weight: CGFloat((item["weight"] as? Double) ?? 0.9)
            ))
        }
        scheduler.enqueue(batch)
    }

    @objc private func tick() {
        scheduler?.tick()
        
        let dt = CGFloat(displayLink?.duration ?? 1.0/60.0)
        let now = CACurrentMediaTime()
        blinkCtl?.tick(dt: dt, now: now)
    }
}