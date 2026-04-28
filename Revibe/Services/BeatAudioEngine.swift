//
//  BeatAudioEngine.swift
//  Revibe
//
//  Plays a short percussive click in time with the user's movement. The click
//  is synthesized in code (no audio file needed) and scheduled through
//  `AVAudioEngine` so playback is sample-accurate and won't queue up if beats
//  arrive faster than the click's natural duration.
//
//  This service intentionally does NOT configure the shared `AVAudioSession`
//  — `AudioCoachService` already manages it (with `.mixWithOthers` so the
//  user's background music continues to play). The click simply mixes on top.
//

import Foundation
import AVFoundation

@MainActor
final class BeatAudioEngine {

    // MARK: - Audio graph

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var clickBuffer: AVAudioPCMBuffer?

    /// Output volume for the click (0.0 – 1.0). Kept low enough that the
    /// click feels like a metronome rather than a full instrument hit.
    var volume: Float = 0.45 {
        didSet { playerNode.volume = volume }
    }

    // MARK: - Lifecycle

    init() {
        setupEngine()
    }

    deinit {
        playerNode.stop()
        if engine.isRunning { engine.stop() }
    }

    // MARK: - Setup

    private func setupEngine() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100,
                                         channels: 1) else {
            return
        }

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        playerNode.volume = volume

        clickBuffer = synthesizeClick(format: format)

        do {
            try engine.start()
        } catch {
            // If the engine fails to start (rare), playClick() becomes a no-op.
            // We don't want this to crash the workout view.
            print("[BeatAudioEngine] failed to start engine: \(error)")
        }
    }

    /// Build a short percussive click in memory: a fast-decaying ~1 kHz sine
    /// burst. ~50 ms total duration — short enough that consecutive beats
    /// don't smear into each other.
    private func synthesizeClick(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double = 0.05
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let channel = buffer.floatChannelData?[0] else { return nil }

        let frequency: Double = 1000
        let twoPi = 2.0 * Double.pi
        let decay: Double = 60.0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * decay)
            let sample = sin(twoPi * frequency * t) * envelope
            channel[i] = Float(sample)
        }
        return buffer
    }

    // MARK: - Public API

    /// Schedule a single click immediately. Safe to call from any beat-event
    /// callback. If a previous click is still playing, this one interrupts
    /// it cleanly.
    func playClick() {
        guard let buffer = clickBuffer, engine.isRunning else { return }
        playerNode.scheduleBuffer(buffer,
                                  at: nil,
                                  options: [.interrupts],
                                  completionHandler: nil)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    /// Stop playback and tear down the engine. Call from `onDisappear` of
    /// the workout view to release audio resources.
    func stop() {
        playerNode.stop()
        if engine.isRunning {
            engine.stop()
        }
    }

    /// Resume the engine after a previous `stop()`. Idempotent.
    func resume() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            print("[BeatAudioEngine] failed to resume engine: \(error)")
        }
    }
}
