//
//  PoseExerciseTestView.swift
//  Revibe
//

import SwiftUI
import Combine
import MediaPipeTasksVision

struct PoseExerciseTestView: View {
    let exercise: PoseTestExercise

    @State private var cameraManager = CameraManager()
    @State private var poseService = PoseLandmarkerService()
    @State private var analyzer: PoseExerciseAnalyzer
    @State private var posePipelineCancellable: AnyCancellable?

    @State private var lastLandmarks: [NormalizedLandmark]?
    @State private var phaseText = "ready"
    @State private var repCount = 0
    @State private var holdSeconds = 0.0
    @State private var feedback: [String] = []
    @State private var isTracking = false
    @State private var suggestion = ""

    init(exercise: PoseTestExercise) {
        self.exercise = exercise
        _analyzer = State(initialValue: PoseExerciseAnalyzer(exercise: exercise))
    }

    private var progress: Double {
        let goal = Double(exercise.goalValue)
        guard goal > 0 else { return 0 }
        if exercise == .plank {
            return min(1.0, holdSeconds / goal)
        }
        return min(1.0, Double(repCount) / goal)
    }

    private var progressLabel: String {
        if exercise == .plank {
            return "\(Int(holdSeconds))s / \(exercise.goalValue)s"
        }
        return "\(repCount) / \(exercise.goalValue)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                // MARK: - Suggestion banner (performance-based)
                if !suggestion.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: suggestionIcon)
                            .font(.system(size: 14))
                            .foregroundColor(suggestionColor)
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundColor(DS.Colors.textPrimary)
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.card)
                            .fill(suggestionColor.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.card)
                            .stroke(suggestionColor.opacity(0.3), lineWidth: 1)
                    )
                }

                // MARK: - Camera position requirement
                HStack(spacing: 6) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 12))
                    Text(exercise.cameraPosition)
                        .font(.caption)
                }
                .foregroundColor(DS.Colors.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

                // MARK: - Stats + progress
                statsCard

                // MARK: - Camera
                GeometryReader { geo in
                    ZStack(alignment: .topTrailing) {
                        CameraPreviewView(cameraManager: cameraManager)

                        PoseOverlayView(
                            landmarks: lastLandmarks,
                            size: geo.size
                        )

                        trackingBadge
                            .padding(10)
                    }
                }
                .frame(height: 340)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(DS.Colors.border, lineWidth: 1)
                )

                // MARK: - Live feedback
                if !feedback.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(DS.Colors.error)
                            .font(.system(size: 13))
                        Text(feedback.joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundColor(DS.Colors.textSecondary)
                        Spacer()
                    }
                }

                // MARK: - Standards card
                VStack(alignment: .leading, spacing: 6) {
                    Text("Standards")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(DS.Colors.textMuted)
                    Text(exercise.standardDescription)
                        .font(.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .fill(DS.Colors.bgSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(DS.Colors.border, lineWidth: 1)
                )
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.top, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.lg)
        }
        .background(DS.Colors.bgPrimary.ignoresSafeArea())
        .navigationTitle(exercise.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DS.Colors.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            analyzer.reset()
            suggestion = "Get into position — \(exercise.cameraPosition.components(separatedBy: " · ").first ?? "front view")"
            cameraManager.startSession()
            startPosePipeline()
        }
        .onDisappear {
            posePipelineCancellable = nil
            cameraManager.stopSession()
        }
    }

    // MARK: - Suggestion helpers

    private var suggestionIcon: String {
        if progress >= 1.0 { return "checkmark.seal.fill" }
        if !feedback.isEmpty { return "exclamationmark.bubble.fill" }
        if !isTracking { return "camera.metering.unknown" }
        return "lightbulb.fill"
    }

    private var suggestionColor: Color {
        if progress >= 1.0 { return DS.Colors.success }
        if !feedback.isEmpty { return DS.Colors.error }
        if !isTracking { return DS.Colors.blue }
        return DS.Colors.accent
    }

    // MARK: - Stats card

    private var statsCard: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phase")
                        .font(.caption)
                        .foregroundColor(DS.Colors.textMuted)
                    Text(phaseText.capitalized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DS.Colors.textPrimary)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text(exercise == .plank ? "Hold" : "Reps")
                        .font(.caption)
                        .foregroundColor(DS.Colors.textMuted)
                    Text(exercise == .plank ? String(format: "%.1fs", holdSeconds) : "\(repCount)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(DS.Colors.accent)
                }
                .frame(minWidth: 70)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(exercise.goalLabel)
                        .font(.caption)
                        .foregroundColor(DS.Colors.textMuted)
                    Text(progressLabel)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(progress >= 1.0 ? DS.Colors.success : DS.Colors.textSecondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DS.Colors.border.opacity(0.5))
                        .frame(height: 6)
                    Capsule()
                        .fill(progress >= 1.0 ? DS.Colors.success : DS.Colors.accent)
                        .frame(width: max(geo.size.width * progress, progress > 0 ? 6 : 0), height: 6)
                        .animation(.easeOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Colors.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Tracking badge

    private var trackingBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isTracking ? DS.Colors.success : DS.Colors.error)
                .frame(width: 7, height: 7)
            Text(isTracking ? "Tracking" : "No pose")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.black.opacity(0.45)))
    }

    // MARK: - Pose pipeline

    private func startPosePipeline() {
        let queue = DispatchQueue(label: "com.revibe.pose.test.pipeline")
        posePipelineCancellable = cameraManager.frameSubject
            .receive(on: queue)
            .map { [poseService] pixelBuffer -> [NormalizedLandmark]? in
                poseService.detect(pixelBuffer: pixelBuffer)
            }
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { (landmarks: [NormalizedLandmark]) in
                let ts = Date().timeIntervalSince1970
                guard let result = analyzer.analyze(landmarks: landmarks, timestamp: ts) else {
                    isTracking = false
                    suggestion = "Move into frame so your full body is visible"
                    return
                }
                isTracking = true
                lastLandmarks = result.landmarks
                phaseText = result.phase
                repCount = result.repCount ?? repCount
                holdSeconds = result.holdSeconds ?? holdSeconds
                feedback = result.feedback
                updateSuggestion()
            }
    }

    private func updateSuggestion() {
        if progress >= 1.0 {
            suggestion = "Goal reached! Great job. Keep going or head back."
            return
        }
        if !isTracking {
            suggestion = "Move into frame so your full body is visible"
            return
        }
        if !feedback.isEmpty {
            suggestion = "Form check: \(feedback.joined(separator: ", "))"
            return
        }

        switch exercise {
        case .squat:
            if repCount == 0 {
                suggestion = "Start squatting — bend knees past 90° then stand back up"
            } else if repCount < 5 {
                suggestion = "Good pace! Keep depth consistent, \(exercise.goalValue - repCount) reps to go"
            } else {
                suggestion = "Almost there — stay controlled for the last \(exercise.goalValue - repCount) reps"
            }
        case .lunge:
            if repCount == 0 {
                suggestion = "Step forward and lower your back knee toward the floor"
            } else if repCount < 5 {
                suggestion = "Nice! Alternate legs evenly, \(exercise.goalValue - repCount) reps remaining"
            } else {
                suggestion = "Final stretch — keep your torso upright"
            }
        case .pushUp:
            if repCount == 0 {
                suggestion = "Start in plank position, lower chest toward the floor"
            } else if repCount < 5 {
                suggestion = "Solid reps! Maintain a straight body line, \(exercise.goalValue - repCount) to go"
            } else {
                suggestion = "Push through the last \(exercise.goalValue - repCount) — full range of motion"
            }
        case .jumpingJack:
            if repCount == 0 {
                suggestion = "Jump feet wide and raise arms overhead, then return"
            } else if repCount < 10 {
                suggestion = "Keep the rhythm! \(exercise.goalValue - repCount) reps left"
            } else {
                suggestion = "Home stretch — arms fully overhead each rep"
            }
        case .plank:
            let remaining = max(0, exercise.goalValue - Int(holdSeconds))
            if phaseText == "ready" {
                suggestion = "Get into plank position — hold a straight line from head to heels"
            } else if phaseText == "entering" {
                suggestion = "Good position! Hold steady to start the timer…"
            } else if phaseText == "badForm" {
                suggestion = "Timer paused — fix your form to resume (\(Int(holdSeconds))s banked)"
            } else if holdSeconds < 3 {
                suggestion = "Timer running! Keep that straight line"
            } else if remaining > 15 {
                suggestion = "Solid hold! Keep hips level, \(remaining)s remaining"
            } else {
                suggestion = "Almost there — stay tight for \(remaining) more seconds"
            }
        }
    }
}

#Preview {
    NavigationStack {
        PoseExerciseTestView(exercise: .squat)
    }
}
