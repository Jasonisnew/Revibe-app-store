//
//  PoseLandmarkerService.swift
//  Revibe
//

import Foundation
import MediaPipeTasksVision
import UIKit

/// Runs MediaPipe Pose Landmarker on camera frames. Use `.image` mode and call `detect(pixelBuffer:)` on a background queue.
final class PoseLandmarkerService {

    private let inferenceQueue = DispatchQueue(label: "com.revibe.pose.inference")
    private var poseLandmarker: PoseLandmarker?

    /// Model resource name in the app bundle (without extension). Must match the .task file you added.
    private let modelName = "pose_landmarker_heavy"
    private let modelType = "task"

    var isReady: Bool { poseLandmarker != nil }

    init() {
        configureLandmarker()
    }

    private func configureLandmarker() {
        guard let path = Bundle.main.path(forResource: modelName, ofType: modelType) else {
            print("Revibe: Pose model not found. Add \(modelName).\(modelType) to the app bundle.")
            return
        }

        let options = PoseLandmarkerOptions()
        options.runningMode = .image
        options.numPoses = 1
        options.minPoseDetectionConfidence = 0.5
        options.minPosePresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5
        options.baseOptions.modelAssetPath = path
        options.baseOptions.delegate = .CPU

        do {
            poseLandmarker = try PoseLandmarker(options: options)
        } catch {
            print("Revibe: Failed to create PoseLandmarker: \(error)")
        }
    }

    /// Run pose detection on a pixel buffer. Call from a background queue. Returns the first pose's landmarks or nil.
    func detect(pixelBuffer: CVPixelBuffer) -> [NormalizedLandmark]? {
        guard let landmarker = poseLandmarker else { return nil }

        let image: MPImage
        do {
            image = try MPImage(pixelBuffer: pixelBuffer, orientation: .up)
        } catch {
            return nil
        }

        guard let result = try? landmarker.detect(image: image) else { return nil }
        guard let firstPose = result.landmarks.first, !firstPose.isEmpty else { return nil }
        return Array(firstPose)
    }
}
