//
//  PostWorkoutSummaryView.swift
//  Revibe
//

import SwiftUI

struct PostWorkoutSummaryView: View {
    @Binding var path: [Route]
    @StateObject private var viewModel: PostWorkoutSummaryViewModel

    init(payload: SummaryPayload, path: Binding<[Route]>) {
        self._path = path
        self._viewModel = StateObject(
            wrappedValue: PostWorkoutSummaryViewModel(payload: payload)
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // MARK: - Header
                completionHeader
                    .padding(.top, DS.Spacing.lg)

                // MARK: - Form Score Ring
                formScoreRing
                    .padding(.top, DS.Spacing.md)

                // MARK: - Stats Row
                statsRow
                    .padding(.top, DS.Spacing.md)
                    .padding(.horizontal, DS.Spacing.md)

                // MARK: - Coaching Takeaway
                coachingCard
                    .padding(.top, DS.Spacing.sm)
                    .padding(.horizontal, DS.Spacing.md)

                // MARK: - Streak
                streakCard
                    .padding(.top, DS.Spacing.sm)
                    .padding(.horizontal, DS.Spacing.md)

                // MARK: - Schedule Next Workout
                scheduleNextCard
                    .padding(.top, DS.Spacing.sm)
                    .padding(.horizontal, DS.Spacing.md)

                // MARK: - Previous Session Comparison
                if viewModel.previousSession != nil && viewModel.formScoreDelta != nil {
                    comparisonCard
                        .padding(.top, DS.Spacing.sm)
                        .padding(.horizontal, DS.Spacing.md)
                }

                // MARK: - Done
                Button {
                    path.removeAll()
                } label: {
                    Text("Done")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(DS.Colors.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(DS.Colors.accent)
                        .cornerRadius(DS.Radius.button)
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.md)
                .padding(.bottom, DS.Spacing.lg)
            }
        }
        .background(DS.Colors.bgPrimary.ignoresSafeArea())
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(DS.Colors.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Summary")
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundColor(DS.Colors.textPrimary)
            }
        }
        .task {
            async let tip: () = viewModel.fetchCoachingTip()
            async let next: () = viewModel.fetchNextWorkoutDay()
            _ = await (tip, next)
        }
    }

    // MARK: - Completion Header

    private var completionHeader: some View {
        VStack(spacing: DS.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(DS.Colors.accent.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(DS.Colors.accent)
            }

            Text("Session Complete")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundColor(DS.Colors.textPrimary)
                .tracking(-0.5)
                .padding(.top, 2)

            Text(viewModel.movementName)
                .font(.subheadline)
                .foregroundColor(DS.Colors.textMuted)
        }
    }

    // MARK: - Form Score Ring

    private var formScoreRing: some View {
        ZStack {
            Circle()
                .stroke(DS.Colors.border, lineWidth: 6)
                .frame(width: 110, height: 110)

            Circle()
                .trim(from: 0, to: CGFloat(viewModel.formScore) / 100.0)
                .stroke(
                    formScoreColor,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 110, height: 110)
                .animation(.easeOut(duration: 0.8), value: viewModel.formScore)

            VStack(spacing: 2) {
                Text("\(viewModel.formScore)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(DS.Colors.textPrimary)
                    .monospacedDigit()
                Text("Form")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DS.Colors.textMuted)
            }
        }
    }

    private var formScoreColor: Color {
        if viewModel.formScore >= 80 { return DS.Colors.success }
        if viewModel.formScore >= 50 { return Color(red: 255/255, green: 214/255, blue: 10/255) }
        return DS.Colors.error
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(
                value: "\(viewModel.repsCompleted)/\(viewModel.totalReps)",
                label: "Reps"
            )
            statDivider
            statCell(
                value: viewModel.duration,
                label: "Time"
            )
            statDivider
            statCell(
                value: "\(viewModel.kcal)",
                label: "Cal",
                muted: true
            )
        }
        .padding(.vertical, DS.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Colors.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }

    private func statCell(value: String, label: String, muted: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: muted ? 16 : 20, weight: .medium, design: .rounded))
                .foregroundColor(muted ? DS.Colors.textSecondary : DS.Colors.textPrimary)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundColor(DS.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Divider()
            .overlay(DS.Colors.border)
            .frame(height: 36)
    }

    // MARK: - Comparison Card

    private var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("vs. Last Session")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DS.Colors.textPrimary)

            HStack(spacing: 0) {
                if let delta = viewModel.formScoreDelta {
                    deltaCell(label: "Form", delta: delta, suffix: "pt")
                }
                if let delta = viewModel.repsDelta {
                    deltaCell(label: "Reps", delta: delta, suffix: "")
                }
                if let delta = viewModel.durationDelta {
                    deltaCell(label: "Time", delta: delta, suffix: "s")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Colors.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }

    private func deltaCell(label: String, delta: Int, suffix: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Image(systemName: delta > 0 ? "arrow.up.right" : delta < 0 ? "arrow.down.right" : "minus")
                    .font(.system(size: 10, weight: .bold))
                Text("\(abs(delta))\(suffix)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundColor(deltaColor(delta))

            Text(label)
                .font(.caption)
                .foregroundColor(DS.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func deltaColor(_ delta: Int) -> Color {
        if delta > 0 { return DS.Colors.success }
        if delta < 0 { return DS.Colors.error }
        return DS.Colors.textMuted
    }

    // MARK: - Coaching Card

    private var coachingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.Colors.accent)
                Text("Coaching Takeaway")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.Colors.textPrimary)
            }

            if viewModel.isLoadingTip {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(DS.Colors.textMuted)
                        .scaleEffect(0.8)
                    Text("Analyzing your session...")
                        .font(.subheadline)
                        .foregroundColor(DS.Colors.textMuted)
                }
                .padding(.vertical, 4)
            } else if let tip = viewModel.coachingTip {
                Text(tip)
                    .font(.subheadline)
                    .foregroundColor(DS.Colors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Gradients.blueSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Schedule Next Workout Card

    @ViewBuilder
    private var scheduleNextCard: some View {
        if viewModel.isLoadingNextDay {
            scheduleNextLoading
        } else if let day = viewModel.nextDay {
            scheduleNextContent(day: day)
        }
    }

    private var scheduleNextLoading: some View {
        VStack(alignment: .leading, spacing: 10) {
            scheduleNextHeader
            HStack(spacing: 8) {
                ProgressView()
                    .tint(DS.Colors.textMuted)
                    .scaleEffect(0.8)
                Text("Loading your plan...")
                    .font(.subheadline)
                    .foregroundColor(DS.Colors.textMuted)
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Colors.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }

    private func scheduleNextContent(day: PlanDay) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            scheduleNextHeader

            Text(day.name)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(DS.Colors.textPrimary)

            HStack(spacing: 12) {
                Label("\(day.durationMinutes) min", systemImage: "clock")
                Label("\(day.exercises.count) exercises", systemImage: "figure.strengthtraining.traditional")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(DS.Colors.textMuted)

            Button {
                viewModel.scheduleNextWorkout()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.didScheduleNext ? "checkmark.circle.fill" : "bell.badge")
                        .font(.system(size: 13, weight: .medium))
                    Text(viewModel.didScheduleNext ? "Scheduled for tomorrow 9 AM" : "Remind me tomorrow")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(viewModel.didScheduleNext ? DS.Colors.success : DS.Colors.textOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(viewModel.didScheduleNext ? DS.Colors.success.opacity(0.15) : DS.Colors.blue)
                .cornerRadius(DS.Radius.button)
            }
            .disabled(viewModel.didScheduleNext)
            .animation(.easeInOut(duration: 0.25), value: viewModel.didScheduleNext)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Colors.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }

    private var scheduleNextHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DS.Colors.blue)
            Text("Up Next")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DS.Colors.textPrimary)
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text("Your \(viewModel.updatedStreak)-day streak")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DS.Colors.textPrimary)

            HStack(spacing: 6) {
                ForEach(Array(viewModel.streakDots.enumerated()), id: \.offset) { _, filled in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(filled ? DS.Colors.accent : DS.Colors.border)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Colors.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        PostWorkoutSummaryView(
            payload: SummaryPayload(
                movementName: "Lateral Raise",
                streak: 3,
                duration: "30:02",
                kcal: 100,
                repsCompleted: 24,
                totalReps: 30,
                formScore: 78
            ),
            path: .constant([])
        )
    }
}
