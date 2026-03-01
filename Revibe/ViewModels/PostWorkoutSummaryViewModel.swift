//
//  PostWorkoutSummaryViewModel.swift
//  Revibe
//

import Foundation
import Combine

class PostWorkoutSummaryViewModel: ObservableObject {
    let updatedStreak: Int
    let duration: String
    let kcal: Int
    let streakDots: [Bool]

    init(streak: Int, duration: String, kcal: Int) {
        self.updatedStreak = streak + 1
        self.duration = duration
        self.kcal = kcal
        self.streakDots = (0..<7).map { $0 < streak + 1 }
    }
}
