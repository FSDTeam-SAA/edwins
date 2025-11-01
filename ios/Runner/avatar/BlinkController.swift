//
//  BlinkController..swift
//  Runner
//
//  Created by Noah Tratzsch on 01.11.25.
//
import Foundation
import CoreGraphics

final class BlinkController {
    private let morpher: MorphWeighter
    private let leftIdx: Int?
    private let rightIdx: Int?

    // 0..1: 0 = open, 1 = closed
    private var phase: CGFloat = 0.0
    // 0=waiting, +1 close, -1 open
    private var direction: CGFloat = 0.0

    /// Higher ->  faster
    var speed: CGFloat = 7.5

    private var nextBlinkTime: CFTimeInterval = 0
    /// randomization  (Sekunden)
    var waitRange: ClosedRange<Double> = 2.5...4.0

    init(morpher: MorphWeighter, leftIdx: Int?, rightIdx: Int?) {
        self.morpher = morpher
        self.leftIdx = leftIdx
        self.rightIdx = rightIdx
        scheduleNextBlink(now: CACurrentMediaTime())
    }

    /// uses cftime not clock since its indipendent from audio
    func tick(dt: CGFloat, now: CFTimeInterval) {
        // 1) State-Automat
        if direction == 0 {
            if now >= nextBlinkTime {
                direction = 1 // close
                phase = 0
            }
        } else {
            // animate
            phase += direction * speed * dt
            if phase >= 1 {
                phase = 1
                direction = -1 // open
            } else if phase <= 0 {
                phase = 0
                direction = 0
                scheduleNextBlink(now: now)
            }
        }

        // smoothstep) 
        let t = phase
        let eased = t * t * (3 - 2 * t)

        if let l = leftIdx   { morpher.setWeight(eased, index: l) }
        if let r = rightIdx  { morpher.setWeight(eased, index: r) }
    }

    private func scheduleNextBlink(now: CFTimeInterval) {
        let wait = CFTimeInterval(Double.random(in: waitRange))
        nextBlinkTime = now + wait
        phase = 0
        direction = 0
    }
}
