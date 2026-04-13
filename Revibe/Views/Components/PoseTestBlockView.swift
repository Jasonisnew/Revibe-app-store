//
//  PoseTestBlockView.swift
//  Revibe
//

import SwiftUI

/// Separate front-page block for pose-testing access and status guidance.
/// This does not alter any personalized workout-plan content.
struct PoseTestBlockView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Pose Test", systemImage: "figure.strengthtraining.traditional")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DS.Colors.textPrimary)

                Spacer()

                HStack(spacing: 8) {
                    Text("Beta")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(DS.Colors.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(DS.Colors.blue.opacity(0.16)))
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(DS.Colors.textMuted)
                }
            }

            Text("Tap to open all five movements and test each one individually.")
                .font(.subheadline)
                .foregroundColor(DS.Colors.textMuted)

            HStack(spacing: 8) {
                statusChip(icon: "camera.fill", text: "Camera Ready")
                statusChip(icon: "person.fill.checkmark", text: "Pose Tracking")
            }

            Text("Tip: Keep your full body in frame and stand side-on for push-up checks.")
                .font(.caption)
                .foregroundColor(DS.Colors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Colors.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }

    private func statusChip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundColor(DS.Colors.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Capsule().fill(DS.Colors.bgTertiary))
    }
}

#Preview {
    PoseTestBlockView()
        .padding()
        .background(DS.Colors.bgPrimary)
}
