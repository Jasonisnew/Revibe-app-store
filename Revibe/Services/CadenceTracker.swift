//
//  CadenceTracker.swift
//  Revibe
//
//  Tracks the cadence (beats per minute) of the user's movement based on
//  beat events emitted by an exercise analyzer (e.g. `LateralRaiseAnalyzer`).
//
//  A "beat" is one meaningful movement transition — for a lateral raise that
//  is the top of the raise and the return to the bottom (two beats per rep).
//
//  The tracker keeps a small rolling window of beat timestamps and exposes a
//  smoothed BPM value clamped to a sane range. It is intentionally
//  decoupled from any specific exercise so other analyzers (squat, jumping
//  jack, etc.) can push beats through the same pipeline.
//

import Foundation
import Combine

@MainActor
final class CadenceTracker: ObservableObject {

    // MARK: - Published state

    /// Current smoothed beats-per-minute. `nil` until enough beats have been
    /// observed to compute a stable estimate.
    @Published private(set) var bpm: Double? = nil

    /// Monotonically increasing counter of recorded beats. Useful for views
    /// that want to react to each beat without re-deriving from BPM.
    @Published private(set) var beatCount: Int = 0

    // MARK: - Tunables

    /// Number of inter-beat intervals to average over when computing BPM.
    /// Larger = more stable, smaller = more responsive.
    private let maxHistory: Int = 8

    /// Hard floor / ceiling on reported BPM. Prevents nonsense values when
    /// the user pauses mid-rep or jitters at a rest position.
    private let minBPM: Double = 20
    private let maxBPM: Double = 180

    // MARK: - Private state

    private var timestamps: [Date] = []

    // MARK: - Public API

    /// Record a single beat at the current instant. Safe to call rapidly —
    /// the rolling history limits memory use.
    func recordBeat() {
        let now = Date()
        timestamps.append(now)
        if timestamps.count > maxHistory + 1 {
            timestamps.removeFirst()
        }
        beatCount += 1
        bpm = computeBPM()
    }

    /// Reset all internal state. Call when a workout starts or stops.
    func reset() {
        timestamps = []
        bpm = nil
        beatCount = 0
    }

    // MARK: - Private

    private func computeBPM() -> Double? {
        guard timestamps.count >= 3 else { return nil }
        let intervals = zip(timestamps, timestamps.dropFirst())
            .map { $1.timeIntervalSince($0) }
        let sum = intervals.reduce(0, +)
        guard sum > 0 else { return nil }
        let avgInterval = sum / Double(intervals.count)
        guard avgInterval > 0.1 else { return nil }
        let raw = 60.0 / avgInterval
        return min(maxBPM, max(minBPM, raw))
    }
}
