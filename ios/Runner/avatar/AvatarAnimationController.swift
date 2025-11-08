import SceneKit
import QuartzCore   // <- für CAMediaTimingFillMode

struct AnimClip {
    let name: String
    let startFrame: Int
    let endFrame: Int
}

final class AvatarAnimationController {

    private weak var root: SCNNode?
    private var basePlayer: SCNAnimationPlayer?
    private var activeKey: String?
    private let fps: Double

    private(set) var clips: [String: AnimClip] = [
        "Waving"    : .init(name: "Waving",     startFrame: 0,    endFrame: 120),
        "HandIdle"  : .init(name: "HandIdle",   startFrame: 150,  endFrame: 283),
        "HappyIdle" : .init(name: "HappyIdle",  startFrame: 300,  endFrame: 600),
        "Talking"   : .init(name: "Talking",    startFrame: 700,  endFrame: 878),
        "Idle"      : .init(name: "Idle",       startFrame: 1000, endFrame: 1499)
    ]

    init(rootNode: SCNNode, fps: Double = 30.0) {
        self.root = rootNode
        self.fps = fps
    }

    func prepareForPlaybackAndStopAll() {
        guard let root = root else { return }

        // 1) BlendShape-Animationen entfernen (Visemes frei)
        root.enumerateChildNodes { node, _ in
            if node.morpher != nil {
                node.removeAllAnimations()
                node.morpher?.calculationMode = .additive
            }
        }

        // 2) Skelett-Player finden & alles stoppen
        var found: SCNAnimationPlayer?
        root.enumerateChildNodes { node, _ in
            for key in node.animationKeys {
                if let p = node.animationPlayer(forKey: key), found == nil {
                    found = p
                }
                node.removeAllAnimations()
            }
        }
        self.basePlayer = found
    }

    func playIdle(loop: Bool = true, blend: TimeInterval = 0.1) {
        play("Idle", loop: loop, blend: blend)
    }

    func play(_ name: String, loop: Bool = false, blend: TimeInterval = 0.1) {
        guard let clip = clips[name] else { return }
        playRange(startFrame: clip.startFrame, endFrame: clip.endFrame, loop: loop, blend: blend)
    }

    func stop() {
        guard let root = root, let key = activeKey else { return }
        root.removeAnimation(forKey: key, blendOutDuration: 0.1)
        activeKey = nil
    }

    // MARK: - Internals

    private func framesToSeconds(_ f: Int) -> TimeInterval { TimeInterval(Double(f) / fps) }

    private func playRange(startFrame: Int, endFrame: Int, loop: Bool, blend: TimeInterval) {
        guard let root = root else { return }

        if basePlayer == nil {
            root.enumerateChildNodes { node, stop in
                if let key = node.animationKeys.first,
                   let p = node.animationPlayer(forKey: key) {
                    self.basePlayer = p
                    stop.initialize(to: true)
                }
            }
        }
        guard let base = basePlayer else {
            #if DEBUG
            print("AvatarAnimationController: no base animation found.")
            #endif
            return
        }

        // Subclip auf Basis der gefundenen Animation bauen
        let sub = (base.animation.copy() as! SCNAnimation)
        sub.usesSceneTimeBase = false
        sub.isRemovedOnCompletion = false
        sub.repeatCount = loop ? .greatestFiniteMagnitude : 1

        let start = framesToSeconds(startFrame)
        let end   = framesToSeconds(endFrame)
        let dur   = max(0.0, end - start)

        sub.timeOffset = start
        sub.duration   = dur

        // Optionales Fill-Mode nur wenn tatsächlich CAAnimation
        if let ca = sub as? CAAnimation {
            ca.fillMode = .forwards
        }

        // Player erzeugen
        let player = SCNAnimationPlayer(animation: sub)
        // Blendzeiten gehören zur Animation, nicht zum Player:
        player.animation.blendInDuration  = blend
        player.animation.blendOutDuration = blend

        let key = "subclip_\(startFrame)_\(endFrame)_\(UUID().uuidString)"

        // Vorherige Subanimation weich ausblenden
        if let prev = activeKey {
            root.removeAnimation(forKey: prev, blendOutDuration: blend)
        }

        root.addAnimationPlayer(player, forKey: key)
        activeKey = key
        player.play()
    }
}
