//
//  WorkoutView.swift
//  Revibe
//

import SwiftUI

struct WorkoutView: View {
    let movementName: String
    let streak: Int
    @Binding var path: [Route]

    @StateObject private var viewModel = WorkoutViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Feedback header
            VStack(spacing: DS.Spacing.xs) {
                Text(viewModel.feedbackText)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundColor(DS.Colors.textPrimary)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.feedbackText)
                    .frame(minHeight: 36)
                    .tracking(-0.3)

                Text(viewModel.instructionCue)
                    .font(.subheadline)
                    .foregroundColor(DS.Colors.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.top, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.sm)

            // Progress bar
            HStack(spacing: DS.Spacing.xs) {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: DS.Colors.accent))
                Text("\(Int(viewModel.progress * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(DS.Colors.textMuted)
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.sm)

            // Camera placeholder
            CameraPlaceholderView()
                .frame(maxWidth: .infinity)
                .frame(height: 370)
                .padding(.horizontal, DS.Spacing.md)

            Spacer()

            // Hairline divider above controls
            Divider()
                .overlay(DS.Colors.border)
                .padding(.bottom, DS.Spacing.sm)

            // Bottom controls
            HStack(spacing: 12) {
                Button {
                    viewModel.stopSession()
                    path.removeAll()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.medium))
                        Text("End Session")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())

                Spacer()

                Button {
                    viewModel.stopSession()
                    path.append(.summary(
                        streak: streak,
                        duration: viewModel.elapsedTime,
                        kcal: viewModel.kcal
                    ))
                } label: {
                    Text("Complete")
                        .frame(minWidth: 110)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.sm)
        }
        .background(DS.Colors.bgPrimary.ignoresSafeArea())
        .navigationTitle(movementName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DS.Colors.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(movementName)
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundColor(DS.Colors.textPrimary)
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutView(
            movementName: "Lateral Raise",
            streak: 3,
            path: .constant([])
        )
    }
}
