//
//  MovementCardView.swift
//  Revibe
//

import SwiftUI

struct MovementCardView: View {
    let movement: Movement
    let onStartSession: () -> Void

    private var cardGradient: LinearGradient {
        let index = abs(movement.id.hashValue) % DS.Colors.cardPalette.count
        let base = DS.Colors.cardPalette[index]
        return LinearGradient(
            colors: [base, DS.Colors.blue.opacity(0.15)],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 4) {
                if movement.isAvailable {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.medium))
                        .foregroundColor(DS.Colors.accent)
                    Text("Available")
                        .font(.caption.weight(.medium))
                        .foregroundColor(DS.Colors.accent)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.medium))
                        .foregroundColor(DS.Colors.textMuted)
                    Text("Locked")
                        .font(.caption.weight(.medium))
                        .foregroundColor(DS.Colors.textMuted)
                }
                Spacer()
            }
            .frame(height: 16)

            Text(movement.name)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(DS.Colors.textPrimary)
                .lineLimit(2)
                .frame(height: 36, alignment: .topLeading)

            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(DS.Colors.bgPrimary.opacity(0.4))
                    .frame(height: 80)
                Image(systemName: movement.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(movement.isAvailable ? DS.Colors.textPrimary : DS.Colors.textMuted)
            }

            Spacer(minLength: 0)

            Button(action: onStartSession) {
                Text("Start Session")
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .foregroundColor(movement.isAvailable ? DS.Colors.textOnAccent : DS.Colors.textMuted)
                    .background(movement.isAvailable ? DS.Colors.accent : DS.Colors.bgTertiary)
                    .cornerRadius(DS.Radius.button)
            }
            .disabled(!movement.isAvailable)
        }
        .padding(DS.Spacing.sm)
        .frame(width: 165, height: 240)
        .background(cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .opacity(movement.isAvailable ? 1.0 : 0.6)
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
