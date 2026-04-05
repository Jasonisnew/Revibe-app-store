//
//  WorkoutViewModel.swift
//  Revibe
//

import Foundation
import Combine
import MediaPipeTasksVision

class WorkoutViewModel: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var feedbackText: String = "Get ready"
    @Published var repCount: Int = 0
    @Published var isComplete: Bool = false
    @Published var lastLandmarks: [NormalizedLandmark]? = nil

    @Published var errorLabels: [String] = []
    @Published var formQuality: FormQuality = .good
    @Published var currentSet: Int = 1
    @Published var totalSets: Int = 3
    @Published var repsPerSet: Int = 10
    @Published var restDuration: Int = 60
    @Published var restRemaining: Int = 0
    @Published var isResting: Bool = false
    @Published var isPaused: Bool = false
    @Published var isTracking: Bool = false

    let instructionCue = "Keep your back straight and core engaged"
    var elapsedTime: String { formatElapsed(elapsedSeconds) }
    var kcal: Int { max(1, Int(Double(elapsedSeconds) * 0.08)) }

    var formScorePercent: Int {
        guard formSamples > 0 else { return 100 }
        return Int(round(formScoreSum / Double(formSamples) * 100))
    }

    private var formScoreSum: Double = 0
    private var formSamples: Int = 0
    private var elapsedSeconds: Int = 0
    private var clockTimer: Timer?
    private var restTimer: Timer?
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

    func updateFromPose(feedback: String, repCount: Int, progress: Double,
                        landmarks: [NormalizedLandmark]? = nil,
                        errorLabels: [String] = [], formQuality: FormQuality = .good) {
        feedbackText = feedback
        self.repCount = repCount
        self.progress = progress
        self.lastLandmarks = landmarks
        self.errorLabels = errorLabels
        self.formQuality = formQuality
        self.isTracking = landmarks != nil

        if landmarks != nil {
            let sample: Double = switch formQuality {
            case .good: 1.0
            case .fair: 0.6
            case .poor: 0.25
            }
            formScoreSum += sample
            formSamples += 1
        }

        isComplete = progress >= 1.0

        if repCount >= repsPerSet && !isResting && currentSet < totalSets {
            beginRest()
        }
    }

    func startSession(usePoseDriven: Bool = false) {
        usePoseDrivenUpdates = usePoseDriven
        elapsedSeconds = 0
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, !self.isPaused else { return }
            self.elapsedSeconds += 1
        }

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

    func togglePause() {
        isPaused.toggle()
    }

    func stopSession() {
        progressTimer?.invalidate()
        feedbackTimer?.invalidate()
        clockTimer?.invalidate()
        restTimer?.invalidate()
        progressTimer = nil
        feedbackTimer = nil
        clockTimer = nil
        restTimer = nil
    }

    private func beginRest() {
        isResting = true
        restRemaining = restDuration
        feedbackText = "Rest"
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.restRemaining > 0 {
                self.restRemaining -= 1
            } else {
                self.restTimer?.invalidate()
                self.restTimer = nil
                self.isResting = false
                self.currentSet += 1
                self.feedbackText = "Set \(self.currentSet) — Go!"
            }
        }
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    deinit {
        stopSession()
    }
}
