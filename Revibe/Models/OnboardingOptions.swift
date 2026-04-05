//
//  OnboardingOptions.swift
//  Revibe
//
//  Single source of truth for first-run questionnaire options.
//  OnboardingView and SettingsView both use these arrays and resolvers.
//

import Foundation

enum OnboardingOptions {

    // MARK: - Options (same order as OnboardingView)

    static let goals = [
        "Stay fit and maintain my physique",
        "Build muscle",
        "Lose fat",
        "Move better and feel less stiff"
    ]

    static let daysPerWeek = [
        "2 days",
        "3 days",
        "4 days",
        "5+ days"
    ]

    static let sessionLengths = [
        "10–15 min",
        "20–30 min",
        "30–45 min",
        "45+ min"
    ]

    static let equipment = [
        "Full gym",
        "Dumbbells only",
        "Home, no equipment",
        "Bands / light equipment"
    ]

    static let injuryAreas = [
        "No pain or injuries",
        "Shoulder",
        "Back",
        "Knee",
        "Other"
    ]

    // MARK: - Resolve stored DB values → canonical option (for Settings / display)

    static func resolveGoal(_ stored: String) -> String {
        matchCanonical(stored, options: goals)
    }

    static func resolveDaysPerWeek(_ stored: String) -> String {
        matchCanonical(stored, options: daysPerWeek)
    }

    static func resolveSessionLength(_ stored: String) -> String {
        matchCanonical(stored, options: sessionLengths)
    }

    static func resolveEquipment(_ stored: String) -> String {
        matchCanonical(stored, options: equipment)
    }

    static func resolveInjuryArea(_ stored: String) -> String {
        matchCanonical(stored, options: injuryAreas)
    }

    private static func matchCanonical(_ raw: String, options: [String]) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if options.contains(trimmed) { return trimmed }
        if let exact = options.first(where: { $0.lowercased() == trimmed.lowercased() }) {
            return exact
        }
        // Legacy slug-style values from older builds
        let legacy: [String: String] = [
            "build_muscle": "Build muscle",
            "lose_fat": "Lose fat",
            "stay_active": "Stay fit and maintain my physique",
            "stay_fit": "Stay fit and maintain my physique",
            "rehab": "Move better and feel less stiff",
            "full_gym": "Full gym",
            "dumbbells": "Dumbbells only",
            "bodyweight": "Home, no equipment",
            "bands": "Bands / light equipment"
        ]
        if let mapped = legacy[trimmed.lowercased()], options.contains(mapped) {
            return mapped
        }
        return trimmed.isEmpty ? "" : trimmed
    }
}
