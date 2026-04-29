//
//  WorkoutMusicPlayer.swift
//  Revibe
//
//  Procedural adaptive workout music. A short rhythmic loop (kick, hat, bass)
//  is synthesized in code at a reference tempo and looped through an
//  `AVAudioPlayerNode`. The loop is routed through an `AVAudioUnitTimePitch`
//  so tempo can be smoothly varied to follow the user's movement cadence
//  WITHOUT changing the pitch of the music.
//
//  This service replaces the previous metronome-style click engine. Beat
//  events from `LateralRaiseAnalyzer` no longer drive an audio click — the
//  music itself provides the rhythm, and `CadenceTracker.bpm` drives the
//  music's tempo.
//

import Foundation
import AVFoundation

@MainActor
final class WorkoutMusicPlayer {

    // MARK: - Audio graph

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()
    private var loopBuffer: AVAudioPCMBuffer?

    // MARK: - Tunables

    /// BPM at which the loop is rendered. Playback rate is computed relative to this.
    private let referenceBPM: Double = 120
    /// Clamp range for what we'll actually play — keeps the music musical.
    private let minBPM: Double = 70
    private let maxBPM: Double = 130
    /// Smoothing factor for tempo changes (0 = instant, 1 = never updates).
    private let tempoSmoothing: Double = 0.85

    /// Output volume (0.0 – 1.0). Kept moderate so the voice coach sits on top cleanly.
    var volume: Float = 0.32 {
        didSet { player.volume = volume }
    }

    /// Currently active tempo (smoothed).
    private(set) var currentBPM: Double = 90

    // MARK: - Lifecycle

    init() {
        setupGraph()
        loopBuffer = synthesizeLoop()
    }

    deinit {
        player.stop()
        if engine.isRunning { engine.stop() }
    }

    // MARK: - Public API

    /// Begin playing the looping backing track at the given starting tempo.
    /// Safe to call repeatedly; subsequent calls are ignored if already playing.
    func start(initialBPM: Double = 90) {
        currentBPM = clamp(initialBPM)
        timePitch.rate = Float(currentBPM / referenceBPM)

        guard let buffer = loopBuffer else { return }
        guard !player.isPlaying else { return }

        do {
            if !engine.isRunning {
                try engine.start()
            }
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            player.play()
        } catch {
            print("[WorkoutMusicPlayer] failed to start engine: \(error)")
        }
    }

    /// Update the target tempo. Smoothed internally so sudden cadence
    /// changes don't cause jarring rate jumps.
    func setBPM(_ bpm: Double) {
        let target = clamp(bpm)
        currentBPM = currentBPM * tempoSmoothing + target * (1 - tempoSmoothing)
        timePitch.rate = Float(currentBPM / referenceBPM)
    }

    /// Stop playback and release engine resources.
    func stop() {
        player.stop()
        if engine.isRunning { engine.stop() }
    }

    // MARK: - Setup

    private func setupGraph() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2) else {
            return
        }
        engine.attach(player)
        engine.attach(timePitch)
        engine.connect(player, to: timePitch, format: format)
        engine.connect(timePitch, to: engine.mainMixerNode, format: format)
        timePitch.pitch = 0
        player.volume = volume
    }

    private func clamp(_ bpm: Double) -> Double {
        return min(maxBPM, max(minBPM, bpm))
    }

    // MARK: - Procedural loop synthesis

    /// Synthesize an 8-beat backing loop at `referenceBPM`. Pattern:
    /// kick on beats 0/2/4/6, closed hat on offbeats, bass pluck on every beat
    /// in an A-minor walking pattern. Total length is exactly an integer
    /// number of beats so the buffer loops seamlessly.
    private func synthesizeLoop() -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2) else {
            return nil
        }

        let sampleRate = format.sampleRate
        let beatDuration = 60.0 / referenceBPM
        let beatsPerLoop = 8
        let totalDuration = beatDuration * Double(beatsPerLoop)
        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount
        guard let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else { return nil }

        let totalFrames = Int(frameCount)
        for i in 0..<totalFrames {
            left[i] = 0
            right[i] = 0
        }

        // A-minor walking bass: A2 → A2 → E2 → A2 → A2 → A2 → G2 → A2
        let bassNotes: [Double] = [110.00, 110.00, 82.41, 110.00,
                                   110.00, 110.00, 98.00, 110.00]

        for beat in 0..<beatsPerLoop {
            let beatStartFrame = Int(Double(beat) * beatDuration * sampleRate)

            if beat % 2 == 0 {
                addKick(left: left, right: right,
                        startFrame: beatStartFrame, totalFrames: totalFrames,
                        sampleRate: sampleRate, gain: 0.75)
            } else {
                addHat(left: left, right: right,
                       startFrame: beatStartFrame, totalFrames: totalFrames,
                       sampleRate: sampleRate, gain: 0.28)
            }

            addBass(left: left, right: right,
                    startFrame: beatStartFrame, totalFrames: totalFrames,
                    freq: bassNotes[beat], duration: beatDuration * 0.92,
                    sampleRate: sampleRate, gain: 0.42)
        }

        // Soft compression / limiter to keep the loop from clipping
        normalize(left: left, right: right, frameCount: totalFrames, ceiling: 0.9)

        return buffer
    }

    // MARK: - Voice synthesis helpers

    /// Punchy kick drum: pitched sine sweep from ~140 Hz down to ~60 Hz with a fast amp envelope.
    private func addKick(left: UnsafeMutablePointer<Float>,
                         right: UnsafeMutablePointer<Float>,
                         startFrame: Int, totalFrames: Int,
                         sampleRate: Double, gain: Double) {
        let duration: Double = 0.18
        let n = Int(duration * sampleRate)
        let twoPi = 2.0 * Double.pi
        let pitchDecay: Double = 12
        let ampDecay: Double = 9

        var phase: Double = 0
        for i in 0..<n {
            let frame = startFrame + i
            if frame >= totalFrames { break }
            let t = Double(i) / sampleRate
            let freq = 60 + 80 * exp(-t * pitchDecay)
            phase += twoPi * freq / sampleRate
            let env = exp(-t * ampDecay)
            let s = Float(sin(phase) * env * gain)
            left[frame] += s
            right[frame] += s
        }
    }

    /// Closed hi-hat: short burst of high-passed white noise.
    private func addHat(left: UnsafeMutablePointer<Float>,
                        right: UnsafeMutablePointer<Float>,
                        startFrame: Int, totalFrames: Int,
                        sampleRate: Double, gain: Double) {
        let duration: Double = 0.06
        let n = Int(duration * sampleRate)
        let decay: Double = 75
        var seed: UInt32 = 0xA5A5A5A5
        var prevSample: Double = 0

        for i in 0..<n {
            let frame = startFrame + i
            if frame >= totalFrames { break }
            let t = Double(i) / sampleRate
            seed = seed &* 1664525 &+ 1013904223
            let raw = (Double(seed) / Double(UInt32.max)) * 2.0 - 1.0
            // simple high-pass: subtract a heavily smoothed copy
            prevSample = prevSample * 0.85 + raw * 0.15
            let highPassed = raw - prevSample
            let env = exp(-t * decay)
            let s = highPassed * env * gain
            left[frame] += Float(s * 0.92)
            right[frame] += Float(s)
        }
    }

    /// Plucked bass tone: sine + saw blend with quick attack and exponential decay.
    private func addBass(left: UnsafeMutablePointer<Float>,
                         right: UnsafeMutablePointer<Float>,
                         startFrame: Int, totalFrames: Int,
                         freq: Double, duration: Double,
                         sampleRate: Double, gain: Double) {
        let n = Int(duration * sampleRate)
        let twoPi = 2.0 * Double.pi
        let attack: Double = 0.005
        let decay: Double = 3.5

        for i in 0..<n {
            let frame = startFrame + i
            if frame >= totalFrames { break }
            let t = Double(i) / sampleRate

            let env: Double
            if t < attack {
                env = t / attack
            } else {
                env = exp(-(t - attack) * decay)
            }

            let phase = twoPi * freq * t
            let sine = sin(phase)
            let saw  = 2.0 * (freq * t - floor(freq * t + 0.5))
            let mixed = sine * 0.7 + saw * 0.3
            let s = Float(mixed * env * gain)
            left[frame] += s
            right[frame] += s
        }
    }

    /// Hard limiter — scales down the buffer if peaks exceed `ceiling`.
    private func normalize(left: UnsafeMutablePointer<Float>,
                           right: UnsafeMutablePointer<Float>,
                           frameCount: Int, ceiling: Float) {
        var peak: Float = 0
        for i in 0..<frameCount {
            peak = max(peak, abs(left[i]))
            peak = max(peak, abs(right[i]))
        }
        guard peak > ceiling else { return }
        let scale = ceiling / peak
        for i in 0..<frameCount {
            left[i] *= scale
            right[i] *= scale
        }
    }
}
