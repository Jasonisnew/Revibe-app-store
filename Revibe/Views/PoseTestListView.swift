//
//  PoseTestListView.swift
//  Revibe
//

import SwiftUI

struct PoseTestListView: View {
    @Binding var path: [Route]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Choose a movement to test")
                    .font(.subheadline)
                    .foregroundColor(DS.Colors.textMuted)

                ForEach(PoseTestExercise.allCases) { exercise in
                    Button {
                        path.append(.poseTestExercise(exercise))
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                Image(systemName: exercise.systemIcon)
                                    .font(.system(size: 22))
                                    .frame(width: 30)
                                    .foregroundColor(DS.Colors.accent)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(exercise.displayName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(DS.Colors.textPrimary)
                                    Text(exercise.goalLabel)
                                        .font(.caption)
                                        .foregroundColor(DS.Colors.accent.opacity(0.8))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(DS.Colors.textMuted)
                            }

                            Text(exercise.standardDescription)
                                .font(.caption)
                                .foregroundColor(DS.Colors.textSecondary)
                                .lineLimit(2)

                            HStack(spacing: 4) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 10))
                                Text(exercise.cameraPosition.components(separatedBy: " · ").first ?? "")
                                    .font(.caption2)
                            }
                            .foregroundColor(DS.Colors.textMuted)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.card)
                                .fill(DS.Colors.bgSecondary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.card)
                                .stroke(DS.Colors.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.top, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.lg)
        }
        .background(DS.Colors.bgPrimary.ignoresSafeArea())
        .navigationTitle("Pose Test")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DS.Colors.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        PoseTestListView(path: .constant([]))
    }
}
