//
//  AvatarAudioPlayer.swift
//  Runner
//
//  Created by Noah Tratzsch on 01.11.25.
//

import AVFoundation

final class AvatarAudioPlayer {

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var file: AVAudioFile?

    private(set) var sampleRate: Double = 48000.0
    private(set) var clock: AudioClock?

    init() throws {
        try setupSession()
        try setupEngine()
    }

    deinit {
        stop()
        engine.stop()
    }

    // Public API
    var isPlaying: Bool { player.isPlaying }

    func play(path: String) throws {
        let url = URL(fileURLWithPath: path)
        try play(url: url)
    }

    func play(url: URL) throws {
        if player.isPlaying { player.stop() }

        let f = try AVAudioFile(forReading: url)
        self.file = f

        let format = f.processingFormat
        self.sampleRate = format.sampleRate

        // Sicherstellen, dass PlayerNode mit passendem Format verbunden ist
        engine.disconnectNodeOutput(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        // (Re)start engine falls nötig
        if !engine.isRunning {
            try engine.start()
        }

        // Clock neu aufsetzen (jetzt mit korrekter Sample-Rate)
        self.clock = AVClock(player: player, sampleRate: self.sampleRate)

        // Abspielplan und Start
        player.stop()
        player.scheduleFile(f, at: nil, completionHandler: nil)
        player.play()
    }

    func stop() {
        player.stop()
        // optional: engine laufen lassen, um schnelle Folge-Starts zu erlauben
    }

    // MARK: Setup

    private func setupSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
    }

    private func setupEngine() throws {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        try engine.start()
    }
}
