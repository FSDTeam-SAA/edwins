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
    
    // ✅ Hand wave animation tracking
    private var handWaveTimer: Timer?
    private var rightHandNode: SCNNode?
    private var leftHandNode: SCNNode?
    private var rightArmNode: SCNNode?
    private var rightForeArmNode: SCNNode?
    private var rightShoulderNode: SCNNode?
    
    // ✅ Camera node tracking
    private var cameraNode: SCNNode?
    private var originalCameraPosition: SCNVector3?

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, backgroundImagePath: String?, cornerRadius: CGFloat, registrar: FlutterPluginRegistrar, avatarName: String) {
        self.registrar = registrar
        self.cornerRadius = cornerRadius
 
        super.init()
        
        print("🎯 [NATIVE] AvatarPlatformView.init() - viewId: \(viewId)")
        print("🎯 [NATIVE] Channel will be: AvatarView/\(viewId)")
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
            print("DAE file not found."); return
        }
        guard let sceneSource = SCNSceneSource(url: sceneURL, options: nil) else { 
            print("Failed to load SCNSceneSource."); return 
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
            camera.fieldOfView = 35

            camNode.position = SCNVector3(0, headY + radius * 0.2, distance)
            camNode.look(at: target)

            wrapper.addChildNode(camNode)
            scnView.pointOfView = camNode
            scnView.allowsCameraControl = false
            
            // ✅ Store camera node and original position
            self.cameraNode = camNode
            self.originalCameraPosition = camNode.position
            print("📸 [NATIVE] Camera setup complete at position: \(camNode.position)")

            applyPendingBackgroundIfAny()
            
            // ✅ Find hand nodes after avatar loads
            findHandNodes(in: scene.rootNode)

        } catch {
            print("USD load failed: \(error)")
        }
    }

    // ✅ AGGRESSIVE: Find hand and arm nodes
    private func findHandNodes(in rootNode: SCNNode) {
        print("🔍 [NATIVE] Searching for hand nodes in skeleton...")
        
        // Print ALL nodes to debug
        print("📋 [NATIVE] Full skeleton hierarchy:")
        printAllNodes(rootNode, level: 0, maxDepth: 8)
        
        // Search for right hand/arm nodes
        rightHandNode = findNodeByName(rootNode, containing: ["hand", "right"], excluding: ["left"])
        rightArmNode = findNodeByName(rootNode, containing: ["arm", "right"], excluding: ["left", "fore"])
        rightForeArmNode = findNodeByName(rootNode, containing: ["forearm", "right"], excluding: ["left"])
        rightShoulderNode = findNodeByName(rootNode, containing: ["shoulder", "right"], excluding: ["left"])
        
        // Fallback to any arm node
        if rightArmNode == nil {
            rightArmNode = rightShoulderNode ?? rightForeArmNode ?? rightHandNode
        }
        
        print("✅ [NATIVE] Right hand: \(rightHandNode?.name ?? "NOT FOUND")")
        print("✅ [NATIVE] Right arm: \(rightArmNode?.name ?? "NOT FOUND")")
        print("✅ [NATIVE] Right forearm: \(rightForeArmNode?.name ?? "NOT FOUND")")
        print("✅ [NATIVE] Right shoulder: \(rightShoulderNode?.name ?? "NOT FOUND")")
    }
    
    // Find node by name patterns (case-insensitive)
    private func findNodeByName(_ root: SCNNode, containing: [String], excluding: [String] = []) -> SCNNode? {
        var foundNode: SCNNode?
        
        root.enumerateChildNodes { (node, stop) in
            guard let name = node.name?.lowercased() else { return }
            
            // Check if name contains all required patterns
            let hasAllRequired = containing.allSatisfy { name.contains($0.lowercased()) }
            let hasExcluded = excluding.contains { name.contains($0.lowercased()) }
            
            if hasAllRequired && !hasExcluded {
                print("🎯 [NATIVE] Found matching node: \(node.name ?? "unnamed")")
                foundNode = node
                stop.pointee = true
            }
        }
        
        return foundNode
    }
    
    // Print node hierarchy for debugging
    private func printAllNodes(_ node: SCNNode, level: Int, maxDepth: Int = 10) {
        guard level < maxDepth else { return }
        let indent = String(repeating: "  ", count: level)
        if let name = node.name, !name.isEmpty {
            print("\(indent)└─ \(name)")
        }
        for child in node.childNodes {
            printAllNodes(child, level: level + 1, maxDepth: maxDepth)
        }
    }

    // ✅ MAIN: Hand wave with camera zoom
    private func triggerHandWave(duration: Double, result: @escaping FlutterResult) {
        print("👋 [NATIVE] Hand wave requested for \(duration)s")
        
        // Animate camera zoom regardless of hand nodes
        animateCameraZoom(duration: duration)
        
        // Try to animate hand if nodes are found
        if let armNode = rightArmNode {
            animateHandWave(armNode: armNode, duration: duration)
        } else {
            print("⚠️ [NATIVE] No arm nodes found - camera zoom only")
        }
        
        // Set completion timer
        handWaveTimer?.invalidate()
        handWaveTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.stopHandWave()
        }
        
        result(nil)
    }
    
    // ✅ Camera zoom animation
// ✅ IMPROVED: More aggressive camera zoom out to show full hand wave
// ✅ Alternative: Use camera FOV instead of position
private func animateCameraZoom(duration: Double) {
    guard let camera = cameraNode, let cam = camera.camera else {
        print("❌ [NATIVE] Camera not found")
        return
    }
    
    print("📸 [NATIVE] Starting FOV zoom animation")
    
    let originalFOV = cam.fieldOfView
    let zoomOutFOV = originalFOV * 1.5  // 50% wider view
    
    print("📸 [NATIVE] Original FOV: \(originalFOV)")
    print("📸 [NATIVE] Zoom out FOV: \(zoomOutFOV)")
    
    // Zoom out
    SCNTransaction.begin()
    SCNTransaction.animationDuration = 0.6
    SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
    cam.fieldOfView = zoomOutFOV
    SCNTransaction.commit()
    
    // Zoom back
    DispatchQueue.main.asyncAfter(deadline: .now() + duration - 0.6) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.6
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeIn)
        cam.fieldOfView = originalFOV
        SCNTransaction.commit()
        
        print("📸 [NATIVE] FOV zoom completed")
    }
}
    
// ✅ PERFECT: L-shaped hand wave (upper arm down, forearm up at 90°)
// ✅ PERFECT: L-shaped hand wave with fingers spread
private func animateHandWave(armNode: SCNNode, duration: Double) {
    print("👋 [NATIVE] Starting L-shaped hand wave animation")
    
    let handNode = rightHandNode
    let forearmNode = rightForeArmNode
    
    // Stop all existing animations
    armNode.removeAllAnimations()
    handNode?.removeAllAnimations()
    forearmNode?.removeAllAnimations()
    
    // ========== UPPER ARM (Shoulder to Elbow) - Keep DOWN ==========
    let armLiftX = CAKeyframeAnimation(keyPath: "eulerAngles.x")
    armLiftX.values = [
        0,          // Start (relaxed)
        -0.3,       // Slight forward (to help elbow position)
        -0.3,       // Hold
        -0.3,       // Hold
        -0.2,       // Relax
        0           // Back to rest
    ]
    armLiftX.keyTimes = [0, 0.2, 0.4, 0.7, 0.85, 1.0]
    armLiftX.duration = duration
    armLiftX.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    
    let armSide = CAKeyframeAnimation(keyPath: "eulerAngles.y")
    armSide.values = [0, 0.2, 0.2, 0.2, 0.1, 0]
    armSide.keyTimes = [0, 0.2, 0.4, 0.7, 0.85, 1.0]
    armSide.duration = duration
    armSide.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    
    let armRotate = CAKeyframeAnimation(keyPath: "eulerAngles.z")
    armRotate.values = [0, -0.3, -0.3, -0.3, -0.15, 0]
    armRotate.keyTimes = [0, 0.2, 0.4, 0.7, 0.85, 1.0]
    armRotate.duration = duration
    armRotate.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    
    let armGroup = CAAnimationGroup()
    armGroup.animations = [armLiftX, armSide, armRotate]
    armGroup.duration = duration
    armGroup.fillMode = .both
    armGroup.isRemovedOnCompletion = false
    
    // ========== FOREARM (Elbow to Wrist) - BEND UP 90° ==========
    if let forearm = forearmNode {
        let forearmBend = CAKeyframeAnimation(keyPath: "eulerAngles.x")
        forearmBend.values = [
            0,          // Start straight
            -1.57,      // Bend up 90° (π/2 radians)
            -1.57,      // Hold L-shape
            -1.57,      // Hold
            -1.2,       // Start straightening
            0           // Back to straight
        ]
        forearmBend.keyTimes = [0, 0.25, 0.4, 0.7, 0.85, 1.0]
        forearmBend.duration = duration
        forearmBend.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        forearmBend.fillMode = .both
        forearmBend.isRemovedOnCompletion = false
        
        forearm.addAnimation(forearmBend, forKey: "forearmBend")
        print("✅ [NATIVE] Forearm L-shape bend applied")
    }
    
    // ========== HAND (Wrist) - WAVE WITH FINGERS SPREAD ==========
// ========== HAND (Wrist) - WAVE LEFT-RIGHT (NOT FRONT-BACK) ==========
if let hand = handNode {
    // Y-axis: Wave LEFT and RIGHT (horizontal motion)
    let handWave = CAKeyframeAnimation(keyPath: "eulerAngles.y")
    handWave.values = [
        0.8,        // Start facing forward
        0.8,        // Hold forward
        1.3,        // Wave RIGHT
        0.3,        // Wave LEFT
        1.3,        // Wave RIGHT
        0.3,        // Wave LEFT
        0.8,        // Back to center
        0.8         // Hold center
    ]
    handWave.keyTimes = [0, 0.3, 0.42, 0.54, 0.66, 0.78, 0.88, 1.0]
    handWave.duration = duration
    handWave.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    handWave.fillMode = .both
    handWave.isRemovedOnCompletion = false
    
    // Z-axis: Keep palm facing forward (no rotation)
    let handRotate = CAKeyframeAnimation(keyPath: "eulerAngles.z")
    handRotate.values = [
        0,          // Start neutral
        0,          // Hold
        0,          // No rotation during wave
        0,          // No rotation
        0,          // No rotation
        0,          // No rotation
        0,          // Hold
        0           // Neutral
    ]
    handRotate.keyTimes = [0, 0.25, 0.4, 0.5, 0.7, 0.85, 0.92, 1.0]
    handRotate.duration = duration
    handRotate.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    handRotate.fillMode = .both
    handRotate.isRemovedOnCompletion = false
    
    // X-axis: Slight forward tilt (natural position)
    let handTilt = CAKeyframeAnimation(keyPath: "eulerAngles.x")
    handTilt.values = [
        0,          // Start
        0,          // Wait
        0.2,        // Slight forward tilt
        0.2,        // Hold
        0.2,        // Hold
        0.1,        // Relax
        0           // Neutral
    ]
    handTilt.keyTimes = [0, 0.3, 0.4, 0.7, 0.85, 0.92, 1.0]
    handTilt.duration = duration
    handTilt.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    handTilt.fillMode = .both
    handTilt.isRemovedOnCompletion = false
    
    let handGroup = CAAnimationGroup()
    handGroup.animations = [handWave, handRotate, handTilt]
    handGroup.duration = duration
    handGroup.fillMode = .both
    handGroup.isRemovedOnCompletion = false
    
    hand.addAnimation(handGroup, forKey: "handWave")
    print("✅ [NATIVE] Hand waving LEFT-RIGHT with palm facing forward")
}
    
    // Apply upper arm animation
    CATransaction.begin()
    CATransaction.setCompletionBlock {
        print("✅ [NATIVE] L-shaped hand wave completed")
    }
    armNode.addAnimation(armGroup, forKey: "armLift")
    CATransaction.commit()
    
    print("✅ [NATIVE] All hand wave animations applied")
}
    
    // ✅ Stop hand wave
 private func stopHandWave() {
    print("🛑 [NATIVE] Stopping hand wave")
    handWaveTimer?.invalidate()
    handWaveTimer = nil
    
    rightHandNode?.removeAnimation(forKey: "handWave")
    leftHandNode?.removeAnimation(forKey: "handWave")
    rightArmNode?.removeAnimation(forKey: "armLift")
    rightForeArmNode?.removeAnimation(forKey: "forearmBend")  // ✅ ADD THIS LINE
    rightForeArmNode?.removeAnimation(forKey: "handWave")     // ✅ ADD THIS LINE
    
    // Restore camera position
    if let camera = cameraNode, let original = originalCameraPosition {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        camera.position = original
        SCNTransaction.commit()
    }
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
            print("⏱️ [NATIVE] Duration: \(duration)")
            triggerHandWave(duration: duration, result: result)
            
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
        rightHandNode = nil
        leftHandNode = nil
        rightArmNode = nil
        rightForeArmNode = nil
        rightShoulderNode = nil
        cameraNode = nil
        originalCameraPosition = nil

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