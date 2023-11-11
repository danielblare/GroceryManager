//
//  DataContainer.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import Foundation
import SwiftData

actor DataContainer {
    
    /// Creates container
    @MainActor
    static func create() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration()
        let container = try ModelContainer(for: schema, configurations: configuration)
        
        return container
    }
}
