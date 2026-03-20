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

    // #region agent log
    private func writeLog(_ payload: String) {
        let path = "/Users/jasonliu/Desktop/Revibe-app-store/.cursor/debug-fefa6b.log"
        let line = payload + "\n"
        guard let data = line.data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: path) {
            if let fh = FileHandle(forWritingAtPath: path) { fh.seekToEndOfFile(); fh.write(data); fh.closeFile() }
        } else {
            FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
        }
    }
    // #endregion agent log

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Status badge
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

            // Icon area
            ZStack {
                RoundedRectangle(cornerRadius: 40)
                    .fill(DS.Colors.bgPrimary.opacity(0.45))
                    .frame(height: 80)
                Image(systemName: movement.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(movement.isAvailable ? DS.Colors.textPrimary : DS.Colors.textMuted)
            }

            Spacer(minLength: 0)

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
        .frame(width: 165, height: 240)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 40))
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
