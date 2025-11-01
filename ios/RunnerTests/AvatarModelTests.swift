//
//  AvatarModelTests.swift
//  Runner
//
//  Created by Noah Tratzsch on 01.11.25.
//
import XCTest
import SceneKit

final class AvatarModelTests: XCTestCase {
    func testAvatarHasMorpherAndTargets() throws {
        let url = Bundle.main.url(forResource: "avatar_new2", withExtension: "usdz")
        XCTAssertNotNil(url, "Model not found")

        let scene = try SCNScene(url: url!, options: nil)
        var foundMorpher: SCNMorpher?
        scene.rootNode.enumerateChildNodes { node, _ in
            if let m = node.morpher { foundMorpher = m }
        }

        XCTAssertNotNil(foundMorpher, "No SCNMorpher")
        XCTAssertFalse(foundMorpher!.targets.isEmpty, "No blendshape targets found")
    }
}
