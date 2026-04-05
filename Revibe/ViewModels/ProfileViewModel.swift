//
//  ProfileViewModel.swift
//  Revibe
//

import Foundation
import Combine
import Supabase

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var goal: String = ""
    @Published var daysPerWeek: String = ""
    @Published var sessionLength: String = ""
    @Published var equipment: String = ""
    @Published var streak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var planSummary: String = ""
    @Published var planDayCount: Int = 0
    @Published var completedThisWeek: Int = 0
    @Published var isLoaded: Bool = false
    @Published var injuryArea: String = ""
    @Published var injuryNote: String = ""

    func loadProfile() async {
        do {
            let userId = try await supabase.auth.session.user.id.uuidString

            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            displayName = profile.displayName

            let userStreak: UserStreak = try await supabase
                .from("streaks")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value
            streak = userStreak.currentStreak
            longestStreak = userStreak.longestStreak

            let onboarding: OnboardingResponse = try await supabase
                .from("onboarding_responses")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value
            goal = OnboardingOptions.resolveGoal(onboarding.goal)
            daysPerWeek = OnboardingOptions.resolveDaysPerWeek(onboarding.daysPerWeek)
            sessionLength = OnboardingOptions.resolveSessionLength(onboarding.sessionLength)
            equipment = OnboardingOptions.resolveEquipment(onboarding.equipment)
            injuryArea = OnboardingOptions.resolveInjuryArea(onboarding.injuryArea)
            injuryNote = onboarding.injuryNote ?? ""

            let planRow: UserPlanRow = try await supabase
                .from("user_plans")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(1)
                .single()
                .execute()
                .value
            planSummary = planRow.planJson.summary
            planDayCount = planRow.planJson.days.count

            isLoaded = true
        } catch {
            isLoaded = true
        }
    }

    /// Saves profile name and training preferences. Returns `nil` on success, or an error message.
    func saveSettings(
        displayName: String,
        goal: String,
        daysPerWeek: String,
        sessionLength: String,
        equipment: String,
        injuryArea: String,
        injuryNote: String
    ) async -> String? {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return "Please enter a display name." }

        do {
            let userId = try await supabase.auth.session.user.id.uuidString

            try await supabase
                .from("profiles")
                .update(ProfileDisplayNameUpdate(displayName: trimmedName))
                .eq("id", value: userId)
                .execute()

            let note = injuryNote.trimmingCharacters(in: .whitespacesAndNewlines)
            try await supabase
                .from("onboarding_responses")
                .update(
                    OnboardingPreferencesUpdate(
                        goal: goal,
                        daysPerWeek: daysPerWeek,
                        sessionLength: sessionLength,
                        equipment: equipment,
                        injuryArea: injuryArea,
                        injuryNote: note.isEmpty ? nil : note
                    )
                )
                .eq("user_id", value: userId)
                .execute()

            self.displayName = trimmedName
            self.goal = goal
            self.daysPerWeek = daysPerWeek
            self.sessionLength = sessionLength
            self.equipment = equipment
            self.injuryArea = injuryArea
            self.injuryNote = note

            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
