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
