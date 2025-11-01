//
//  AvatarRig.swift
//  Runner
//
//  Created by Noah Tratzsch on 01.11.25.
//

import SceneKit

/// Rig
final class AvatarRig: MorphWeighter {

    // Scene & Morpher
    let scene: SCNScene
    let morpher: SCNMorpher
    let node: SCNNode

    // Indizes
    private(set) var indexByName: [String:Int] = [:]
    var targetCount: Int { morpher.targets.count }

    
    enum Component { case viseme, blink, emotion }
    private var components: [Component: [CGFloat]] = [:]

    // MARK: Init / Loading
    init(modelURL: URL) throws {
        self.scene = try SCNScene(url: modelURL, options: nil)

        guard let best = AvatarRig.findBestMorpherNode(in: scene.rootNode),
              let m = best.morpher
        else { throw NSError(domain: "AvatarRig", code: 1, userInfo: [NSLocalizedDescriptionKey: "No morpher found"]) }

        self.node = best
        self.morpher = m

        // Mapping
        for (i, t) in m.targets.enumerated() {
            if let nm = t.name { indexByName[nm] = i }
        }

        let count = m.targets.count
        components[.viseme]  = Array(repeating: 0, count: count)
        components[.blink]   = Array(repeating: 0, count: count)
        components[.emotion] = Array(repeating: 0, count: count)
    }

    // MARK: Composition
    func applyComponents(combine: (_ a: CGFloat, _ b: CGFloat) -> CGFloat = max) {
        let cVis = components[.viseme]  ?? []
        let cBln = components[.blink]   ?? []
        let cEmo = components[.emotion] ?? []
        let n = targetCount

        for i in 0..<n {
            let v = combine(cVis[safe:i], combine(cBln[safe:i], cEmo[safe:i]))
            morpher.setWeight(v, forTargetAt: i)
        }
    }
    func setWeight(_ w: CGFloat, index: Int) {
        morpher.setWeight(w, forTargetAt: index)
    }
    
    /// helper

    func resetAllWeights() {
        for i in 0..<targetCount { morpher.setWeight(0, forTargetAt: i) }
        for k in components.keys { components[k] = Array(repeating: 0, count: targetCount) }
    }

    func setComponent(_ comp: Component, weights: [CGFloat]) {
        precondition(weights.count == targetCount, "component size mismatch")
        components[comp] = weights
    }

    func setComponent(_ comp: Component, index: Int, weight: CGFloat) {
        guard var arr = components[comp], index >= 0, index < arr.count else { return }
        arr[index] = weight
        components[comp] = arr
    }

    func index(of name: String) -> Int? { indexByName[name] }

    // MARK: Static helpers

    static func findBestMorpherNode(in root: SCNNode) -> SCNNode? {
        var best: (node: SCNNode, score: Int)?
        root.enumerateChildNodes { node, _ in
            guard let m = node.morpher else { return }
            var score = 0
            let name = (node.name ?? "").lowercased()
            if name.contains("head")  { score += 20 }
            if name.contains("teeth") { score += 10 }
            if name.contains("eye")   { score -= 5 }

            let tnames = m.targets.compactMap { $0.name?.lowercased() }
            if tnames.contains("jawopen") { score += 10 }
            if tnames.contains("mouthclose") { score += 8 }
            if tnames.contains("viseme_aa") { score += 10 }
            if tnames.contains("viseme_o") || tnames.contains("viseme_u") { score += 6 }

            if best == nil || score > best!.score { best = (node, score) }
        }
        return best?.node
    }
}

private extension Array where Element == CGFloat {
    subscript(safe i: Int) -> CGFloat {
        (i >= 0 && i < count) ? self[i] : 0
    }
}
