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
    case barcode(_ value: String)
    case object(_ value: String)
}

// MARK: Route View
extension Route: View {
    var body: some View {
        switch self {
            case .barcode(let value): Text(value)
            case .object(let value): Text(value)
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
