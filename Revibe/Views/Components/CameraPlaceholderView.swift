//
//  CameraPlaceholderView.swift
//  Revibe
//

import SwiftUI

struct CameraPlaceholderView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Colors.bgSecondary)
                .overlay(
                    VStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(DS.Colors.textMuted)
                        Text("Live Camera Feed")
                            .font(.subheadline)
                            .foregroundColor(DS.Colors.textMuted)
                        Text("Pose Detection Overlay")
                            .font(.caption)
                            .foregroundColor(DS.Colors.border)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(DS.Colors.border, lineWidth: 1)
                )

            // Reference thumbnail overlay
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.button)
                    .fill(DS.Colors.bgPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.button)
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )
                    .frame(width: 72, height: 72)
                Image(systemName: "person.fill.viewfinder")
                    .font(.system(size: 26))
                    .foregroundColor(DS.Colors.textMuted)
            }
            .padding(DS.Spacing.sm)
        }
    }
}

#Preview {
    CameraPlaceholderView()
        .frame(height: 360)
        .padding()
        .background(DS.Colors.bgPrimary)
}
