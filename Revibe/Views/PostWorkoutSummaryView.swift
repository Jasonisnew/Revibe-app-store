//
//  PostWorkoutSummaryView.swift
//  Revibe
//

import SwiftUI

struct PostWorkoutSummaryView: View {
    @Binding var path: [Route]
    @StateObject private var viewModel: PostWorkoutSummaryViewModel

    init(streak: Int, duration: String, kcal: Int, path: Binding<[Route]>) {
        self._path = path
        self._viewModel = StateObject(
            wrappedValue: PostWorkoutSummaryViewModel(streak: streak, duration: duration, kcal: kcal)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Completion header
            VStack(spacing: DS.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(DS.Colors.bgSecondary)
                        .frame(width: 88, height: 88)
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(DS.Colors.textPrimary)
                }

                Text("Session Complete")
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundColor(DS.Colors.textPrimary)
                    .tracking(-0.5)
                    .padding(.top, 4)

                Text("You crushed it today!")
                    .font(.subheadline)
                    .foregroundColor(DS.Colors.textMuted)
            }

            Spacer()
                .frame(height: DS.Spacing.lg)

            // Streak card
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Your \(viewModel.updatedStreak)-day streak")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DS.Colors.textPrimary)

                HStack(spacing: 8) {
                    ForEach(Array(viewModel.streakDots.enumerated()), id: \.offset) { _, filled in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(filled ? DS.Colors.accent : DS.Colors.border)
                            .frame(width: 28, height: 28)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(DS.Colors.cardSand)
            )
            .padding(.horizontal, DS.Spacing.md)

            Spacer()
                .frame(height: DS.Spacing.sm)

            // Stats row
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Text(viewModel.duration)
                        .font(.title2.weight(.medium))
                        .foregroundColor(DS.Colors.textPrimary)
                        .monospacedDigit()
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(DS.Colors.textMuted)
                }
                Spacer()
                Divider()
                    .overlay(DS.Colors.border)
                    .frame(height: 44)
                Spacer()
                VStack(spacing: 4) {
                    Text("\(viewModel.kcal)")
                        .font(.title2.weight(.medium))
                        .foregroundColor(DS.Colors.textPrimary)
                        .monospacedDigit()
                    Text("KCal")
                        .font(.caption)
                        .foregroundColor(DS.Colors.textMuted)
                }
                Spacer()
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
            .padding(.horizontal, DS.Spacing.md)

            Spacer()

            // Done button
            Button {
                path.removeAll()
            } label: {
                Text("Done")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DS.Colors.textPrimary)
                    .cornerRadius(DS.Radius.button)
                    .padding(.horizontal, DS.Spacing.md)
            }
            .padding(.bottom, DS.Spacing.md)
        }
        .background(DS.Colors.bgPrimary.ignoresSafeArea())
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(DS.Colors.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Summary")
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundColor(DS.Colors.textPrimary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PostWorkoutSummaryView(
            streak: 3,
            duration: "30:02",
            kcal: 100,
            path: .constant([])
        )
    }
}
