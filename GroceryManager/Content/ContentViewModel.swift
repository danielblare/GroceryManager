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
    
    /// View model status
    enum Status {
        /// no device with that media type exists
        case noCameraOnDevice
        /// user didn't provide access to the camera
        case noAccess
        
        case idle
        case ready
    }
    
    // MARK: Managers, Delegates, UIKit
    /// Barcode manager instance
    @ObservationIgnored private let barcodeManager: BarcodeManager = BarcodeManager()
    
    /// Delegate for barcode scanning
    @ObservationIgnored private var captureMetadataDelegate: AVCaptureMetadataOutputObjectsDelegate!
    
    /// Delegate for object identifying
    @ObservationIgnored private var captureVideodataDelegate: AVCaptureVideoDataOutputSampleBufferDelegate!
    
    /// Current capture device
    private var captureDevice: AVCaptureDevice?
    
    /// Current capture session
    private var captureSession: AVCaptureSession = AVCaptureSession()
    
    /// Video preview layer
    var videoPreviewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    /// Current output for capture session
    private var currentOutput: AVCaptureOutput?
    
    
    // MARK: View variables
    /// Current status
    private(set) var status: Status = .idle
    
    /// Current tool selection in scanner view
    private(set) var selectedTool: ScanTool = .object
    
    /// Alert to display in main view
    var alert: AlertData?
    
    /// Indicated identified product to display confirmation sheet
    var productIdentified: Product?
    
    /// Indicated successfull object captured for ML scanning
    private(set) var isScanning: Bool = false
    
    /// Indicated when view model is processing barcode
    private(set) var isLoading: Bool = false
    
    
    // MARK: Indication booleans
    
    /// Indicated whether camera access was granted by the user
    private var cameraAccessGranted: Bool = false
    
    /// Indicates whether the flash is currently available for use
    var flashAvailable: Bool {
        captureDevice?.isFlashAvailable ?? false
    }
    
    /// Indicates whether the device’s flash is currently active
    var isFlashOn: Bool {
        captureDevice?.isTorchActive ?? false
    }
    
    init() {
        Task {
            // Requesting camera access
            cameraAccessGranted = await AVCaptureDevice.requestAccess(for: .video)
            
            guard cameraAccessGranted else {
                status = .noAccess
                return
            }
            
            // Checking for capture device
            guard let captureDevice = AVCaptureDevice.default(for: .video) else {
                status = .noCameraOnDevice
                return
            }
            
            self.captureDevice = captureDevice
            
            // Setting delegates
            captureMetadataDelegate = CaptureMetadataDelegate(fire: barcodeDetected)
            captureVideodataDelegate = CaptureVideodataDelegate(isScanning: .init(get: { self.isScanning }, set: { self.isScanning = $0 }), fire: objectDetected)
            
            // Setting up capture session
            setupSession()
        }
    }
}
 
// MARK: Capture session functions
extension ViewModel {
    
    /// Configuring capture device
    private func configureDevice() throws {
        guard let captureDevice else { return }
        try captureDevice.lockForConfiguration()
        
        // Setting autofocus
        if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
            captureDevice.focusMode = .continuousAutoFocus
        }
        
        // Setting range restriction
        if captureDevice.isAutoFocusRangeRestrictionSupported {
            captureDevice.autoFocusRangeRestriction = .near
        }
        
        captureDevice.unlockForConfiguration()
    }

    /// Setting up capture session
    /// Configuring device > adding input > setting output > assigning video layer > running session
    private func setupSession() {
        
        // Checking for device
        guard let captureDevice else {
            status = .noCameraOnDevice
            return
        }
        
        do {
            // Configuring device
            try? configureDevice()
            
            let input = try AVCaptureDeviceInput(device: captureDevice)

            // Adding input
            captureSession.addInput(input)
                 
            // Setting output
            setOutput(to: selectedTool)
            
            // Assigning video layer
            videoPreviewLayer.session = captureSession
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame = UIScreen.main.bounds
            
            // Starting session
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }

            status = .ready
        } catch {
            status = .noAccess
        }
    }

    /// Setting output according to selected `ScanTool`
    private func setOutput(to tool: ScanTool) {
        captureSession.beginConfiguration()
        
        if let currentOutput { // Removing current output if exists
            captureSession.removeOutput(currentOutput)
        }
        
        switch tool {
        case .object: // Setting output for ML Identification
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.setSampleBufferDelegate(captureVideodataDelegate, queue: DispatchQueue.main)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            captureSession.addOutput(videoDataOutput)
            
            currentOutput = videoDataOutput
        case .barcode: // Setting output for barcode scan
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
    
    /// Pausing capture session
    func pauseSession() {
        captureSession.stopRunning()
    }

    /// Starting capture session
    func continueSession() {
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
}
    
// MARK: View functions
extension ViewModel {
    
    /// Show blank editor for manual product adding
    func addManually() {
        pauseSession()

        let product = Product(title: "")
        productIdentified = product
    }
    
    /// Fires when object was recognized by ML Model
    private func objectDetected(_ value: String) {
        guard selectedTool == .object else { return }
        pauseSession()
        let product = Product(title: value)
        
        productIdentified = product
    }
    
    /// Fires when barcode was recognized
    private func barcodeDetected(_ value: String) {
        guard selectedTool == .barcode else { return }
        pauseSession()
        
        isLoading = true
        Task {
            defer {
                isLoading = false
            }
            
            do {
                // Fetching info about item
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
    
    /// Selecting `ScanTool`
    func select(_ tool: ScanTool) {
        selectedTool = tool
        setOutput(to: tool)
    }
    
    /// Toggling flashlight on the device
    func toggleFlashlight() {
        guard let captureDevice, flashAvailable else { return }
        do {
            try captureDevice.lockForConfiguration()
            
            captureDevice.torchMode = isFlashOn ? .off : .on
            
            captureDevice.unlockForConfiguration()
        } catch {}
    }
}
