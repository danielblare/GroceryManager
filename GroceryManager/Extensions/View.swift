//
//  View.swift
//  GroceryManager
//
//  Created by Daniel on 11/12/23.
//

import SwiftUI

struct AlertData: Equatable {
    static func == (lhs: AlertData, rhs: AlertData) -> Bool {
        lhs.title == rhs.title && lhs.message == rhs.message
    }
    
    let title: String
    let message: String
    let additionalButton: Button<Text>?
    let action: (() -> Void)?
    
    init(title: String, message: String, action: (() -> Void)? = nil, additionalButton: Button<Text>? = nil) {
        self.title = title
        self.message = message
        self.additionalButton = additionalButton
        self.action = action
    }
}

extension View {
    
    /// Shows alert when alert data value is present
    func alert(_ alert: Binding<AlertData?>) -> some View {
        self.alert(alert.wrappedValue?.title ?? "", isPresented: .constant(alert.wrappedValue != nil)) {
            Button("OK") {
                alert.wrappedValue?.action?()
                alert.wrappedValue = nil
            }
            
            alert.wrappedValue?.additionalButton
        } message: {
            Text(alert.wrappedValue?.message ?? "")
        }
    }
}
