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

    // ✅ NEW: Trigger single viseme immediately for TTS-based lip sync
    func triggerViseme(name: String, duration: Double, weight: CGFloat = 0.8) {
        print("🎭 [VisemeScheduler] triggerViseme called: \(name), duration: \(duration)s")
        
        guard let index = visemeNameToIndex(name) else {
            print("⚠️ [VisemeScheduler] Unknown viseme: \(name)")
            return
        }
        
        print("✅ [VisemeScheduler] Mapped \(name) to index: \(index)")
        
        let now = clock.nowSamples()
        let durationSamples = Int64(duration * Double(clock.sampleRate))
        
        let event = VisemeEvent(
            index: index,
            start: now,
            end: now + durationSamples,
            weight: weight
        )
        
        // Add to active immediately
        active[index] = event
        morpher.setWeight(weight, index: index)
        
        print("🎬 [VisemeScheduler] Applied weight \(weight) to index \(index)")
        
        // Schedule to remove after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.active.removeValue(forKey: index)
            self?.morpher.setWeight(0, index: index)
            print("⏹️ [VisemeScheduler] Cleared viseme \(name)")
        }
    }
    
    // ✅ NEW: Map viseme names to blend shape indices
    private func visemeNameToIndex(_ name: String) -> Int? {
        // Standard ARKit viseme mapping
        let visemeMap: [String: Int] = [
            "viseme_sil": 0,  // Silence
            "viseme_PP": 1,   // P, B, M
            "viseme_FF": 2,   // F, V
            "viseme_TH": 3,   // TH
            "viseme_DD": 4,   // D, T, N
            "viseme_kk": 5,   // K, G
            "viseme_CH": 6,   // CH, J, SH
            "viseme_SS": 7,   // S, Z
            "viseme_nn": 8,   // N, NG
            "viseme_RR": 9,   // R
            "viseme_aa": 10,  // AA, AH
            "viseme_E": 11,   // E, EH
            "viseme_I": 12,   // I, IH
            "viseme_O": 13,   // O, OH
            "viseme_U": 14,   // U, UH, OO
        ]
        return visemeMap[name]
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