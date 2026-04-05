//
//  UserModels.swift
//  Revibe
//

import Foundation

struct Profile: Codable {
    let id: UUID
    let displayName: String
    let timezone: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case timezone
    }
}

struct ProfileDisplayNameUpdate: Encodable {
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

struct OnboardingPreferencesUpdate: Encodable {
    let goal: String
    let daysPerWeek: String
    let sessionLength: String
    let equipment: String
    let injuryArea: String
    let injuryNote: String?

    enum CodingKeys: String, CodingKey {
        case goal
        case daysPerWeek = "days_per_week"
        case sessionLength = "session_length"
        case equipment
        case injuryArea = "injury_area"
        case injuryNote = "injury_note"
    }
}

struct UserStreak: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let lastActiveDate: String?

    enum CodingKeys: String, CodingKey {
        case currentStreak  = "current_streak"
        case longestStreak  = "longest_streak"
        case lastActiveDate = "last_active_date"
    }
}

struct WorkoutCompletion: Encodable {
    let userId: String
    let completedAt: String
    let timezone: String

    enum CodingKeys: String, CodingKey {
        case userId     = "user_id"
        case completedAt = "completed_at"
        case timezone
    }
}

// MARK: - Workout Plan (from Edge Function / OpenAI)

struct PlanExercise: Codable, Identifiable {
    var id: String { name }
    let name: String
    let sets: Int
    let reps: Int
    let rest: String
}

struct PlanDay: Codable, Identifiable {
    var id: Int { dayNumber }
    let dayNumber: Int
    let name: String
    let durationMinutes: Int
    let exercises: [PlanExercise]
}

struct WorkoutPlan: Codable {
    let summary: String
    let description: String
    let days: [PlanDay]
}

struct UserPlanRow: Codable {
    let planJson: WorkoutPlan

    enum CodingKeys: String, CodingKey {
        case planJson = "plan_json"
    }
}

// MARK: - Session History (local persistence for session-over-session comparison)

struct SessionRecord: Codable {
    let movementName: String
    let formScore: Int
    let repsCompleted: Int
    let totalReps: Int
    let durationSeconds: Int
    let date: Date

    private static let key = "lastSessionRecord"

    static func loadPrevious() -> SessionRecord? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SessionRecord.self, from: data)
    }

    func persist() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: SessionRecord.key)
        }
    }
}

struct OnboardingResponse: Codable {
    let userId: String
    let goal: String
    let daysPerWeek: String
    let sessionLength: String
    let equipment: String
    let injuryArea: String
    let injuryNote: String?

    enum CodingKeys: String, CodingKey {
        case userId        = "user_id"
        case goal
        case daysPerWeek   = "days_per_week"
        case sessionLength = "session_length"
        case equipment
        case injuryArea    = "injury_area"
        case injuryNote    = "injury_note"
    }
}
