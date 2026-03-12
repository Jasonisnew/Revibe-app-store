//
//  CameraPreviewView.swift
//  Revibe
//

import AVFoundation
import SwiftUI
import UIKit

final class CameraPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
            guard let layer = previewLayer else { return }
            layer.frame = bounds
            self.layer.addSublayer(layer)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView(frame: .zero)
        view.backgroundColor = .black
        view.previewLayer = cameraManager.previewLayerForDisplay
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer?.frame = uiView.bounds
    }
}
