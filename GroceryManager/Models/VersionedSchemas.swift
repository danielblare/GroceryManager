//
//  VersionedSchemas.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    
    static var models: [any PersistentModel.Type] {
        [Item.self]
    }
    
    static var versionIdentifier: Schema.Version = .init(1, 0, 0)
}
