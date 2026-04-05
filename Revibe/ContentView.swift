//
//  ContentView.swift
//  Revibe
//

import SwiftUI

enum Route: Hashable {
    case workout(movementName: String)
    case summary(SummaryPayload)
}

struct SummaryPayload: Hashable {
    let movementName: String
    let streak: Int
    let duration: String
    let kcal: Int
    let repsCompleted: Int
    let totalReps: Int
    let formScore: Int
}

enum Tab {
    case home, profile
}

struct ContentView: View {
    @State private var path: [Route] = []
    @State private var selectedTab: Tab = .home
    @StateObject private var homeViewModel = HomeViewModel()

    private var showTabBar: Bool {
        path.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack(path: $path) {
                Group {
                    switch selectedTab {
                    case .home:
                        HomeView(viewModel: homeViewModel, path: $path)
                    case .profile:
                        ProfileView()
                    }
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .workout(let movementName):
                        WorkoutView(
                            movementName: movementName,
                            streak: homeViewModel.streak,
                            path: $path
                        )
                    case .summary(let payload):
                        PostWorkoutSummaryView(
                            payload: payload,
                            path: $path
                        )
                    }
                }
            }

            if showTabBar {
                floatingTabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showTabBar)
    }

    // MARK: - Floating Tab Bar

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            tabBarButton(icon: "house.fill", label: "Home", tab: .home)
            tabBarButton(icon: "person.fill", label: "Profile", tab: .profile)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(DS.Colors.bgSecondary)
                .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .padding(.horizontal, 80)
        .padding(.bottom, 16)
    }

    private func tabBarButton(icon: String, label: String, tab: Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selectedTab == tab ? DS.Colors.accent : DS.Colors.textMuted)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ContentView()
}
