//
//  HomeViewModel.swift
//  Revibe
//

import Foundation
import Combine
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
    @Published var greeting: String = "Hello 👋"
    @Published var subtitle: String = "Ready for today's workout?"
    @Published var plan: WorkoutPlan?
    @Published var todayDay: PlanDay?
    @Published var todayDayIndex: Int = 0
    @Published var completedThisWeek: Int = 0

    let movements: [Movement] = [
        Movement(name: "Lateral Raise", isAvailable: true, iconName: "figure.arms.open"),
        Movement(name: "Shoulder External Rotation", isAvailable: false, iconName: "figure.cooldown"),
        Movement(name: "Squat Pattern", isAvailable: false, iconName: "figure.strengthtraining.traditional")
    ]

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func firstName(from displayName: String) -> String {
        displayName.components(separatedBy: " ").first ?? displayName
    }

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

            let name = firstName(from: profile.displayName)
            greeting = "\(timeOfDayGreeting), \(name) 👋"
            streak = userStreak.currentStreak

            let planRow: UserPlanRow = try await supabase
                .from("user_plans")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(1)
                .single()
                .execute()
                .value

            plan = planRow.planJson

            let dayIndex = (Calendar.current.component(.weekday, from: Date()) - 1) % max(planRow.planJson.days.count, 1)
            todayDayIndex = dayIndex
            todayDay = planRow.planJson.days.indices.contains(dayIndex) ? planRow.planJson.days[dayIndex] : planRow.planJson.days.first
        } catch {
            if greeting == "Hello 👋" {
                greeting = "\(timeOfDayGreeting) 👋"
            }
        }
    }
}
