//
//  PreviewContainer.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import Foundation
import SwiftData

/// Model container for preview providers
struct PreviewContainer {
    let container: ModelContainer!
    
    /// Initializing with Persistent model types
    init(_ types: [any PersistentModel.Type], isStoredInMemoryOnly: Bool = true) {
        
        let schema = Schema(types)
        let configuration = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
        self.container = try! ModelContainer(for: schema, configurations: [configuration])
    }
    
    /// Initializing with versioned schema
    init(schema: VersionedSchema.Type, isStoredInMemoryOnly: Bool = true) {
        let schema = Schema(versionedSchema: schema)
        let configuration = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
        self.container = try! ModelContainer(for: schema, configurations: [configuration])
    }
    
    /// Adding any Persistent Model to the container
    func add(_ items: [any PersistentModel]) {
        Task { @MainActor in
            items.forEach { container.mainContext.insert($0) }
        }
    }
}
