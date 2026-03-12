//
//  WorkoutView.swift
//  Revibe
//

import SwiftUI
import Combine

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
            // Feedback header
            VStack(spacing: DS.Spacing.xs) {
                Text(viewModel.feedbackText)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundColor(DS.Colors.textPrimary)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.feedbackText)
                    .frame(minHeight: 36)
                    .tracking(-0.3)

                Text(viewModel.instructionCue)
                    .font(.subheadline)
                    .foregroundColor(DS.Colors.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.top, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.sm)

            // Progress bar and rep count
            HStack(spacing: DS.Spacing.xs) {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: DS.Colors.accent))
                Text("\(viewModel.repCount) reps")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(DS.Colors.textMuted)
                Text("\(Int(viewModel.progress * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(DS.Colors.textMuted)
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.sm)

            // Live camera feed + pose overlay
            GeometryReader { geo in
                ZStack {
                    CameraPreviewView(cameraManager: cameraManager)

                    PoseOverlayView(
                        landmarks: viewModel.lastLandmarks,
                        size: geo.size
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 370)
            .padding(.horizontal, DS.Spacing.md)

            Spacer()

            // Hairline divider above controls
            Divider()
                .overlay(DS.Colors.border)
                .padding(.bottom, DS.Spacing.sm)

            // Bottom controls
            HStack(spacing: 12) {
                Button {
                    viewModel.stopSession()
                    path.removeAll()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.medium))
                        Text("End Session")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())

                Spacer()

                Button {
                    viewModel.stopSession()
                    path.append(.summary(
                        streak: streak,
                        duration: viewModel.elapsedTime,
                        kcal: viewModel.kcal
                    ))
                } label: {
                    Text("Complete")
                        .frame(minWidth: 110)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.sm)
        }
        .background(DS.Colors.bgPrimary.ignoresSafeArea())
        .navigationTitle(movementName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DS.Colors.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(movementName)
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundColor(DS.Colors.textPrimary)
            }
        }
        .onAppear {
            lateralRaiseAnalyzer.setTargetReps(10)
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
                    landmarks: result.landmarks
                )
            }
    }

    /// Shows "Move into frame" if no pose is detected for more than 1.5 seconds.
    private func startNoPoseWatchdog() {
        lastDetectionTime = Date()
        noPoseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let gap = Date().timeIntervalSince(lastDetectionTime)
            if gap > 1.5 {
                viewModel.feedbackText = "Move into frame"
                viewModel.lastLandmarks = nil
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
