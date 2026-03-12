//
//  PoseOverlayView.swift
//  Revibe
//

import SwiftUI
import MediaPipeTasksVision

// MARK: - Skeleton connections (MediaPipe 33-landmark body)
// Each tuple is (fromIndex, toIndex) using MediaPipe Pose landmark indices.
private let skeletonConnections: [(Int, Int)] = [
    // Face
    (0, 1), (1, 2), (2, 3), (3, 7),
    (0, 4), (4, 5), (5, 6), (6, 8),
    // Shoulders
    (11, 12),
    // Left arm
    (11, 13), (13, 15), (15, 17), (15, 19), (15, 21), (17, 19),
    // Right arm
    (12, 14), (14, 16), (16, 18), (16, 20), (16, 22), (18, 20),
    // Torso
    (11, 23), (12, 24), (23, 24),
    // Left leg
    (23, 25), (25, 27), (27, 29), (27, 31), (29, 31),
    // Right leg
    (24, 26), (26, 28), (28, 30), (28, 32), (30, 32)
]

/// Arm landmark indices – drawn in accent colour to highlight the exercise joints.
private let armIndices: Set<Int> = [11, 12, 13, 14, 15, 16]
private let armConnections: Set<String> = ["11-13","13-15","12-14","14-16","11-12"]

struct PoseOverlayView: View {
    /// Latest pose landmarks (normalized 0–1). `nil` when no person is detected.
    let landmarks: [NormalizedLandmark]?
    /// The size of the camera preview area in points; used to convert normalised → screen coords.
    let size: CGSize

    // Front camera frames are mirrored: flip x so overlay matches the preview.
    var mirrored: Bool = true

    var body: some View {
        Canvas { ctx, canvasSize in
            guard let lms = landmarks, !lms.isEmpty else { return }

            let w = canvasSize.width
            let h = canvasSize.height

            // Helper: normalized landmark → CGPoint in view space.
            func point(_ i: Int) -> CGPoint? {
                guard i < lms.count else { return nil }
                let lm = lms[i]
                let rawX = CGFloat(lm.x)
                let x = mirrored ? (1.0 - rawX) * w : rawX * w
                let y = CGFloat(lm.y) * h
                return CGPoint(x: x, y: y)
            }

            // Draw skeleton lines
            for (from, to) in skeletonConnections {
                guard let p1 = point(from), let p2 = point(to) else { continue }

                let key = "\(min(from,to))-\(max(from,to))"
                let isArm = armConnections.contains(key)

                var path = Path()
                path.move(to: p1)
                path.addLine(to: p2)
                ctx.stroke(
                    path,
                    with: .color(isArm ? Color(red: 1, green: 0.3, blue: 0.3) : Color.white.opacity(0.6)),
                    lineWidth: isArm ? 3 : 2
                )
            }

            // Draw joint dots
            for i in 0..<lms.count {
                guard let p = point(i) else { continue }

                let isArm = armIndices.contains(i)
                let radius: CGFloat = isArm ? 7 : 4

                // Filled dot
                let dot = Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
                ctx.fill(dot, with: .color(isArm ? Color(red: 1, green: 0.3, blue: 0.3) : Color.white))

                // Outline
                ctx.stroke(
                    dot,
                    with: .color(Color.black.opacity(0.5)),
                    lineWidth: 1
                )
            }
        }
        .allowsHitTesting(false)  // Transparent to touch – camera view still receives gestures.
    }
}
