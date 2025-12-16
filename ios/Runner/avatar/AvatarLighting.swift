//
//  AvatarLighting.swift
//  Runner
//
//  Created by Noah Tratzsch on 19.11.25.
//
import RealityKit

final class AvatarLighting {

    static func applyBasicLighting(to anchor: AnchorEntity) {
        // Key Light (Directional) – von oben vorne
        let keyLight = DirectionalLight()
        keyLight.light.intensity = 5000       // lux
        keyLight.light.color = .white

        // Orientierung: leicht von oben vorne
        let tiltDown  = simd_quatf(angle: -.pi / 4, axis: [1, 0, 0]) // nach unten
        let fromSide  = simd_quatf(angle:  .pi / 8, axis: [0, 1, 0]) // leicht von rechts
        keyLight.orientation = tiltDown * fromSide

        anchor.addChild(keyLight)

        // Fill Light (Point) – weiches Aufhellen von vorne
        let fillLight = PointLight()
        fillLight.light.intensity = 3000
        fillLight.light.color = .white
        fillLight.position = [0, 2, 2]   // vor & über dem Avatar

        anchor.addChild(fillLight)
    }
}
