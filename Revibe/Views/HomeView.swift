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
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {

                // 1. Compact greeting + streak badge + progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.greeting)
                                .font(.system(size: 26, weight: .regular, design: .serif))
                                .foregroundColor(DS.Colors.textPrimary)
                                .tracking(-0.3)
                            Text(viewModel.subtitle)
                                .font(.subheadline)
                                .foregroundColor(DS.Colors.textMuted)
                        }

                        Spacer()

                        StreakBadge(streak: viewModel.streak)
                    }

                    WeeklyProgressBar(
                        completedThisWeek: viewModel.completedThisWeek,
                        totalWorkouts: viewModel.plan?.days.count ?? 4
                    )
                }
                .padding(.top, 4)

                // Pose test (above plan content so it stays easy to find)
                Button {
                    path.append(.poseTestList)
                } label: {
                    PoseTestBlockView()
                }
                .buttonStyle(.plain)

                // 2. Today's workout hero card
                if let todayDay = viewModel.todayDay, let plan = viewModel.plan {
                    TodayWorkoutCard(
                        day: todayDay,
                        planSummary: plan.description,
                        onStart: {
                            if let movement = viewModel.movements.first(where: { $0.isAvailable }) {
                                path.append(.workout(movementName: movement.name))
                            }
                        }
                    )
                }

                // 4. Weekly plan (horizontal scroll, edge-to-edge)
                if let plan = viewModel.plan {
                    WeekOverviewView(
                        plan: plan,
                        todayDayIndex: viewModel.todayDayIndex,
                        horizontalInset: DS.Spacing.md
                    )
                }

            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, 80)
        }
        .background(DS.Colors.bgPrimary.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DS.Colors.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel(), path: .constant([]))
    }
}
