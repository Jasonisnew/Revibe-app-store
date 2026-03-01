//
//  MovementCardView.swift
//  Revibe
//

import SwiftUI

struct MovementCardView: View {
    let movement: Movement
    let onStartSession: () -> Void

    private var cardColor: Color {
        let index = abs(movement.id.hashValue) % DS.Colors.cardPalette.count
        return DS.Colors.cardPalette[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status badge
            HStack {
                if movement.isAvailable {
                    Label("Available", systemImage: "checkmark")
                        .font(.caption.weight(.medium))
                        .foregroundColor(DS.Colors.accent)
                } else {
                    Label("Locked", systemImage: "lock.fill")
                        .font(.caption.weight(.medium))
                        .foregroundColor(DS.Colors.textMuted)
                }
                Spacer()
            }

            Text(movement.name)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(DS.Colors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Icon area
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(DS.Colors.bgPrimary.opacity(0.45))
                    .frame(height: 88)
                Image(systemName: movement.iconName)
                    .font(.system(size: 38))
                    .foregroundColor(movement.isAvailable ? DS.Colors.textPrimary : DS.Colors.textMuted)
            }

            // Start button
            Button(action: onStartSession) {
                Text("Start Session")
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .foregroundColor(movement.isAvailable ? .white : DS.Colors.textMuted)
                    .background(movement.isAvailable ? DS.Colors.textPrimary : DS.Colors.bgSecondary)
                    .cornerRadius(DS.Radius.button)
            }
            .disabled(!movement.isAvailable)
        }
        .padding(DS.Spacing.sm)
        .background(cardColor)
        .cornerRadius(DS.Radius.card)
        .opacity(movement.isAvailable ? 1.0 : 0.6)
        .frame(width: 165)
    }
}

#Preview {
    HStack(spacing: 12) {
        MovementCardView(
            movement: Movement(name: "Lateral Raise", isAvailable: true, iconName: "figure.arms.open"),
            onStartSession: {}
        )
        MovementCardView(
            movement: Movement(name: "Shoulder External Rotation", isAvailable: false, iconName: "figure.cooldown"),
            onStartSession: {}
        )
    }
    .padding()
    .background(DS.Colors.bgPrimary)
}
