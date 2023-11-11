//
//  CaptureVideodataDelegate.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import UIKit
import AVFoundation
import CoreML

class CaptureVideodataDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var MLModel = try! GroceryClassifier()

    private var result: [String : Int] = [:]

    private var resultCount: Int {
        result.reduce(0) { partialResult, value in
            partialResult + value.value
        }
    }

    let fire: (String) -> Void
    
    init(fire: @escaping (String) -> Void) {
        self.fire = fire
    }

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

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let image = UIImage(ciImage: ciImage)

        UIGraphicsBeginImageContext(CGSize(width: 360, height: 360))
        image.draw(in: CGRect(x: 0, y: 0, width: 360, height: 360))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(resizedImage.size.width), Int(resizedImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(resizedImage.size.width), height: Int(resizedImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        context?.translateBy(x: 0, y: resizedImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context!)
        resizedImage.draw(in: CGRect(x: 0, y: 0, width: resizedImage.size.width, height: resizedImage.size.height))
        UIGraphicsPopContext()

        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        if let pixelBuffer = pixelBuffer,
            let output = try? MLModel.prediction(image: pixelBuffer) {

            DispatchQueue.main.async {
                if let sureResult = output.targetProbability.filter({ $0.value > 0.85 }).sorted(by: { $0.value > $1.value }).first?.key {
                    self.result[sureResult, default: 0] += 1
                }
            }
        }
    }
}
