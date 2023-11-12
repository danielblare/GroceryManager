//
//  ContentViewModel.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import SwiftUI
import AVFoundation
import Observation

@Observable
final class ViewModel {

    enum Status {
        case noCameraOnDevice
        case notDefined
        case noAccess
        case goodToGo
    }
    
    private(set) var status: Status = .notDefined
    private var cameraAccessGranted: Bool = false
    private(set) var selectedTool: ScanTool = .object
    
    private(set) var isLoading: Bool = false
        
    var alert: AlertData?
    private(set) var isScanning: Bool = false
    
    var flashAvailable: Bool {
        captureDevice?.isFlashAvailable ?? false
    }
    
    var isFlashOn: Bool {
        captureDevice?.isTorchActive ?? false
    }
    
    @ObservationIgnored
    private let barcodeManager: BarcodeManager = BarcodeManager()
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    private var captureSession: AVCaptureSession = AVCaptureSession()
    
    @ObservationIgnored
    private var captureMetadataDelegate: AVCaptureMetadataOutputObjectsDelegate!
    
    @ObservationIgnored
    private var captureVideodataDelegate: AVCaptureVideoDataOutputSampleBufferDelegate!
        
    private var captureDevice: AVCaptureDevice?
    
    init() {
        Task {
            cameraAccessGranted = await AVCaptureDevice.requestAccess(for: .video)
            
            guard cameraAccessGranted else {
                status = .noAccess
                return
            }
            guard let captureDevice = AVCaptureDevice.default(for: .video) else {
                status = .noCameraOnDevice
                return
            }
            
            self.captureDevice = captureDevice
            
            captureMetadataDelegate = CaptureMetadataDelegate(fire: barcodeDetected)
            captureVideodataDelegate = CaptureVideodataDelegate(isScanning: .init(get: { self.isScanning }, set: { self.isScanning = $0 }), fire: objectDetected)
            
            setupSession()
        }
    }
    
    var productIdentified: Product?
    
    private func objectDetected(_ value: String) {
        guard selectedTool == .object else { return }
        pauseSession()
        let product = Product(title: value)
        
        productIdentified = product
    }
    
    private func barcodeDetected(_ value: String) {
        guard selectedTool == .barcode else { return }
        pauseSession()
        
        isLoading = true
        Task {
            defer {
                isLoading = false
            }
            
            do {
                let item = try await barcodeManager.parseBarcode(value)
                await MainActor.run {
                    let product = Product(from: item, barcode: value)
                    productIdentified = product
                }
            } catch {
                alert = .init(title: "Error", message: "This Barcode cannot be identified") {
                    self.continueSession()
                }
            }
        }
    }
    
    func select(_ tool: ScanTool) {
        selectedTool = tool
        setOutput(to: tool)
    }
    
    func pauseSession() {
        captureSession.stopRunning()
    }

    func continueSession() {
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    func toggleFlashlight() {
        guard let captureDevice, flashAvailable else { return }
        do {
            try captureDevice.lockForConfiguration()
            
            captureDevice.torchMode = isFlashOn ? .off : .on
            
            captureDevice.unlockForConfiguration()
        } catch {  }
    }
    
    private var currentOutput: AVCaptureOutput?
    
    private func setOutput(to tool: ScanTool) {
        captureSession.beginConfiguration()
        if let currentOutput {
            captureSession.removeOutput(currentOutput)
        }
        switch tool {
        case .object:
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.setSampleBufferDelegate(captureVideodataDelegate, queue: DispatchQueue.main)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            captureSession.addOutput(videoDataOutput)

            currentOutput = videoDataOutput
        case .barcode:
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(captureMetadataDelegate, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.ean13, .ean8, .upce] // Define the types of barcodes you want to detect
                currentOutput = metadataOutput
            }
        }
        
        captureSession.commitConfiguration()
    }
    
    private func configureDevice() throws {
        guard let captureDevice else { return }
        try captureDevice.lockForConfiguration()
        
        if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
            captureDevice.focusMode = .continuousAutoFocus
        }
        if captureDevice.isAutoFocusRangeRestrictionSupported {
            captureDevice.autoFocusRangeRestriction = .near
        }
        
        captureDevice.unlockForConfiguration()
    }
    
    private func setupSession() {
        guard let captureDevice else {
            status = .noCameraOnDevice
            return
        }
        
        do {
            try? configureDevice()
            
            let input = try AVCaptureDeviceInput(device: captureDevice)

            captureSession.addInput(input)
                 
            setOutput(to: selectedTool)
            
            videoPreviewLayer.session = captureSession
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame = UIScreen.main.bounds
            
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }

            status = .goodToGo
        } catch {
            status = .noAccess
        }
    }
}
