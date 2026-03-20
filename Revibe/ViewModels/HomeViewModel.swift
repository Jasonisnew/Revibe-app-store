//
//  HomeViewModel.swift
//  Revibe
//

import Foundation
import Supabase

struct Movement: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let isAvailable: Bool
    let iconName: String
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var streak: Int = 0
    @Published var greeting: String = "Hello! 👋"
    @Published var subtitle: String = "You ready for today's session"

    let movements: [Movement] = [
        Movement(name: "Lateral Raise", isAvailable: true, iconName: "figure.arms.open"),
        Movement(name: "Shoulder External Rotation", isAvailable: false, iconName: "figure.cooldown"),
        Movement(name: "Squat Pattern", isAvailable: false, iconName: "figure.strengthtraining.traditional")
    ]

    func loadUserData() async {
        do {
            let userId = try await supabase.auth.session.user.id.uuidString

            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            let userStreak: UserStreak = try await supabase
                .from("streaks")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value

            greeting = "Hello \(profile.displayName)! 👋"
            streak = userStreak.currentStreak
        } catch {
            greeting = "Hello! 👋"
            streak = 0
        }
    }
}
