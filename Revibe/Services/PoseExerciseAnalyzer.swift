//
//  PoseExerciseAnalyzer.swift
//  Revibe
//

import Foundation
import MediaPipeTasksVision

struct PoseExerciseFrameResult {
    let exercise: PoseTestExercise
    let phase: String
    let repCount: Int?
    let holdSeconds: Double?
    let feedback: [String]
    let landmarks: [NormalizedLandmark]
}

final class PoseExerciseAnalyzer {
    private enum LM {
        static let leftShoulder = 11
        static let rightShoulder = 12
        static let leftElbow = 13
        static let rightElbow = 14
        static let leftWrist = 15
        static let rightWrist = 16
        static let leftHip = 23
        static let rightHip = 24
        static let leftKnee = 25
        static let rightKnee = 26
        static let leftAnkle = 27
        static let rightAnkle = 28
        static let nose = 0
    }

    let exercise: PoseTestExercise
    private var phase: String = "ready"
    private var repCount = 0
    private var holdSeconds = 0.0
    private var lastTimestamp: TimeInterval?
    private var goodFormSince: TimeInterval?
    private static let plankEntryDelay: TimeInterval = 0.5

    init(exercise: PoseTestExercise) {
        self.exercise = exercise
    }

    func reset() {
        phase = "ready"
        repCount = 0
        holdSeconds = 0
        lastTimestamp = nil
        goodFormSince = nil
    }

    func analyze(landmarks: [NormalizedLandmark], timestamp: TimeInterval) -> PoseExerciseFrameResult? {
        guard landmarks.count > LM.rightAnkle else { return nil }
        let dt = max(0, timestamp - (lastTimestamp ?? timestamp))
        lastTimestamp = timestamp

        switch exercise {
        case .squat:
            return squatResult(landmarks: landmarks)
        case .lunge:
            return lungeResult(landmarks: landmarks)
        case .pushUp:
            return pushUpResult(landmarks: landmarks)
        case .jumpingJack:
            return jumpingJackResult(landmarks: landmarks)
        case .plank:
            return plankResult(landmarks: landmarks, dt: dt, timestamp: timestamp)
        }
    }

    private func squatResult(landmarks: [NormalizedLandmark]) -> PoseExerciseFrameResult {
        let leftKnee = angle(landmarks[LM.leftHip], landmarks[LM.leftKnee], landmarks[LM.leftAnkle])
        let rightKnee = angle(landmarks[LM.rightHip], landmarks[LM.rightKnee], landmarks[LM.rightAnkle])
        let knee = (leftKnee + rightKnee) / 2
        var feedback: [String] = []

        let shoulderMidY = (Double(landmarks[LM.leftShoulder].y) + Double(landmarks[LM.rightShoulder].y)) / 2
        let hipMidY = (Double(landmarks[LM.leftHip].y) + Double(landmarks[LM.rightHip].y)) / 2
        if hipMidY - shoulderMidY < 0.08 {
            feedback.append("Sit hips back")
        }

        if phase == "ready" || phase == "up" {
            if knee < 95 {
                phase = "down"
            }
        } else if phase == "down", knee > 155 {
            phase = "up"
            repCount += 1
        } else if phase == "down", knee > 110 {
            feedback.append("Go lower")
        }

        return PoseExerciseFrameResult(
            exercise: .squat,
            phase: phase,
            repCount: repCount,
            holdSeconds: nil,
            feedback: feedback,
            landmarks: landmarks
        )
    }

    private func lungeResult(landmarks: [NormalizedLandmark]) -> PoseExerciseFrameResult {
        let leftKnee = angle(landmarks[LM.leftHip], landmarks[LM.leftKnee], landmarks[LM.leftAnkle])
        let rightKnee = angle(landmarks[LM.rightHip], landmarks[LM.rightKnee], landmarks[LM.rightAnkle])
        let frontKnee = min(leftKnee, rightKnee)
        var feedback: [String] = []

        if phase == "ready" || phase == "standing" {
            phase = "standing"
            if frontKnee < 100 {
                phase = "lowered"
            }
        } else if phase == "lowered", frontKnee > 155 {
            phase = "standing"
            repCount += 1
        } else if phase == "lowered", frontKnee > 115 {
            feedback.append("Drop deeper")
        }

        return PoseExerciseFrameResult(
            exercise: .lunge,
            phase: phase,
            repCount: repCount,
            holdSeconds: nil,
            feedback: feedback,
            landmarks: landmarks
        )
    }

    private func pushUpResult(landmarks: [NormalizedLandmark]) -> PoseExerciseFrameResult {
        let leftElbow = angle(landmarks[LM.leftShoulder], landmarks[LM.leftElbow], landmarks[LM.leftWrist])
        let rightElbow = angle(landmarks[LM.rightShoulder], landmarks[LM.rightElbow], landmarks[LM.rightWrist])
        let elbow = (leftElbow + rightElbow) / 2
        var feedback: [String] = []

        let shoulderMidY = (Double(landmarks[LM.leftShoulder].y) + Double(landmarks[LM.rightShoulder].y)) / 2
        let hipMidY = (Double(landmarks[LM.leftHip].y) + Double(landmarks[LM.rightHip].y)) / 2
        if hipMidY - shoulderMidY > 0.25 { feedback.append("Hips too low") }
        if hipMidY - shoulderMidY < 0.03 { feedback.append("Hips too high") }

        if phase == "ready" || phase == "top" {
            phase = "top"
            if elbow < 95 {
                phase = "bottom"
            }
        } else if phase == "bottom", elbow > 155 {
            phase = "top"
            repCount += 1
        } else if phase == "bottom", elbow > 110 {
            feedback.append("Lower chest more")
        }

        return PoseExerciseFrameResult(
            exercise: .pushUp,
            phase: phase,
            repCount: repCount,
            holdSeconds: nil,
            feedback: feedback,
            landmarks: landmarks
        )
    }

    private func jumpingJackResult(landmarks: [NormalizedLandmark]) -> PoseExerciseFrameResult {
        let shoulderWidth = distance(landmarks[LM.leftShoulder], landmarks[LM.rightShoulder])
        let hipWidth = distance(landmarks[LM.leftHip], landmarks[LM.rightHip])
        let armSpread = distance(landmarks[LM.leftWrist], landmarks[LM.rightWrist]) / max(shoulderWidth, 0.001)
        let legSpread = distance(landmarks[LM.leftAnkle], landmarks[LM.rightAnkle]) / max(hipWidth, 0.001)
        var feedback: [String] = []

        let isOpen = armSpread > 2.1 && legSpread > 1.7
        let isClosed = armSpread < 1.2 && legSpread < 1.05

        if phase == "ready" || phase == "closed" {
            phase = "closed"
            if isOpen { phase = "open" }
        } else if phase == "open", isClosed {
            phase = "closed"
            repCount += 1
        }

        if !isOpen && phase == "closed" {
            if armSpread < 2.1 { feedback.append("Arms higher/wider") }
            if legSpread < 1.7 { feedback.append("Jump feet wider") }
        }

        return PoseExerciseFrameResult(
            exercise: .jumpingJack,
            phase: phase,
            repCount: repCount,
            holdSeconds: nil,
            feedback: feedback,
            landmarks: landmarks
        )
    }

    private func plankResult(landmarks: [NormalizedLandmark], dt: TimeInterval, timestamp: TimeInterval) -> PoseExerciseFrameResult {
        let shoulderMid = midpoint(landmarks[LM.leftShoulder], landmarks[LM.rightShoulder])
        let hipMid = midpoint(landmarks[LM.leftHip], landmarks[LM.rightHip])
        let ankleMid = midpoint(landmarks[LM.leftAnkle], landmarks[LM.rightAnkle])
        let bodyLine = abs(segmentAngle(shoulderMid, hipMid) - segmentAngle(shoulderMid, ankleMid))
        var feedback: [String] = []

        let noseY = Double(landmarks[LM.nose].y)
        if noseY > shoulderMid.y + 0.12 {
            feedback.append("Head dropping")
        }

        let isGoodForm = bodyLine < 18 && feedback.isEmpty

        if isGoodForm {
            if goodFormSince == nil {
                goodFormSince = timestamp
            }

            let heldFor = timestamp - (goodFormSince ?? timestamp)

            if phase == "ready" || phase == "entering" {
                if heldFor >= Self.plankEntryDelay {
                    phase = "hold"
                    holdSeconds += min(dt, 0.2)
                } else {
                    phase = "entering"
                }
            } else if phase == "hold" {
                holdSeconds += min(dt, 0.2)
            } else if phase == "badForm" {
                phase = "hold"
            }
        } else {
            goodFormSince = nil

            if phase == "hold" {
                phase = "badForm"
            } else if phase != "badForm" {
                phase = "ready"
                feedback.append("Get into position")
            }

            if bodyLine >= 18 {
                if hipMid.y > shoulderMid.y + 0.12 {
                    feedback.append("Hips too low")
                } else {
                    feedback.append("Hips too high")
                }
            }
        }

        return PoseExerciseFrameResult(
            exercise: .plank,
            phase: phase,
            repCount: nil,
            holdSeconds: holdSeconds,
            feedback: feedback,
            landmarks: landmarks
        )
    }

    private func angle(_ a: NormalizedLandmark, _ b: NormalizedLandmark, _ c: NormalizedLandmark) -> Double {
        let baX = Double(a.x - b.x), baY = Double(a.y - b.y)
        let bcX = Double(c.x - b.x), bcY = Double(c.y - b.y)
        let dot = baX * bcX + baY * bcY
        let magBA = sqrt(baX * baX + baY * baY)
        let magBC = sqrt(bcX * bcX + bcY * bcY)
        guard magBA > 0, magBC > 0 else { return 180 }
        let cosA = max(-1, min(1, dot / (magBA * magBC)))
        return acos(cosA) * 180 / .pi
    }

    private func distance(_ a: NormalizedLandmark, _ b: NormalizedLandmark) -> Double {
        let dx = Double(a.x - b.x), dy = Double(a.y - b.y)
        return sqrt(dx * dx + dy * dy)
    }

    private func midpoint(_ a: NormalizedLandmark, _ b: NormalizedLandmark) -> (x: Double, y: Double) {
        ((Double(a.x) + Double(b.x)) / 2, (Double(a.y) + Double(b.y)) / 2)
    }

    private func segmentAngle(_ a: (x: Double, y: Double), _ b: (x: Double, y: Double)) -> Double {
        atan2(b.y - a.y, b.x - a.x) * 180 / .pi
    }
}
