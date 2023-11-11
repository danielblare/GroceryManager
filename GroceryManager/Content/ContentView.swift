//
//  ContentView.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import SwiftUI
import SwiftData
import AVFoundation
import Observation
import Combine

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
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    private var captureSession: AVCaptureSession = AVCaptureSession()
    
    @ObservationIgnored
    private var captureMetadataDelegate: AVCaptureMetadataOutputObjectsDelegate!
    
    @ObservationIgnored
    private var captureVideodataDelegate: AVCaptureVideoDataOutputSampleBufferDelegate!
        
    init() {
        captureMetadataDelegate = CaptureMetadataDelegate(fire: barcodeDetected)
        captureVideodataDelegate = CaptureVideodataDelegate(fire: objectDetected)
        
        Task {
            cameraAccessGranted = await AVCaptureDevice.requestAccess(for: .video)
            if cameraAccessGranted {
                setupSession()
            } else {
                status = .noAccess
            }
        }
    }
    
    let subject: PassthroughSubject<Route, Never> = .init()
    
    private func objectDetected(_ value: String) {
        guard selectedTool == .object else { return }
        captureSession.stopRunning()
        subject.send(.object(value))
    }
    
    private func barcodeDetected(_ value: String) {
        guard selectedTool == .barcode else { return }
        captureSession.stopRunning()
        subject.send(.barcode(value))
    }
    
    func select(_ tool: ScanTool) {
        selectedTool = tool
    }

    func startSession() {
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    private func setOutputs() {
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(captureVideodataDelegate, queue: DispatchQueue.main)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        captureSession.addOutput(videoDataOutput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(captureMetadataDelegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8] // Define the types of barcodes you want to detect
        }
    }
    
    private func configure(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        if device.isAutoFocusRangeRestrictionSupported {
            device.autoFocusRangeRestriction = .none
        }
        
        device.unlockForConfiguration()
    }
    
    private func setupSession() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            status = .noCameraOnDevice
            return
        }
        
        do {
            
            try? configure(captureDevice)
            
            let input = try AVCaptureDeviceInput(device: captureDevice)

            captureSession.addInput(input)
                 
            setOutputs()
            
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

struct ContentView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: ViewModel = ViewModel()
    @Namespace private var namespace
    
    var body: some View {
        @Bindable var routeManager = dependencies.routeManager
        NavigationStack(path: $routeManager.routes) {
            Group {
                switch viewModel.status {
                case .noCameraOnDevice: NoCameraOnDeviceView
                case .notDefined: Text("Wait")
                case .noAccess: NoCameraAccessView
                case .goodToGo:
                    GeometryReader { proxy in
                        VideoCaptureView(videoPreviewLayer: $viewModel.videoPreviewLayer)
                            .ignoresSafeArea()
                        
                            .overlay(alignment: .bottom) {
                                makeToolbar(proxy: proxy)
                            }
                    }
                    .onAppear {
                        viewModel.startSession()
                    }
                }
            }
            .navigationDestination(for: Route.self) { $0 }
        }
        .onReceive(viewModel.subject) { dependencies.routeManager.push(to: $0) }
    }
    
    private func makeToolbar(proxy: GeometryProxy) -> some View {
        HStack(spacing: 30) {
            let primaryOpposite: Color = colorScheme == .dark ? .black : .white
            Button {

            } label: {
                Image(systemName: "plus")
                    .resizable()
                    .scaledToFit()
                    .padding(15)
                    .frame(width: 60, height: 60)
                    .background(primaryOpposite)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            HStack {
                ForEach(ScanTool.allCases, id: \.self) { tool in
                    let isSelected = viewModel.selectedTool == tool
                    Image(systemName: tool.icon)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(isSelected ? .primary : primaryOpposite)
                        .padding(15)
                        .frame(width: 60, height: 60)
                        .background {
                            if isSelected {
                                Circle()
                                    .fill(primaryOpposite)
                                    .matchedGeometryEffect(id: "selected_tool", in: namespace)
                            }
                        }
                        .onTapGesture {
                            viewModel.select(tool)
                        }
                }
            }
            .padding(5)
            .background(.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 50))
        }
        
        .padding(.bottom, proxy.size.height * 0.15)
        .animation(.interactiveSpring, value: viewModel.selectedTool)
        .sensoryFeedback(.selection, trigger: viewModel.selectedTool)

    }
    
    private var NoCameraOnDeviceView: some View {
        ContentUnavailableView("There is no camera available on this device", systemImage: "camera.fill")
    }
    
    private var NoCameraAccessView: some View {
        VStack {
            ContentUnavailableView("We will need access to your camera in order for app to work.\nTo allow camera using go Settings > Grocery > Camera", systemImage: "lock.shield.fill")
            
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                Button("Open in Settings") {
                    UIApplication.shared.open(settingsUrl)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    @State var dependencies = Dependencies()
    
    return SwiftDataPreview(preview: PreviewContainer(schema: SchemaV1.self)) {
        ContentView()
    }
    .environment(dependencies)
}
