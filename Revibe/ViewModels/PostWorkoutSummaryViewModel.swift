//
//  PostWorkoutSummaryViewModel.swift
//  Revibe
//

import Foundation
import Combine
import Supabase
@preconcurrency import UserNotifications

class PostWorkoutSummaryViewModel: ObservableObject {
    let updatedStreak: Int
    let duration: String
    let kcal: Int
    let formScore: Int
    let repsCompleted: Int
    let totalReps: Int
    let movementName: String
    let streakDots: [Bool]
    let formInsights: [String]

    @Published var coachingTip: String? = nil
    @Published var isLoadingTip: Bool = true
    @Published var nextDay: PlanDay? = nil
    @Published var isLoadingNextDay: Bool = true
    @Published var didScheduleNext: Bool = false

    let previousSession: SessionRecord?

    var formScoreDelta: Int? {
        guard let prev = previousSession, prev.movementName == movementName else { return nil }
        return formScore - prev.formScore
    }

    var repsDelta: Int? {
        guard let prev = previousSession, prev.movementName == movementName else { return nil }
        return repsCompleted - prev.repsCompleted
    }

    var durationDelta: Int? {
        guard let prev = previousSession, prev.movementName == movementName else { return nil }
        let currentSeconds = parseDuration(duration)
        return currentSeconds - prev.durationSeconds
    }

    init(payload: SummaryPayload) {
        self.movementName = payload.movementName
        self.updatedStreak = payload.streak + 1
        self.duration = payload.duration
        self.kcal = payload.kcal
        self.formScore = payload.formScore
        self.repsCompleted = payload.repsCompleted
        self.totalReps = payload.totalReps
        self.streakDots = (0..<7).map { $0 < payload.streak + 1 }
        self.formInsights = payload.formInsights

        self.previousSession = SessionRecord.loadPrevious()

        let record = SessionRecord(
            movementName: payload.movementName,
            formScore: payload.formScore,
            repsCompleted: payload.repsCompleted,
            totalReps: payload.totalReps,
            durationSeconds: Self.parseDurationStatic(payload.duration),
            date: Date()
        )
        record.persist()
    }

    func fetchCoachingTip() async {
        do {
            let body: [String: Any] = [
                "movementName": movementName,
                "formScore": formScore,
                "repsCompleted": repsCompleted,
                "totalReps": totalReps,
                "duration": duration
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: body)

            struct TipResponse: Decodable { let tip: String }
            let decoded: TipResponse = try await supabase.functions.invoke(
                "generate-coaching-tip",
                options: FunctionInvokeOptions(body: jsonData)
            )

            await MainActor.run {
                self.coachingTip = decoded.tip
                self.isLoadingTip = false
            }
        } catch {
            await MainActor.run {
                self.coachingTip = formScore >= 80
                    ? "Great session! Keep focusing on controlled movements to maintain your form."
                    : "Try slowing down your reps next time — quality over quantity builds real strength."
                self.isLoadingTip = false
            }
        }
    }

    func fetchNextWorkoutDay() async {
        do {
            let userId = try await supabase.auth.session.user.id.uuidString

            let planRow: UserPlanRow = try await supabase
                .from("user_plans")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(1)
                .single()
                .execute()
                .value

            let days = planRow.planJson.days
            let todayIndex = (Calendar.current.component(.weekday, from: Date()) - 1) % max(days.count, 1)
            let nextIndex = (todayIndex + 1) % days.count
            let next = days.indices.contains(nextIndex) ? days[nextIndex] : days.first

            await MainActor.run {
                self.nextDay = next
                self.isLoadingNextDay = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingNextDay = false
            }
        }
    }

    @MainActor
    func scheduleNextWorkout() {
        guard let day = nextDay else { return }
        Task {
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) == true else { return }

            let content = UNMutableNotificationContent()
            content.title = "Time to train"
            content.body = "\(day.name) — \(day.durationMinutes) min, \(day.exercises.count) exercises"
            content.sound = .default

            var tomorrow = Calendar.current.dateComponents([.year, .month, .day], from: Date().addingTimeInterval(86400))
            tomorrow.hour = 9
            tomorrow.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: tomorrow, repeats: false)
            let request = UNNotificationRequest(identifier: "nextWorkout", content: content, trigger: trigger)

            try? await center.add(request)
            self.didScheduleNext = true
        }
    }

    private func parseDuration(_ str: String) -> Int {
        Self.parseDurationStatic(str)
    }

    private static func parseDurationStatic(_ str: String) -> Int {
        let parts = str.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }
}
