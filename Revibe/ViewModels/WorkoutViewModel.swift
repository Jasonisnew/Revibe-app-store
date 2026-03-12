//
//  WorkoutViewModel.swift
//  Revibe
//

import Foundation
import Combine
import MediaPipeTasksVision

class WorkoutViewModel: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var feedbackText: String = "Raise arms higher"
    @Published var repCount: Int = 0
    @Published var isComplete: Bool = false
    @Published var lastLandmarks: [NormalizedLandmark]? = nil

    let instructionCue = "Keep your back straight and core engaged"
    let elapsedTime = "30:02"
    let kcal = 100

    private var progressTimer: Timer?
    private var feedbackTimer: Timer?
    private var feedbackIndex = 0
    private var usePoseDrivenUpdates = false

    private let feedbackMessages = [
        "Raise arms higher",
        "Good form!",
        "Lower slightly",
        "Keep it up!",
        "Almost there!"
    ]

    /// Call from the main queue when using pose detection (e.g. lateral raise).
    func updateFromPose(feedback: String, repCount: Int, progress: Double, landmarks: [NormalizedLandmark]? = nil) {
        feedbackText = feedback
        self.repCount = repCount
        self.progress = progress
        self.lastLandmarks = landmarks
        isComplete = progress >= 1.0
    }

    /// Start session. Pass usePoseDriven: true when pose detection will drive feedback/progress (no fake timers).
    func startSession(usePoseDriven: Bool = false) {
        usePoseDrivenUpdates = usePoseDriven
        if usePoseDriven { return }

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.progress < 1.0 {
                self.progress = min(self.progress + 0.005, 1.0)
            } else {
                self.progressTimer?.invalidate()
                self.isComplete = true
            }
        }

        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.feedbackIndex = (self.feedbackIndex + 1) % self.feedbackMessages.count
            self.feedbackText = self.feedbackMessages[self.feedbackIndex]
        }
    }

    func stopSession() {
        progressTimer?.invalidate()
        feedbackTimer?.invalidate()
        progressTimer = nil
        feedbackTimer = nil
    }

    deinit {
        stopSession()
    }
}
