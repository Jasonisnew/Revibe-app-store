//
//  ContentView.swift
//  Revibe
//

import SwiftUI

enum Route: Hashable {
    case workout(movementName: String)
    case summary(streak: Int, duration: String, kcal: Int)
}

struct ContentView: View {
    @State private var path: [Route] = []
    @StateObject private var homeViewModel = HomeViewModel()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(viewModel: homeViewModel, path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .workout(let movementName):
                        WorkoutView(
                            movementName: movementName,
                            streak: homeViewModel.streak,
                            path: $path
                        )
                    case .summary(let streak, let duration, let kcal):
                        PostWorkoutSummaryView(
                            streak: streak,
                            duration: duration,
                            kcal: kcal,
                            path: $path
                        )
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
