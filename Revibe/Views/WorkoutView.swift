//
//  WorkoutView.swift
//  Revibe
//

import SwiftUI
import Combine
import Supabase

struct WorkoutView: View {
    let movementName: String
    let streak: Int
    @Binding var path: [Route]

    @StateObject private var viewModel = WorkoutViewModel()
    @State private var cameraManager = CameraManager()
    @State private var poseService = PoseLandmarkerService()
    @State private var lateralRaiseAnalyzer = LateralRaiseAnalyzer()
    @State private var posePipelineCancellable: AnyCancellable?
    @State private var noPoseTimer: Timer? = nil
    @State private var lastDetectionTime: Date = .distantPast

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Set info bar
            setInfoBar
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.xs)

            // MARK: Main coaching cue
            coachingCue
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.sm)

            // MARK: Progress + quality row
            progressRow
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, 10)
                .padding(.bottom, 10)

            // MARK: Camera with overlays
            cameraSection
                .padding(.horizontal, DS.Spacing.md)

            Spacer(minLength: DS.Spacing.sm)

            // MARK: Bottom controls
            bottomControls
                .padding(.horizontal, DS.Spacing.md)
                .padding(.bottom, DS.Spacing.sm)
        }
        .background(DS.Colors.bgPrimary.ignoresSafeArea())
        .navigationTitle(movementName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DS.Colors.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(movementName)
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundColor(DS.Colors.textPrimary)
            }
        }
        .onAppear {
            lateralRaiseAnalyzer.setTargetReps(viewModel.repsPerSet)
            viewModel.startSession(usePoseDriven: true)
            cameraManager.startSession()
            startPosePipeline()
            startNoPoseWatchdog()
        }
        .onDisappear {
            posePipelineCancellable = nil
            noPoseTimer?.invalidate()
            noPoseTimer = nil
            viewModel.stopSession()
            cameraManager.stopSession()
            lateralRaiseAnalyzer.reset()
        }
    }

    // MARK: - Set Info Bar

    private var setInfoBar: some View {
        HStack {
            HStack(spacing: 6) {
                Text("Set \(viewModel.currentSet)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.Colors.textPrimary)
                Text("of \(viewModel.totalSets)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DS.Colors.textMuted)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "repeat")
                    .font(.caption2)
                    .foregroundColor(DS.Colors.textMuted)
                Text("\(viewModel.totalSets) × \(viewModel.repsPerSet) reps")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DS.Colors.textSecondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(DS.Colors.textMuted)
                Text("Rest \(viewModel.restDuration)s")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DS.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Colors.bgSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(DS.Colors.border, lineWidth: 1)
                )
        )
    }

    // MARK: - Coaching Cue

    private var coachingCue: some View {
        VStack(spacing: 4) {
            if viewModel.isResting {
                Text("Rest — \(viewModel.restRemaining)s")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(DS.Colors.blue)
                    .tracking(-0.3)
            } else {
                Text(viewModel.feedbackText)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(feedbackColor)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.feedbackText)
                    .tracking(-0.3)
            }

            Text(viewModel.instructionCue)
                .font(.subheadline)
                .foregroundColor(DS.Colors.textMuted)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var feedbackColor: Color {
        switch viewModel.formQuality {
        case .good: return DS.Colors.accent
        case .fair: return Color(red: 255/255, green: 214/255, blue: 10/255)
        case .poor: return DS.Colors.error
        }
    }

    // MARK: - Progress Row

    private var progressRow: some View {
        HStack(spacing: 12) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DS.Colors.border)
                        .frame(height: 8)

                    Capsule()
                        .fill(DS.Gradients.progress)
                        .frame(width: max(geo.size.width * viewModel.progress, viewModel.progress > 0 ? 8 : 0), height: 8)
                        .animation(.easeOut(duration: 0.3), value: viewModel.progress)
                }
            }
            .frame(height: 8)

            Text("\(viewModel.repCount)/\(viewModel.repsPerSet)")
                .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundColor(DS.Colors.textSecondary)
                .frame(width: 38)

            qualityBadge
        }
    }

    private var qualityBadge: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(qualityDotColor)
                .frame(width: 7, height: 7)
            Text(viewModel.formQuality.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(qualityDotColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(qualityDotColor.opacity(0.12))
        )
    }

    private var qualityDotColor: Color {
        switch viewModel.formQuality {
        case .good: return DS.Colors.success
        case .fair: return Color(red: 255/255, green: 214/255, blue: 10/255)
        case .poor: return DS.Colors.error
        }
    }

    // MARK: - Camera Section

    private var cameraSection: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                ZStack {
                    CameraPreviewView(cameraManager: cameraManager)

                    PoseOverlayView(
                        landmarks: viewModel.lastLandmarks,
                        size: geo.size
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))

                // Error labels overlay at bottom of camera
                if !viewModel.errorLabels.isEmpty && !viewModel.isResting {
                    VStack(spacing: 6) {
                        ForEach(viewModel.errorLabels, id: \.self) { label in
                            errorTag(label)
                        }
                    }
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.errorLabels)
                }

                // Tracking status indicator
                HStack {
                    Spacer()
                    trackingIndicator
                        .padding(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
    }

    private func errorTag(_ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(DS.Colors.error.opacity(0.85))
        )
    }

    private var trackingIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(viewModel.isTracking ? DS.Colors.success : DS.Colors.error)
                .frame(width: 6, height: 6)
            Text(viewModel.isTracking ? "Tracking" : "No pose")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.black.opacity(0.5)))
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.stopSession()
                path.removeAll()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.medium))
                    Text("End")
                }
            }
            .buttonStyle(SecondaryButtonStyle())

            Button {
                viewModel.togglePause()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.caption.weight(.medium))
                    Text(viewModel.isPaused ? "Resume" : "Pause")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(DS.Colors.textPrimary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(DS.Colors.bgTertiary)
                .cornerRadius(DS.Radius.button)
            }

            Spacer()

            Button {
                viewModel.stopSession()
                Task { await recordCompletion() }
                path.append(.summary(SummaryPayload(
                    movementName: movementName,
                    streak: streak,
                    duration: viewModel.elapsedTime,
                    kcal: viewModel.kcal,
                    repsCompleted: viewModel.repCount,
                    totalReps: viewModel.repsPerSet * viewModel.totalSets,
                    formScore: viewModel.formScorePercent
                )))
            } label: {
                Text("Complete")
                    .frame(minWidth: 100)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    // MARK: - Pose Pipeline

    private func startPosePipeline() {
        let queue = DispatchQueue(label: "com.revibe.pose.pipeline")
        posePipelineCancellable = cameraManager.frameSubject
            .receive(on: queue)
            .compactMap { [poseService] pixelBuffer in
                poseService.detect(pixelBuffer: pixelBuffer)
            }
            .receive(on: DispatchQueue.main)
            .compactMap { [lateralRaiseAnalyzer] landmarks in
                lateralRaiseAnalyzer.analyze(landmarks: landmarks)
            }
            .sink { [self] result in
                lastDetectionTime = Date()
                viewModel.updateFromPose(
                    feedback: result.feedbackText,
                    repCount: result.repCount,
                    progress: result.progress,
                    landmarks: result.landmarks,
                    errorLabels: result.errorLabels,
                    formQuality: result.formQuality
                )
            }
    }

    private func recordCompletion() async {
        do {
            let userId = try await supabase.auth.session.user.id.uuidString
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let completion = WorkoutCompletion(
                userId: userId,
                completedAt: formatter.string(from: Date()),
                timezone: TimeZone.current.identifier
            )

            try await supabase
                .from("workout_completions")
                .insert(completion)
                .execute()
        } catch { }
    }

    private func startNoPoseWatchdog() {
        lastDetectionTime = Date()
        noPoseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let gap = Date().timeIntervalSince(lastDetectionTime)
            if gap > 1.5 {
                viewModel.feedbackText = "Move into frame"
                viewModel.lastLandmarks = nil
                viewModel.isTracking = false
                viewModel.errorLabels = []
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutView(
            movementName: "Lateral Raise",
            streak: 3,
            path: .constant([])
        )
    }
}
