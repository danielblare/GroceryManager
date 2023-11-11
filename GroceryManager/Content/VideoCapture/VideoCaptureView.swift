//
//  VideoCaptureView.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import SwiftUI
import AVFoundation

struct VideoCaptureView: UIViewRepresentable {
    @Binding var videoPreviewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        videoPreviewLayer.removeFromSuperlayer()
        uiView.layer.addSublayer(videoPreviewLayer)
    }
}
