//
//  HomeView.swift
//  Revibe
//

import SwiftUI
import Supabase

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var path: [Route]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
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

                    StreakBannerView(streak: viewModel.streak)

                    Divider()
                        .overlay(DS.Colors.border)

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
            .task {
                await viewModel.loadUserData()
            }

            Button {
                Task { try? await supabase.auth.signOut() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Sign Out")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(DS.Colors.accent)
                .cornerRadius(DS.Radius.button)
                .shadow(color: DS.Colors.accent.opacity(0.4), radius: 6, x: 0, y: 3)
            }
            .padding(.leading, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.md)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel(), path: .constant([]))
    }
}
