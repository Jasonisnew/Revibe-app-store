//
//  LateralRaiseAnalyzer.swift
//  Revibe
//
//  Angle convention (from horizontal):
//    0°  = arm perfectly level with the shoulder (target)
//   -10° to +10° = correct range
//   < -10° = arm below shoulder level → "Raise arm higher"
//   > +10° = arm above shoulder level → "Lower your arm"
//

import Foundation
import MediaPipeTasksVision

// MARK: - Landmark indices (MediaPipe Pose, 33 points)
// Reference: https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker
private enum LM {
    static let leftShoulder  = 11
    static let rightShoulder = 12
    static let leftElbow     = 13
    static let rightElbow    = 14
    static let leftWrist     = 15
    static let rightWrist    = 16
    static let leftHip       = 23
    static let rightHip      = 24
}

// MARK: - Form Quality

enum FormQuality: String {
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var color: String {
        switch self {
        case .good: return "green"
        case .fair: return "yellow"
        case .poor: return "red"
        }
    }
}

// MARK: - Result

struct LateralRaiseFrameResult {
    let feedbackText: String
    let repCount: Int
    let progress: Double
    let landmarks: [NormalizedLandmark]
    let formErrors: [FormError]
    let formQuality: FormQuality

    /// Flat label strings for legacy display paths
    var errorLabels: [String] { formErrors.map { $0.label } }
}

// MARK: - Analyzer

final class LateralRaiseAnalyzer {

    // MARK: Tunable thresholds

    /// Correct arm-height range relative to horizontal (0° = perfectly level).
    /// Negative means arm is below shoulder; positive means arm is above shoulder.
    var correctMin: Double = -40
    var correctMax: Double =  40

    /// Arms are considered "at rest / down" when their signed angle is below this.
    var restThreshold: Double = -45

    /// Arms are considered "at the top" (rep triggered) when signed angle is ≥ this.
    var peakThreshold: Double = -25

    /// Elbow angle below this → arm is moderately too bent — minor error
    var elbowBentThreshold: Double = 140
    /// Elbow angle below this → severe bend with joint strain risk — dangerous error
    var elbowDangerThreshold: Double = 100

    /// Torso lean above this → user is swinging / leaning — minor error
    var torsoLeanThreshold: Double = 18
    /// Torso lean above this → significant injury risk — dangerous error
    var torsoDangerThreshold: Double = 30

    /// Frames of history to average for smoothing (reduces jitter).
    let smoothingWindow: Int = 6

    // MARK: Private state

    private enum Phase { case down, goingUp, up, goingDown }
    private var phase: Phase = .down
    private var repCount = 0
    private var targetReps: Int = 10

    // Smoothing ring buffers
    private var leftHistory:   [Double] = []
    private var rightHistory:  [Double] = []
    private var lElbowHistory: [Double] = []
    private var rElbowHistory: [Double] = []
    private var torsoHistory:  [Double] = []

    // MARK: Public API

    func setTargetReps(_ reps: Int) { targetReps = max(1, reps) }

    func reset() {
        phase       = .down
        repCount    = 0
        leftHistory   = []
        rightHistory  = []
        lElbowHistory = []
        rElbowHistory = []
        torsoHistory  = []
    }

    /// Returns nil when the required landmarks aren't visible (person not in frame).
    func analyze(landmarks: [NormalizedLandmark]) -> LateralRaiseFrameResult? {
        guard landmarks.count > LM.rightHip else { return nil }

        // ── 1. Raw angles ──────────────────────────────────────────────────
        // signedShoulderAngle: 0° = arm level, negative = below, positive = above
        let rawLeft  = signedShoulderAngle(shoulder: landmarks[LM.leftShoulder],
                                           elbow:    landmarks[LM.leftElbow],
                                           side:     .left)
        let rawRight = signedShoulderAngle(shoulder: landmarks[LM.rightShoulder],
                                           elbow:    landmarks[LM.rightElbow],
                                           side:     .right)

        let rawLElbow = elbowAngle(shoulder: landmarks[LM.leftShoulder],
                                   elbow:    landmarks[LM.leftElbow],
                                   wrist:    landmarks[LM.leftWrist])
        let rawRElbow = elbowAngle(shoulder: landmarks[LM.rightShoulder],
                                   elbow:    landmarks[LM.rightElbow],
                                   wrist:    landmarks[LM.rightWrist])

        let rawTorso  = torsoAngle(leftShoulder:  landmarks[LM.leftShoulder],
                                   rightShoulder: landmarks[LM.rightShoulder],
                                   leftHip:       landmarks[LM.leftHip],
                                   rightHip:      landmarks[LM.rightHip])

        // ── 2. Smooth ──────────────────────────────────────────────────────
        let leftAngle  = smooth(&leftHistory,   value: rawLeft)
        let rightAngle = smooth(&rightHistory,  value: rawRight)
        let lElbow     = smooth(&lElbowHistory, value: rawLElbow)
        let rElbow     = smooth(&rElbowHistory, value: rawRElbow)
        let torso      = smooth(&torsoHistory,  value: rawTorso)
        let avgAngle   = (leftAngle + rightAngle) / 2

        // ── 3. Phase state machine ─────────────────────────────────────────
        // avgAngle is the signed degrees-from-horizontal of both arms combined.
        // restThreshold ≈ -65° (arms at side), peakThreshold ≈ -15° (near level).
        switch phase {
        case .down:
            if avgAngle >= peakThreshold        { phase = .up }
            else if avgAngle > restThreshold    { phase = .goingUp }
        case .goingUp:
            if avgAngle >= peakThreshold        { phase = .up }
            else if avgAngle <= restThreshold   { phase = .down }
        case .up:
            if avgAngle < peakThreshold         { phase = .goingDown }
        case .goingDown:
            if avgAngle <= restThreshold {
                phase = .down
                repCount += 1
            } else if avgAngle >= peakThreshold {
                phase = .up
            }
        }

        // ── 4. Feedback + errors ─────────────────────────────────────────
        let (feedback, errors, quality) = buildDetailedFeedback(
            leftAngle:  leftAngle,
            rightAngle: rightAngle,
            lElbow:     lElbow,
            rElbow:     rElbow,
            torso:      torso,
            phase:      phase
        )

        let progress = min(1.0, Double(repCount) / Double(targetReps))

        return LateralRaiseFrameResult(
            feedbackText: feedback,
            repCount:     repCount,
            progress:     progress,
            landmarks:    landmarks,
            formErrors:   errors,
            formQuality:  quality
        )
    }

    // MARK: - Geometry helpers

    private enum Side { case left, right }

    /// Signed angle of the arm relative to horizontal (shoulder level).
    ///  0°  = arm perfectly level with the shoulder.
    /// < 0° = arm below shoulder level.
    /// > 0° = arm above shoulder level.
    private func signedShoulderAngle(shoulder: NormalizedLandmark,
                                     elbow:    NormalizedLandmark,
                                     side:     Side) -> Double {
        // In image coords: x increases right, y increases downward.
        // We compute the vector from shoulder to elbow, then find the angle
        // between that vector and the horizontal (positive-x axis for right arm,
        // negative-x axis for left arm).  Positive result = above horizontal.

        let dx = Double(elbow.x - shoulder.x)
        // dy in image coords: negative dy means elbow is ABOVE shoulder in display.
        let dy = Double(elbow.y - shoulder.y)

        // For the right arm the elbow should be to the right (dx > 0 when raised).
        // For the left  arm the elbow should be to the left  (dx < 0 when raised).
        // atan2(-dy, abs(dx)) gives 0 when the arm is horizontal,
        // negative when the arm is below horizontal, positive when above.
        let signedDx: Double
        switch side {
        case .right: signedDx =  dx   // expect positive dx when arm is raised
        case .left:  signedDx = -dx   // flip so negative dx also becomes positive
        }

        // atan2(-dy, signedDx):
        //   signedDx > 0, dy ≈ 0  → angle ≈ 0°  (horizontal – correct)
        //   signedDx > 0, dy > 0  → angle < 0°  (elbow below shoulder – too low)
        //   signedDx > 0, dy < 0  → angle > 0°  (elbow above shoulder – too high)
        let radians = atan2(-dy, signedDx)
        return radians * 180 / .pi
    }

    /// Interior angle at the elbow joint (shoulder→elbow→wrist). 180° = fully straight.
    private func elbowAngle(shoulder: NormalizedLandmark,
                            elbow:    NormalizedLandmark,
                            wrist:    NormalizedLandmark) -> Double {
        let v1x = Double(shoulder.x - elbow.x), v1y = Double(shoulder.y - elbow.y)
        let v2x = Double(wrist.x    - elbow.x), v2y = Double(wrist.y    - elbow.y)
        let dot  = v1x * v2x + v1y * v2y
        let mag1 = sqrt(v1x * v1x + v1y * v1y)
        let mag2 = sqrt(v2x * v2x + v2y * v2y)
        guard mag1 > 0, mag2 > 0 else { return 180 }
        let cosA = max(-1, min(1, dot / (mag1 * mag2)))
        return acos(cosA) * 180 / .pi
    }

    /// Degrees the torso deviates from vertical. 0° = perfectly upright.
    private func torsoAngle(leftShoulder:  NormalizedLandmark,
                            rightShoulder: NormalizedLandmark,
                            leftHip:       NormalizedLandmark,
                            rightHip:      NormalizedLandmark) -> Double {
        let midShoulderX = Double(leftShoulder.x + rightShoulder.x) / 2
        let midShoulderY = Double(leftShoulder.y + rightShoulder.y) / 2
        let midHipX      = Double(leftHip.x      + rightHip.x)      / 2
        let midHipY      = Double(leftHip.y       + rightHip.y)      / 2
        let dx = midShoulderX - midHipX
        let dy = midShoulderY - midHipY   // negative in display = shoulder above hip ✓
        return abs(atan2(dx, -dy) * 180 / .pi)
    }

    // MARK: - Smoothing

    private func smooth(_ history: inout [Double], value: Double) -> Double {
        history.append(value)
        if history.count > smoothingWindow { history.removeFirst() }
        return history.reduce(0, +) / Double(history.count)
    }

    // MARK: - Feedback builder

    private func buildDetailedFeedback(leftAngle:  Double,
                                       rightAngle: Double,
                                       lElbow:     Double,
                                       rElbow:     Double,
                                       torso:      Double,
                                       phase:      Phase) -> (String, [FormError], FormQuality) {

        let avgAngle = (leftAngle + rightAngle) / 2
        var errors: [FormError] = []

        // Torso lean — dangerous threshold first
        if torso > torsoDangerThreshold {
            errors.append(FormError(key: "torsoDanger", label: "Stop — reset your posture", risk: .dangerous))
        } else if torso > torsoLeanThreshold {
            errors.append(FormError(key: "torsoLean", label: "Leaning — keep upright", risk: .minor))
        }

        // Elbow bend — dangerous threshold first
        let minElbow = min(lElbow, rElbow)
        if minElbow < elbowDangerThreshold {
            errors.append(FormError(key: "elbowDanger", label: "Elbows too bent — strain risk", risk: .dangerous))
        } else if minElbow < elbowBentThreshold {
            errors.append(FormError(key: "elbowBent", label: "Soften the elbows", risk: .minor))
        }

        // Arm symmetry (only flag during the active raising/holding phase)
        if phase == .goingUp || phase == .up {
            let leftOk  = leftAngle  >= correctMin && leftAngle  <= correctMax
            let rightOk = rightAngle >= correctMin && rightAngle <= correctMax
            if !leftOk && rightOk {
                errors.append(FormError(key: "leftUneven", label: "Left arm uneven", risk: .minor))
            } else if leftOk && !rightOk {
                errors.append(FormError(key: "rightUneven", label: "Right arm uneven", risk: .minor))
            }
        }

        let primaryCue: String
        let leftOk  = leftAngle  >= correctMin && leftAngle  <= correctMax
        let rightOk = rightAngle >= correctMin && rightAngle <= correctMax
        switch phase {
        case .down:
            primaryCue = "Raise Higher"
        case .goingUp:
            primaryCue = avgAngle < correctMin ? "Raise Higher" : "Good Form"
        case .up:
            primaryCue = (leftOk && rightOk) ? "Good Form" : (avgAngle < correctMin ? "Raise Higher" : "Lower Slightly")
        case .goingDown:
            primaryCue = "Controlled Descent"
        }

        let hasDanger = errors.contains { $0.risk == .dangerous }
        let quality: FormQuality
        if hasDanger {
            quality = .poor
        } else if errors.isEmpty && (primaryCue == "Good Form" || primaryCue == "Controlled Descent") {
            quality = .good
        } else if errors.count <= 1 {
            quality = .fair
        } else {
            quality = .poor
        }

        return (primaryCue, errors, quality)
    }
}
