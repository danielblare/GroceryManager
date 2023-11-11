//
//  ScanTool.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import SwiftUI

enum ScanTool: CaseIterable {
    case object
    case barcode
    
    var icon: String {
        switch self {
        case .object: "camera.viewfinder"
        case .barcode: "barcode.viewfinder"
        }
    }        
}
