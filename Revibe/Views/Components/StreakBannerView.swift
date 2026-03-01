//
//  StreakBannerView.swift
//  Revibe
//

import SwiftUI

struct StreakBannerView: View {
    let streak: Int

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Text("🔥")
                .font(.system(size: 30))

            VStack(alignment: .leading, spacing: 3) {
                Text("\(streak)-day streak")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DS.Colors.textPrimary)
                Text("Keep up the work!")
                    .font(.subheadline)
                    .foregroundColor(DS.Colors.textMuted)
            }

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.sm)
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
}

#Preview {
    StreakBannerView(streak: 3)
        .padding()
        .background(DS.Colors.bgPrimary)
}
