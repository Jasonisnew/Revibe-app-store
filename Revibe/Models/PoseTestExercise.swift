//
//  PoseTestExercise.swift
//  Revibe
//

import Foundation

enum PoseTestExercise: String, CaseIterable, Hashable, Identifiable {
    case squat
    case lunge
    case pushUp
    case jumpingJack
    case plank

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .squat: return "Squat"
        case .lunge: return "Lunge"
        case .pushUp: return "Push-up"
        case .jumpingJack: return "Jumping Jack"
        case .plank: return "Plank"
        }
    }

    var systemIcon: String {
        switch self {
        case .squat: return "figure.strengthtraining.functional"
        case .lunge: return "figure.walk.motion"
        case .pushUp: return "figure.core.training"
        case .jumpingJack: return "figure.jumprope"
        case .plank: return "figure.core.training"
        }
    }

    // MARK: - Camera position requirement per exercise

    var cameraPosition: String {
        switch self {
        case .squat:
            return "Front or 45° angle · Place phone 6-8 ft away at hip height · Full body must be visible from head to feet"
        case .lunge:
            return "Side view preferred · Place phone 6-8 ft away at hip height · Both legs must stay in frame throughout the movement"
        case .pushUp:
            return "Side view required · Place phone on the floor 5-6 ft away · Full body from head to toes must be visible"
        case .jumpingJack:
            return "Front view · Place phone 6-8 ft away at chest height · Arms and legs must be visible at full extension"
        case .plank:
            return "Side view required · Place phone on the floor 5-6 ft away · Shoulders, hips, and ankles must all be visible"
        }
    }

    // MARK: - Performance standards

    var standardDescription: String {
        switch self {
        case .squat:
            return "Knee angle below 90° at bottom · Torso stays upright · Knees track over toes without drifting inward"
        case .lunge:
            return "Front knee bends to ~90° · Back knee drops toward floor · Torso remains upright and stable"
        case .pushUp:
            return "Elbows bend past 90° at bottom · Body stays in a straight line · No hip sag or pike"
        case .jumpingJack:
            return "Arms fully overhead at top · Feet wider than hips at top · Controlled rhythm, full range of motion"
        case .plank:
            return "Body forms a straight line from head to heels · No hip sag or pike · Head neutral, not dropping"
        }
    }

    var goalLabel: String {
        switch self {
        case .squat: return "Goal: 10 reps"
        case .lunge: return "Goal: 10 reps (5 each side)"
        case .pushUp: return "Goal: 10 reps"
        case .jumpingJack: return "Goal: 20 reps"
        case .plank: return "Goal: 30 seconds"
        }
    }

    var goalValue: Int {
        switch self {
        case .squat: return 10
        case .lunge: return 10
        case .pushUp: return 10
        case .jumpingJack: return 20
        case .plank: return 30
        }
    }
}
