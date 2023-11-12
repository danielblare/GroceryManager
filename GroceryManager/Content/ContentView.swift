//
//  ContentView.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    @Namespace private var namespace
    
    @State private var viewModel: ViewModel = ViewModel()
    
    var body: some View {
        @Bindable var routeManager = dependencies.routeManager
        NavigationStack(path: $routeManager.routes) {
            Group {
                switch viewModel.status {
                case .noCameraOnDevice: NoCameraOnDeviceView
                case .idle: Text("Wait...")
                case .noAccess: NoCameraAccessView
                case .ready: MainView
                }
            }
            // Navigation
            .navigationTitle("Scanning")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { $0 }
            
            // Presenting sheet with product editor
            .sheet(item: $viewModel.productIdentified) { viewModel.continueSession() } content: { product in
                NavigationStack {
                    ProductOverview(for: product)
                        .navigationTitle("Add product")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Save") {
                                    context.insert(product)
                                    viewModel.productIdentified = nil
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
            }
            
            // Haptic, animations, alerts
            .alert($viewModel.alert)
            .sensoryFeedback(.error, trigger: viewModel.alert, condition: { $1 != nil })
            .sensoryFeedback(.success, trigger: viewModel.productIdentified, condition: { $1 != nil })
        }
    }
    
    /// Main vieo capturing view
    private var MainView: some View {
        GeometryReader { proxy in
            VideoCaptureView(videoPreviewLayer: $viewModel.videoPreviewLayer)
                .ignoresSafeArea()
                .overlay {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                            .background(.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    } else if viewModel.selectedTool == .object, viewModel.isScanning {
                        Text("Scanning object...")
                    }
                }
            // Top toolbar
                .overlay(alignment: .top) {
                    makeTopToolbar()
                        .disabled(viewModel.isLoading)
                }
            // Bottom toolbar
                .overlay(alignment: .bottom) {
                    makeBottomToolbar(proxy: proxy)
                        .disabled(viewModel.isLoading)
                }
        }
        .onDisappear {
            viewModel.pauseSession()
        }
        .onAppear {
            viewModel.continueSession()
        }
        .animation(.easeInOut, value: viewModel.isScanning)
    }
    
    /// Top toolbar
    private func makeTopToolbar() -> some View {
        HStack {
            let primaryOpposite: Color = colorScheme == .dark ? .black : .white
            Button {
                dependencies.routeManager.push(to: .list)
            } label: {
                Image(systemName: "list.bullet")
                    .resizable()
                    .scaledToFit()
                    .padding(15)
                    .frame(width: 60, height: 60)
                    .background(primaryOpposite)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Button {
                viewModel.toggleFlashlight()
            } label: {
                Image(systemName: viewModel.flashAvailable ? "flashlight.\(viewModel.isFlashOn ? "on" : "off").fill" : "flashlight.slash")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(viewModel.isFlashOn ? primaryOpposite : .primary)
                    .padding(15)
                    .frame(width: 60, height: 60)
                    .background(viewModel.isFlashOn ? .primary : primaryOpposite)
                    .clipShape(Circle())
            }
            .disabled(!viewModel.flashAvailable)
        }
        .buttonStyle(.plain)
        .padding()
        
        .sensoryFeedback(.selection, trigger: viewModel.isFlashOn)
        .animation(.interactiveSpring, value: viewModel.isFlashOn)
    }
    
    /// Botton toolbar
    private func makeBottomToolbar(proxy: GeometryProxy) -> some View {
        HStack(spacing: 30) {
            let primaryOpposite: Color = colorScheme == .dark ? .black : .white
            Button {
                viewModel.addManually()
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
                            if !isSelected {
                                viewModel.select(tool)
                            }
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
