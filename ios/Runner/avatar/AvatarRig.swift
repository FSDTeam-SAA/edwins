//
//  AvatarRig.swift
//  Runner
//
//  Created by Noah Tratzsch on 01.11.25.
//
/*
import Foundation
import RealityKit
import simd
import CoreGraphics

@available(iOS 18.0, *)
final class Avatar: MorphWeighter {

    let root: Entity
    let wrapper: Entity
    private var blendEntity: Entity

    private var blendComponent: BlendShapeWeightsComponent {
        get { blendEntity.components[BlendShapeWeightsComponent.self]! }
        set { blendEntity.components.set(newValue) }
    }

    private(set) var indexByName: [String:Int] = [:]

    var targetCount: Int { blendComponent.weightSet[0].weights.count }

    enum Component { case viseme, blink, emotion }
    private var components: [Component: [Float]] = [:]

    // MARK: - Init

    init(modelURL: URL) throws {

        // 1) Laden
        let loaded = try Entity.load(contentsOf: modelURL)

        self.root = Entity()
        root.name = "AvatarRoot"
        root.addChild(loaded)

        // 2) Container (Armature) finden
        guard let container = Avatar.findAvatarContainer(in: loaded) else {
            throw NSError(domain:"AvatarRigRK", code:2,
                          userInfo:[NSLocalizedDescriptionKey:"No avatar container found"])
        }

        // 3) Normalisieren
        let wrapper = Avatar.normalize(container)
        self.wrapper = wrapper
        root.addChild(wrapper)

        // 4) Blendshape-Entity finden
        guard let bEntity = Avatar.findBlendShapeEntity(in: wrapper),
              let modelComp = bEntity.components[ModelComponent.self]
        else {
            throw NSError(domain:"AvatarRigRK", code:1,
                          userInfo:[NSLocalizedDescriptionKey:"No model with blendshapes found"])
        }

        blendEntity = bEntity

        // 5) Blendshape-Komponente aktivieren
        let mapping = BlendShapeWeightsMapping(meshResource: modelComp.mesh)
        let comp = BlendShapeWeightsComponent(weightsMapping: mapping)
        blendEntity.components.set(comp)

        // 6) Namen → Index
        let set = comp.weightSet[0]
        var dict: [String:Int] = [:]
        for (i, name) in set.weightNames.enumerated() {
            dict[name] = i
        }
        indexByName = dict

        // 7) Komponenten vorbereiten
        let count = set.weights.count
        components[.viseme]  = Array(repeating: 0, count: count)
        components[.blink]   = Array(repeating: 0, count: count)
        components[.emotion] = Array(repeating: 0, count: count)
    }

    // MARK: - MorphWeighter

    func setWeight(_ w: CGFloat, index: Int) {
        var comp = blendComponent
        var set  = comp.weightSet[0]
        guard index >= 0 && index < set.weights.count else { return }
        set.weights[index] = Float(w)
        comp.weightSet[0] = set
        blendComponent = comp
    }

    func applyComponents(combine: (_ a: Float, _ b: Float) -> Float = max) {
        var comp = blendComponent
        var set = comp.weightSet[0]

        let vis = components[.viseme]  ?? []
        let bln = components[.blink]   ?? []
        let emo = components[.emotion] ?? []

        for i in 0..<set.weights.count {
            let v = combine(vis[safe:i], combine(bln[safe:i], emo[safe:i]))
            set.weights[i] = v
        }

        comp.weightSet[0] = set
        blendComponent = comp
    }

    func setComponent(_ compType: Component, index: Int, weight: Float) {
        guard var arr = components[compType], index >= 0 && index < arr.count else { return }
        arr[index] = weight
        components[compType] = arr
    }

    func setComponent(_ compType: Component, weights: [Float]) {
        components[compType] = weights
    }

    func index(of name: String) -> Int? { indexByName[name] }

    func resetAllWeights() {
        var comp = blendComponent
        var set = comp.weightSet[0]

        for i in 0..<set.weights.count { set.weights[i] = 0 }

        comp.weightSet[0] = set
        blendComponent = comp

        for key in components.keys {
            components[key] = Array(repeating: 0, count: targetCount)
        }
    }

    // MARK: - Traversal Helper (fix für "Entity has no member 'visit'")

    private static func visitHierarchy(
        start: Entity,
        block: (_ entity: Entity, _ stop: inout Bool) -> Void
    ) {

        var stop = false

        func recurse(_ e: Entity) {
            if stop { return }
            block(e, &stop)
            for child in e.children {
                recurse(child)
                if stop { return }
            }
        }

        recurse(start)
    }

    // MARK: - Static Finders

    static func findAvatarContainer(in root: Entity) -> Entity? {
        var result: Entity?
        visitHierarchy(start: root) { entity, stop in
            if entity.name.lowercased().contains("armature") {
                result = entity
                stop = true
            }
        }
        return result
    }

    static func findBlendShapeEntity(in root: Entity) -> Entity? {
        var best: (entity: Entity, score: Int)?
        visitHierarchy(start: root) { entity, stop in
            guard entity.components[ModelComponent.self] != nil else { return }

            let name = entity.name.lowercased()
            var score = 0
            if name.contains("wolf3d_head") { score += 200 }
            if name.contains("head")       { score += 100 }
            if name.contains("teeth")      { score += 10 }
            if name.contains("eye")        { score -= 5 }

            if best == nil || score > best!.score {
                best = (entity, score)
            }
        }
        return best?.entity
    }

    // MARK: - Normalize

    static func normalize(_ container: Entity) -> Entity {
        let wrapper = Entity()
        wrapper.name = "AvatarWrapper"
        wrapper.addChild(container)

        container.transform.scale = SIMD3<Float>(repeating: 1)
        container.transform.rotation = simd_quatf(angle: 0, axis: [0,1,0])

        let bounds = container.visualBounds(relativeTo: wrapper)
        let size = bounds.extents

        var t = container.transform

        if size.z > size.y {
            t.rotation = simd_quatf(angle: -.pi/2, axis: [1,0,0])
        }

        let center = bounds.center
        t.translation.x -= center.x
        t.translation.z -= center.z
        t.translation.y -= bounds.min.y

        container.transform = t
        return wrapper
    }
}

// Array-Safe-Index
private extension Array where Element == Float {
    subscript(safe i: Int) -> Float {
        (i >= 0 && i < count) ? self[i] : 0
    }
}




import Foundation
import RealityKit

@available(iOS 18.0, *)
final class Avatar: MorphWeighter {

    let root: Entity
    private let skinnedEntity: Entity?

    private(set) var indexByName: [String:Int] = [:]
    var targetCount: Int { weightNames.count }

    private var weightNames: [String] = []

    enum Component { case viseme, blink, emotion }
    private var components: [Component: [Float]] = [:]

    init(loadedEntity: Entity) {
        self.root = loadedEntity

        let skinned = Avatar.findSkinnedEntity(in: loadedEntity)
        self.skinnedEntity = skinned

        // --- NO iOS 18 CHECKS ---
        if let skinned,
           let comp = skinned.components[BlendShapeWeightsComponent.self],
           comp.weightSet.count > 0 {

            let names = comp.weightSet[0].weightNames

            self.weightNames = names
            for (i, name) in names.enumerated() {
                indexByName[name] = i
            }

            components[.viseme]  = Array(repeating: 0, count: names.count)
            components[.blink]   = Array(repeating: 0, count: names.count)
            components[.emotion] = Array(repeating: 0, count: names.count)

            print("🎭 Avatar BlendShapes:", names)
        }
    }

    // MARK: Weight setters

    func index(of name: String) -> Int? {
        indexByName[name]
    }

    func resetAll() {
        guard let skinned = skinnedEntity,
              var comp = skinned.components[BlendShapeWeightsComponent.self],
              comp.weightSet.count > 0 else { return }

        var weights = comp.weightSet[0].weights
        for i in 0..<weights.count {
            weights[i] = 0
        }
        comp.weightSet[0].weights = weights
        skinned.components[BlendShapeWeightsComponent.self] = comp

        for key in components.keys {
            components[key] = Array(repeating: 0, count: targetCount)
        }
    }

    func setWeight(_ w: CGFloat, index: Int) {
        // Gewicht direkt in den Component schreiben
        var comp = skinnedEntity?.components[BlendShapeWeightsComponent.self]!

        // Sicherheit: innerhalb der Bounds bleiben
        guard index >= 0, index < comp?.weightSet[0].weights.count else { return }

        var weights = comp?.weightSet[0].weights
        weights?[index] = Float(w)
        comp?.weightSet[0].weights = weights ?? <#default value#>

        skinnedEntity?.components[BlendShapeWeightsComponent.self] = comp
    }


    func setComponent(_ comp: Component, index: Int, weight: Float) {
        guard var arr = components[comp],
              index >= 0, index < arr.count else { return }

        arr[index] = weight
        components[comp] = arr
        applyComponents()
    }

    func setComponent(_ comp: Component, weights: [Float]) {
        components[comp] = weights
        applyComponents()
    }

    func applyComponents(combine: (_ a: Float, _ b: Float) -> Float = max) {
        guard let skinned = skinnedEntity,
              var comp = skinned.components[BlendShapeWeightsComponent.self],
              comp.weightSet.count > 0 else { return }

        let vis = components[.viseme]  ?? []
        let bli = components[.blink]   ?? []
        let emo = components[.emotion] ?? []

        var weights = comp.weightSet[0].weights

        for i in 0..<min(weights.count, targetCount) {
            weights[i] = combine(vis[i], combine(bli[i], emo[i]))
        }

        comp.weightSet[0].weights = weights
        skinned.components[BlendShapeWeightsComponent.self] = comp
    }

    // MARK: Entity scan

    private static func findSkinnedEntity(in root: Entity) -> Entity? {
        var found: Entity?

        root.visit { ent in
            if ent.components[BlendShapeWeightsComponent.self] != nil {
                let nm = ent.name.lowercased()

                if nm.contains("head") || nm.contains("armature") {
                    found = ent
                } else if found == nil {
                    found = ent
                }
            }
        }

        return found
    }
}

private extension Entity {
    func visit(_ block: (Entity) -> Void) {
        block(self)
        children.forEach { $0.visit(block) }
    }
}



*/

import SceneKit

/// Rig
final class AvatarRig: MorphWeighter {

    // Scene & Morpher
    let scene: SCNScene
    let wrapper: SCNNode
    
    let morpher: SCNMorpher
    let node: SCNNode
    
    // Head node for constraints
    private(set) var headNode: SCNNode?

    // Indizes
    private(set) var indexByName: [String:Int] = [:]
    var targetCount: Int { morpher.targets.count }

    
    enum Component { case viseme, blink, emotion }
    private var components: [Component: [CGFloat]] = [:]
    


    // MARK: Init / Loading
    init(modelURL: URL) throws {
        let srcScene = try SCNScene(url: modelURL, options: nil)

        guard let container = AvatarRig.findAvatarContainer(in: srcScene.rootNode) else {
            throw NSError(domain:"AvatarRig", code:2,
                          userInfo:[NSLocalizedDescriptionKey:"No visible container found"])
        }

        // normalize the avatar
        let wrapper = AvatarRig.normalize(container)
        let clean = SCNScene()
        clean.rootNode.addChildNode(wrapper)
        
        self.scene = clean
        self.wrapper = wrapper
        
        
        // find morpher
        guard let best = AvatarRig.findBestMorpherNode(in: wrapper),
              let m = best.morpher
        else { throw NSError(domain:"AvatarRig", code:1,
                             userInfo:[NSLocalizedDescriptionKey:"No morpher found"]) }
        
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
        
        // Find head bone
        self.headNode = AvatarRig.findHeadBone(in: wrapper)
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
            let nm = (node.name ?? "").lowercased()
            if nm.contains("head")  { score += 100 }   // wichtigster Bonus
            if nm.contains("wolf3d_head") { score += 200 } // ReadyPlayerMe sicher erkennen
            if nm.contains("teeth") { score += 10 }
            if nm.contains("eye")   { score -= 5 }
            if best == nil || score > best!.score { best = (node, score) }
        }
        return best?.node
    }

    
    static func findAvatarContainer(in root: SCNNode) -> SCNNode? {
        var best: SCNNode?
        root.enumerateChildNodes { n, stop in
            let nm = (n.name ?? "").lowercased()
            if nm.contains("armature") { // egal ob .001, .002 ...
                best = n
                stop.pointee = true
            }
        }
        
        return best
    }


    
    static func normalize(_ container: SCNNode) -> SCNNode {
            let wrapper = SCNNode(); wrapper.name = "AvatarWrapper"
            wrapper.addChildNode(container)

    
            container.scale = SCNVector3(1,1,1)
            container.eulerAngles = SCNVector3Zero

            
            let (minB, maxB) = container.boundingBox
            let size = SCNVector3(maxB.x - minB.x, maxB.y - minB.y, maxB.z - minB.z)
            if size.z > size.y { container.eulerAngles.x = -.pi/2 } // Z -> Y

            
            let sphere = container.presentation.boundingSphere
            container.position.x -= sphere.center.x
            container.position.z -= sphere.center.z
            container.position.y -= minB.y

        
            return wrapper
        }
    
    static func findHeadBone(in root: SCNNode) -> SCNNode? {
        var head: SCNNode?
        print("🔍 [NATIVE] Searching for head bone in root: \(root.name ?? "unnamed")")
        root.enumerateChildNodes { node, stop in
            let nm = (node.name ?? "").lowercased()
            // Look for common head bone names
            if nm.contains("head") && !nm.contains("top") && !nm.contains("end") {
                print("🎯 [NATIVE] Found head candidate: \(node.name ?? "unnamed") type: \(node.geometry == nil ? "Bone/Node" : "Mesh")")
                head = node
                stop.pointee = true
            }
        }
        if head == nil {
            print("❌ [NATIVE] No head bone found!")
        }
        return head
    }
    


}

private extension Array where Element == CGFloat {
    subscript(safe i: Int) -> CGFloat {
        (i >= 0 && i < count) ? self[i] : 0
    }
}

