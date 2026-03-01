//
//  HomeViewModel.swift
//  Revibe
//

import Foundation
import Combine

struct Movement: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let isAvailable: Bool
    let iconName: String
}

class HomeViewModel: ObservableObject {
    @Published var streak: Int = 3

    let greeting = "Hello User! 👋"
    let subtitle = "You ready for today's session"

    let movements: [Movement] = [
        Movement(name: "Lateral Raise", isAvailable: true, iconName: "figure.arms.open"),
        Movement(name: "Shoulder External Rotation", isAvailable: false, iconName: "figure.cooldown"),
        Movement(name: "Squat Pattern", isAvailable: false, iconName: "figure.strengthtraining.traditional")
    ]
}
