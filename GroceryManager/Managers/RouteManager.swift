//
//  RouteManager.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import SwiftUI
import Observation

/// Route value for navigation path
enum Route: Hashable {
    case list
    case product(_ value: Product)
}

// MARK: Route View
extension Route: View {
    var body: some View {
        switch self {
        case .list: ListView()
        case .product(let product): ProductOverview(for: product).navigationTitle(product.title)
        }
    }
}

// MARK: Route Manager
@Observable final class RouteManager {
    
    /// Navigation path
    var routes = [Route]()
    
    /// Pushing navigation to the `route` only if it's not in path already
    func push(to route: Route) {
        guard !routes.contains(route) else {
            return
        }
        routes.append(route)
    }
    
    /// Resets navigation path to the root and selects home tab
    func reset() {
        routes = []
    }
    
    /// Removes last components from navigation path navigating user to the previous screen
    func back() {
        _ = routes.popLast()
    }
}
