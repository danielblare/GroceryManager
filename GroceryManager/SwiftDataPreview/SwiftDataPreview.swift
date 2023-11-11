//
//  SwiftDataPreview.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import SwiftUI
import SwiftData

/// Generates preview taking container and optional items in
struct SwiftDataPreview<T: View>: View {
    private let content: T
    private let preview: PreviewContainer
    private let items: [any PersistentModel]?
    
    init(preview: PreviewContainer, items: [any PersistentModel]? = nil, @ViewBuilder _ content: () -> T) {
        self.preview = preview
        self.items = items
        self.content = content()
    }
    
    
    var body: some View {
        content
            .modelContainer(preview.container)
            .onAppear {
                if let items {
                    preview.add(items)
                }
            }
    }
}
