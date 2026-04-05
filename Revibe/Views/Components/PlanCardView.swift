//
//  PlanCardView.swift
//  Revibe
//

import SwiftUI

struct TodayWorkoutCard: View {
    let day: PlanDay
    let planSummary: String
    let onStart: () -> Void
    var onPreview: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TODAY FOR YOU")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(DS.Colors.accent)
                .tracking(1.2)

            Text("\(day.name) Focus")
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundColor(DS.Colors.textPrimary)

            Text("\(day.durationMinutes) min · \(day.exercises.count) exercises · Full gym")
                .font(.caption)
                .foregroundColor(DS.Colors.textMuted)

            Text(condensedSummary)
                .font(.caption)
                .foregroundColor(DS.Colors.textSecondary)
                .lineLimit(2)

            Divider().overlay(DS.Colors.border)

            VStack(spacing: 0) {
                ForEach(Array(day.exercises.enumerated()), id: \.offset) { index, exercise in
                    HStack {
                        Text(shortenExerciseName(exercise.name))
                            .font(.caption)
                            .foregroundColor(DS.Colors.textPrimary)

                        Spacer()

                        Text("\(exercise.sets) × \(exercise.reps)")
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(DS.Colors.textMuted)
                    }
                    .padding(.vertical, 6)

                    if index < day.exercises.count - 1 {
                        Divider().overlay(DS.Colors.border)
                    }
                }
            }

            Divider().overlay(DS.Colors.border)

            Button(action: onStart) {
                Text("Start Today's Workout")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(DS.Colors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DS.Colors.accent)
                    .cornerRadius(DS.Radius.button)
            }

            if let onPreview {
                Button(action: onPreview) {
                    Text("Preview workout")
                        .font(.caption.weight(.medium))
                        .foregroundColor(DS.Colors.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Gradients.blueSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }

    /// Strips boilerplate phrasing and returns a short, punchy coaching line.
    private var condensedSummary: String {
        var s = planSummary
        let removals = [
            "This plan focuses on ",
            "This plan is designed for ",
            ", tailored for a full gym setup.",
            ", tailored for a full gym setup",
            ", designed for a full gym setup.",
            ", designed for a full gym setup"
        ]
        for phrase in removals { s = s.replacingOccurrences(of: phrase, with: "") }
        let capitalized = s.prefix(1).uppercased() + s.dropFirst()
        return capitalized.hasSuffix(".") ? capitalized : capitalized + "."
    }

    private func shortenExerciseName(_ name: String) -> String {
        var result = name
        if let range = result.range(of: #"\s*\(.*\)"#, options: .regularExpression) {
            result.removeSubrange(range)
        }
        return result
    }
}

// MARK: - Streak Badge (top-right of header)

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("🔥")
                .font(.system(size: 20))
            Text("\(streak)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(DS.Colors.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(DS.Colors.bgTertiary)
        )
        .overlay(Capsule().stroke(DS.Colors.border, lineWidth: 1))
    }
}

// MARK: - Weekly Progress Bar

struct WeeklyProgressBar: View {
    let completedThisWeek: Int
    let totalWorkouts: Int

    private var progress: Double {
        guard totalWorkouts > 0 else { return 0 }
        return Double(completedThisWeek) / Double(totalWorkouts)
    }

    private var percentText: String {
        "\(Int(progress * 100))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(completedThisWeek) of \(totalWorkouts) this week")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DS.Colors.textPrimary)
                Spacer()
                Text(percentText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.Colors.textMuted)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DS.Colors.border.opacity(0.5))
                        .frame(height: 6)

                    Capsule()
                        .fill(DS.Gradients.progress)
                        .frame(width: max(geo.size.width * progress, progress > 0 ? 6 : 0), height: 6)
                        .animation(.easeOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Week Overview

enum DayStatus {
    case completed, today, upcoming
}

struct WeekOverviewView: View {
    let plan: WorkoutPlan
    let todayDayIndex: Int
    let horizontalInset: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Weekly Plan")
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundColor(DS.Colors.textPrimary)

            Text("\(plan.days.count) workouts built around your goal and recovery")
                .font(.subheadline)
                .foregroundColor(DS.Colors.textMuted)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(plan.days.enumerated()), id: \.offset) { index, day in
                            let status: DayStatus = index < todayDayIndex ? .completed
                                : index == todayDayIndex ? .today
                                : .upcoming

                            WeekDayCard(day: day, status: status)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, horizontalInset)
                    .padding(.vertical, 2)
                }
                .padding(.horizontal, -horizontalInset)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(todayDayIndex, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}

struct WeekDayCard: View {
    let day: PlanDay
    let status: DayStatus

    private static let cardColors: [Color] = DS.Colors.cardPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StatusChip(status: status)

            Text(day.name)
                .font(.system(size: 15, weight: status == .today ? .semibold : .medium, design: .serif))
                .foregroundColor(DS.Colors.textPrimary)
                .lineLimit(1)

            HStack(spacing: 4) {
                Text("\(day.durationMinutes) min")
                Text("·")
                Text("\(day.exercises.count) exercises")
            }
            .font(.caption)
            .foregroundColor(DS.Colors.textMuted)

            Divider().overlay(DS.Colors.border)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(day.exercises.prefix(3)) { exercise in
                    Text(shortenName(exercise.name))
                        .font(.caption2)
                        .foregroundColor(DS.Colors.textSecondary)
                        .lineLimit(1)
                }
                if day.exercises.count > 3 {
                    Text("+\(day.exercises.count - 3) more")
                        .font(.caption2)
                        .foregroundColor(DS.Colors.textMuted)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(width: 160)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    private var cardBackground: LinearGradient {
        switch status {
        case .today:
            return LinearGradient(
                colors: [DS.Colors.blueDeep, DS.Colors.blue.opacity(0.35)],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
        case .completed:
            return LinearGradient(
                colors: [DS.Colors.success.opacity(0.08), DS.Colors.success.opacity(0.04)],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
        case .upcoming:
            return LinearGradient(
                colors: [DS.Colors.bgSecondary, DS.Colors.bgSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private var cardBorder: Color {
        switch status {
        case .today: return DS.Colors.blue.opacity(0.4)
        case .completed: return DS.Colors.success.opacity(0.2)
        case .upcoming: return DS.Colors.border
        }
    }

    private func shortenName(_ name: String) -> String {
        var result = name
        if let range = result.range(of: #"\s*\(.*\)"#, options: .regularExpression) {
            result.removeSubrange(range)
        }
        return result
    }
}

struct StatusChip: View {
    let status: DayStatus

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(backgroundColor)
            )
    }

    private var label: String {
        switch status {
        case .completed: return "Done"
        case .today: return "Today"
        case .upcoming: return "Upcoming"
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .completed: return DS.Colors.success
        case .today: return DS.Colors.blue
        case .upcoming: return DS.Colors.textMuted
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .completed: return DS.Colors.success.opacity(0.15)
        case .today: return DS.Colors.blue.opacity(0.2)
        case .upcoming: return DS.Colors.bgTertiary
        }
    }
}
