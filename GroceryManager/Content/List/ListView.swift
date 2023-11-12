//
//  ListView.swift
//  GroceryManager
//
//  Created by Daniel on 11/12/23.
//

import SwiftUI
import SwiftData

struct ListView: View {
    @Environment(\.modelContext) private var context
    
    @Query private var products: [Product]
    
    /// Current category selected for filtering
    @State private var selectedCategory: String?
    
    var body: some View {
        Group {
            if products.isEmpty {
                ContentUnavailableView("List is empty", systemImage: "cart")
            } else {
                List {
                    ForEach(products.filter { if let selectedCategory { $0.category == selectedCategory } else { true } }) { product in
                        NavigationLink(value: Route.product(product)) { rowView(for: product) }
                    }
                    .onDelete {
                        guard let index = $0.first else { return }
                        context.delete(products[index])
                    }
                }
                .toolbar(content: buildToolbar)
            }
        }
        .navigationTitle("List")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// Builds row view for list
    private func rowView(for product: Product) -> some View {
        VStack(alignment: .leading) {
            Text(product.title)
                .font(.title3)
            
            if let brand = product.brand {
                Text(brand)
            }
            
            if !product.category.isEmpty {
                Text(product.category)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    @ToolbarContentBuilder
    private func buildToolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            // Category selector
            Menu {
                
                // Fetching unique categories
                ForEach(getUniqueCategories(), id: \.self) { category in
                    let isSelected = selectedCategory == category
                    Button {
                        selectedCategory = isSelected ? nil : category
                    } label: {
                        HStack {
                            Text(category)
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .symbolVariant(selectedCategory == nil ? .none : .fill)
            }
            
            EditButton()
            
        }
    }
    
    /// Returns unique categories extracted from all items in the list
    private func getUniqueCategories() -> [String] {
        let uniqueSet = Set(products.map({ $0.category })).filter { !$0.isEmpty }
        
        return Array(uniqueSet)
    }
 }

#Preview {
    @State var dependencies: Dependencies = Dependencies()
    
    return SwiftDataPreview(preview: PreviewContainer(schema: SchemaV1.self), items: [Product.dummy]) {
        NavigationStack {
            ListView()
        }
    }
    .environment(dependencies)
}
