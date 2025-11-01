import Foundation
import CoreGraphics


final class VisemeScheduler {
    private let clock: AudioClock
    private let morpher: MorphWeighter

    private var queue: [VisemeEvent] = []

    // current events
    private var active: [Int: VisemeEvent] = [:]

    // Test logging, optional
    private var logEnabled = false
    private var log: [(ts: Int64, idx: Int, w: CGFloat)] = []

    init(clock: AudioClock, morpher: MorphWeighter) {
        self.clock = clock
        self.morpher = morpher
    }

    func enableLog(_ on: Bool) {
        logEnabled = on
        log.removeAll()
    }

    func fetchLog() -> [(Int64, Int, CGFloat)] { log }

    func clear() {
        queue.removeAll()
        active.removeAll()
        for i in 0..<morpher.targetCount {
            morpher.setWeight(0, index: i)
        }
    }

    func enqueue(_ batch: [VisemeEvent]) {
        guard !batch.isEmpty else { return }
        queue.append(contentsOf: batch)
        queue.sort { $0.start < $1.start }
    }

    // tick via clock
    func tick() {
        let now = clock.nowSamples()

        // activate events
        while let e = queue.first, e.start <= now {
            queue.removeFirst()
            active[e.index] = e
        }

        // play events
        if !active.isEmpty {
            for (idx, e) in active {
                if now >= e.end {
                    active.removeValue(forKey: idx)
                    morpher.setWeight(0, index: idx)
                    if logEnabled { log.append((now, idx, 0)) }
                } else {
                    let w = e.weight
                    morpher.setWeight(w, index: idx)
                    if logEnabled { log.append((now, idx, w)) }
                }
            }
        }
        
        // clear when finished
        if queue.isEmpty && active.isEmpty {
            clear()
        }
    }
}
