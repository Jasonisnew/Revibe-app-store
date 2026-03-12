//
//  CameraManager.swift
//  Revibe
//

import AVFoundation
import Combine
import UIKit

final class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    // MARK: - Session & Queues

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.revibe.capture")
    private let sampleBufferQueue = DispatchQueue(label: "com.revibe.samplebuffer")

    // MARK: - Output & Preview

    private let videoOutput = AVCaptureVideoDataOutput()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: session)

    // MARK: - Frame Delivery (Combine)

    let frameSubject = PassthroughSubject<CVPixelBuffer, Never>()

    // MARK: - Throttling & State

    private var frameCount = 0
    private var hasConfigured = false

    // MARK: - Init

    override init() {
        super.init()
        previewLayer.videoGravity = .resizeAspectFill
    }

    // MARK: - Public API

    /// Call when the workout view appears. Requests camera permission, configures once, then starts capture.
    func startSession() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }
            if !granted {
                DispatchQueue.main.async {
                    // Post notification or set a published property so UI can show "Camera access required"
                }
                return
            }
            self.sessionQueue.async {
                self.configureIfNeeded()
                self.session.startRunning()
            }
        }
    }

    /// Call when the workout view disappears.
    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    /// Use this in a UIViewRepresentable to show the live camera feed.
    var previewLayerForDisplay: AVCaptureVideoPreviewLayer {
        previewLayer
    }

    // MARK: - Configuration (runs once on session queue)

    private func configureIfNeeded() {
        guard !hasConfigured else { return }
        hasConfigured = true

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        // Front camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return
        }

        guard let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
            return
        }
        session.addInput(input)

        // Video data output for pose (BGRA)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)

        guard session.canAddOutput(videoOutput) else { return }
        session.addOutput(videoOutput)

        // Portrait orientation so preview and frames match (iOS 17+ uses videoRotationAngle)
        if let connection = videoOutput.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Throttle to ~every 2nd frame to reduce CPU (optional; remove or change divisor as needed)
        frameCount += 1
        if frameCount % 2 != 0 { return }

        frameSubject.send(pixelBuffer)
    }
}
