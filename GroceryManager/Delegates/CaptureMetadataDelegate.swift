//
//  CaptureMetadataDelegate.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import Foundation
import AVFoundation

class CaptureMetadataDelegate: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    let fire: (String) -> Void
    
    init(fire: @escaping (String) -> Void) {
        self.fire = fire
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let barcodeObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcodeValue = barcodeObject.stringValue else { return }
        
        fire(barcodeValue)
    }
}
