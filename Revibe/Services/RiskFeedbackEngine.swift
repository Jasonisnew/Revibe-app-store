//
//  RiskFeedbackEngine.swift
//  Revibe
//

import Foundation

// MARK: - Risk Level

enum FeedbackRiskLevel {
    /// Logged only — surfaced in set-end summary, never shown mid-rep
    case minor
    /// Same mistake in 2+ consecutive reps — show a brief real-time cue
    case repeated
    /// Large deviation with injury potential — interrupt immediately
    case dangerous
}

// MARK: - Form Error

struct FormError {
    let key: String               // stable identifier, e.g. "elbowsBent"
    let label: String             // short user-facing text, e.g. "Elbows too bent"
    let risk: FeedbackRiskLevel
}

// MARK: - Feedback Decision

struct FeedbackDecision {
    /// Non-nil only when the engine decides to show a real-time correction cue
    let displayMessage: String?
    let level: FeedbackRiskLevel?
    let triggerDangerAlert: Bool
    let dangerMessage: String?

    static let none = FeedbackDecision(
        displayMessage: nil, level: nil,
        triggerDangerAlert: false, dangerMessage: nil
    )
}

// MARK: - Engine

/// Sits between the pose analyzer and the view model.
/// Receives raw per-frame errors and decides what (if anything) to show the user,
/// based on error severity, repetition count, and throttle rules.
final class RiskFeedbackEngine {

    // MARK: - Tunable thresholds

    /// Consecutive reps with the same error before escalating to a real-time cue
    var repeatedThreshold: Int = 2
    /// Minimum seconds between non-dangerous cues (prevents spamming)
    var minCueInterval: TimeInterval = 6.0

    // MARK: - Private state

    /// Per error key: how many consecutive reps it has appeared
    private var consecutiveRepErrors: [String: Int] = [:]
    /// Per error key: label + total count for set-end summary
    private var accumulator: [String: (label: String, count: Int)] = [:]
    /// Errors (key → label) seen during the current (in-progress) rep
    private var currentRepErrors: [String: String] = [:]
    /// Last rep count seen — used to detect rep completion
    private var lastRepCount: Int = 0
    /// Last time a real-time cue was emitted
    private var lastCueTime: Date = .distantPast

    // MARK: - Public API

    /// Call on every camera frame. Returns a decision about what to show the user.
    func evaluate(errors: [FormError], repCount: Int) -> FeedbackDecision {

        // 1. Detect completed rep
        if repCount > lastRepCount {
            commitCurrentRep()
            lastRepCount = repCount
        }

        // 2. Register errors observed during this rep
        for error in errors {
            currentRepErrors[error.key] = error.label
        }

        // 3. Dangerous errors always surface immediately, ignoring throttle
        if let danger = errors.first(where: { $0.risk == .dangerous }) {
            return FeedbackDecision(
                displayMessage: danger.label,
                level: .dangerous,
                triggerDangerAlert: true,
                dangerMessage: danger.label
            )
        }

        // 4. Repeated errors — only show if the throttle window has passed
        let now = Date()
        guard now.timeIntervalSince(lastCueTime) >= minCueInterval else { return .none }

        // Prioritise whichever error has the longest streak
        let sorted = errors.sorted {
            (consecutiveRepErrors[$0.key] ?? 0) > (consecutiveRepErrors[$1.key] ?? 0)
        }

        for error in sorted {
            let streak = consecutiveRepErrors[error.key] ?? 0
            if streak >= repeatedThreshold {
                lastCueTime = now
                return FeedbackDecision(
                    displayMessage: error.label,
                    level: .repeated,
                    triggerDangerAlert: false,
                    dangerMessage: nil
                )
            }
        }

        return .none
    }

    /// Call when a set ends (rest begins).
    /// Returns a human-readable summary of minor errors from the set, then resets set state.
    func beginNewSet() -> [String] {
        commitCurrentRep()
        let summary = buildSummary()
        accumulator = [:]
        consecutiveRepErrors = [:]
        currentRepErrors = [:]
        return summary
    }

    /// Full reset for a new session
    func reset() {
        consecutiveRepErrors = [:]
        accumulator = [:]
        currentRepErrors = [:]
        lastRepCount = 0
        lastCueTime = .distantPast
    }

    // MARK: - Private

    private func commitCurrentRep() {
        // Errors NOT seen this rep have their streak broken
        for key in consecutiveRepErrors.keys where currentRepErrors[key] == nil {
            consecutiveRepErrors[key] = 0
        }
        // Errors seen this rep increment both streak and accumulator
        for (key, label) in currentRepErrors {
            consecutiveRepErrors[key] = (consecutiveRepErrors[key] ?? 0) + 1
            var entry = accumulator[key] ?? (label: label, count: 0)
            entry.count += 1
            accumulator[key] = entry
        }
        currentRepErrors = [:]
    }

    private func buildSummary() -> [String] {
        accumulator
            .sorted { $0.value.count > $1.value.count }
            .compactMap { _, entry in entry.count > 0 ? "\(entry.count)× \(entry.label)" : nil }
    }
}
