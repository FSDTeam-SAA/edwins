//
//  AudioClock.swift
//  Runner
//
//  Created by Noah Tratzsch on 01.11.25.
//
import AVFoundation

protocol AudioClock {
    var sampleRate: Double { get }
    func nowSamples() -> Int64
}

final class AVClock: AudioClock {
    private let player: AVAudioPlayerNode
    let sampleRate: Double

    init(player: AVAudioPlayerNode, sampleRate: Double) {
        self.player = player
        self.sampleRate = sampleRate
    }
    
    func nowSamples() -> Int64 {
        guard
            let nodeTime = player.lastRenderTime,
            let t = player.playerTime(forNodeTime: nodeTime)
        else {
            return 0
        }
        return Int64(t.sampleTime)
    }
}

// ✅ NEW: Clock for TTS-based visemes (without audio file)
final class TTSClock: AudioClock {
    private var startTime: TimeInterval = 0
    let sampleRate: Double = 44100.0
    
    init() {
        self.startTime = CACurrentMediaTime()
    }
    
    func nowSamples() -> Int64 {
        let elapsed = CACurrentMediaTime() - startTime
        return Int64(elapsed * sampleRate)
    }
    
    func reset() {
        startTime = CACurrentMediaTime()
    }
}