# GroceryManager

Allows to scan your groceries using both machine learning and barcodes to recognize produce
- Scanning fruits and vegetables with DIY ML Model
- Recognizing barcodes and fetching data about it
- Add product manually if it wasn't recognized
- Browse/modify list of scanned products

## Code features
- AVFoundation with AVCapture input/output embedded
- API Calls for barcode lookup
- Create ML for custom model training(available here: https://github.com/stuffeddanny/Produce-CoreML-Model)
- MVVM, SwiftData, VersionedSchemas, ModelContainers, @Model, @Query, @Bindable for flawless data managing
- New Observable framework for more efficient code

## Screenshots

<div>
  <img src="https://github.com/stuffeddanny/GroceryManager/blob/main/Screenshots/main.png?raw=true" alt="App Screenshot" width="250" />
  <img src="https://github.com/stuffeddanny/GroceryManager/blob/main/Screenshots/object_scan.png?raw=true" alt="App Screenshot" width="250" />
  <img src="https://github.com/stuffeddanny/GroceryManager/blob/main/Screenshots/object_scan_popover.png?raw=true" alt="App Screenshot" width="250" />
  <img src="https://github.com/stuffeddanny/GroceryManager/blob/main/Screenshots/barcode_scan.png?raw=true" alt="App Screenshot" width="250" />
  <img src="https://github.com/stuffeddanny/GroceryManager/blob/main/Screenshots/manual_adding.png?raw=true" alt="App Screenshot" width="250" />
  <img src="https://github.com/stuffeddanny/GroceryManager/blob/main/Screenshots/list.png?raw=true" alt="App Screenshot" width="250" />
  <img src="https://github.com/stuffeddanny/GroceryManager/blob/main/Screenshots/object_1.png?raw=true" alt="App Screenshot" width="250" />
  <img src="https://github.com/stuffeddanny/GroceryManager/blob/main/Screenshots/object_2.png?raw=true" alt="App Screenshot" width="250" />
  <img src="https://github.com/stuffeddanny/GroceryManager/blob/main/Screenshots/object_3.png?raw=true" alt="App Screenshot" width="250" />
</div>

## Code snippets

### Setting AVCaptureOutput according to the tool selected

```swift
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
```
### Setting up AVCaptureSession

```swift
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
```
### Detecting barcode

```swift
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
```
### Using ML Model to capture output

```swift
func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard resultCount < 50 else {
        let result = result
        self.result = [:]
        if let mostWanted = result.max(by: { $0.value < $1.value })?.key {
            fire(mostWanted)
        }
        return
    }
    connection.videoRotationAngle = 0
    // Resize the frame to 360 × 360
    // This is the required size of the ML model
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
        return
    }
    
    // Other code for image processing
    ...
    
    if let pixelBuffer = pixelBuffer,
        let output = try? MLModel.prediction(image: pixelBuffer) {
        let sureResults = output.targetProbability.filter({ $0.value > 0.85 })
        isScanning = !sureResults.isEmpty
        
        DispatchQueue.main.async {
            if let result = sureResults.sorted(by: { $0.value > $1.value }).first?.key {
                self.result[result, default: 0] += 1
            }
        }
    }
}
```
### Parsing barcodes

```swift
func parseBarcode(_ value: String) async throws -> BarcodeProduct {
    let headers = [
        "X-RapidAPI-Key": "...",
        "X-RapidAPI-Host": "..."
    ]
    var request = URLRequest(url: URL(string: "https://barcodes-lookup.p.rapidapi.com/?query=\(value)")!)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    let result = try await URLSession.shared.data(for: request)
    let data = result.0
    
    guard let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let product = jsonData["product"] else { throw URLError(.cannotDecodeRawData) }
    
    let productData = try JSONSerialization.data(withJSONObject: product)
    let model = try JSONDecoder().decode(BarcodeProduct.self, from: productData)
    
    return model
}
```

## Lessons Learned
In this project my main goal was to master AVFoundation and ML Model creation.
 
- I trained my very own ML Model for image classification using data I gathered myself
- I managed to set up AVCaptureSession to recognize barcodes and objects, configure AVCaptureDevice
- I used API calls to get data from barcode 
- I implemented custom logic for precise object identification

## 🛠 Skills
Swift, SwiftUI, SwiftData, Observable, CreateML, REST API, AVFoundation, Navigation Flow, MVVM, Async environment, Actors, Multithreading, Git, UX/UI, URLRequests
