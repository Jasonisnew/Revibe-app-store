//
//  HomeView.swift
//  Revibe
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var path: [Route]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                // Greeting
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.greeting)
                        .font(.system(size: 34, weight: .regular, design: .serif))
                        .foregroundColor(DS.Colors.textPrimary)
                        .tracking(-0.5)
                    Text(viewModel.subtitle)
                        .font(.subheadline)
                        .foregroundColor(DS.Colors.textMuted)
                }
                .padding(.top, DS.Spacing.xs)

                // Streak banner
                StreakBannerView(streak: viewModel.streak)

                // Divider
                Divider()
                    .overlay(DS.Colors.border)

                // Movement section
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Movement")
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .foregroundColor(DS.Colors.textPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.sm) {
                            ForEach(viewModel.movements) { movement in
                                MovementCardView(movement: movement) {
                                    path.append(.workout(movementName: movement.name))
                                }
                            }
                        }
                        .padding(.horizontal, 1)
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.md)
        }
        .background(DS.Colors.bgPrimary.ignoresSafeArea())
        .navigationTitle("Revibe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DS.Colors.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Revibe")
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundColor(DS.Colors.textPrimary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel(), path: .constant([]))
    }
}
