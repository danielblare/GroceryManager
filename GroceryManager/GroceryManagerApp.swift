//
//  GroceryManagerApp.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import SwiftUI
import SwiftData
import Observation

typealias Product = SchemaV1.Product

@Observable
final class Dependencies {
    let routeManager: RouteManager

    init() {
        self.routeManager = RouteManager()
    }
}

@main
struct GroceryManagerApp: App {
    
    private let modelContainer: ModelContainer
    
    /// Dependency injection
    @State private var dependencies: Dependencies = Dependencies()

    init() {
        modelContainer = try! DataContainer.create()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Inserting dependencies
        .environment(dependencies)
        // Creating model container
        .modelContainer(modelContainer)
    }
}
