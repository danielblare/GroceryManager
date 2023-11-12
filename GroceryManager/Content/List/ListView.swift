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
    @State private var selectedCategory: String?
    
    var body: some View {
        Group {
            if products.isEmpty {
                ContentUnavailableView("List is empty", systemImage: "cart")
            } else {
                List {
                    ForEach(products.filter { if let selectedCategory { $0.category == selectedCategory } else { true } }) { product in
                        NavigationLink(value: Route.product(product)) {
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
                    }
                    .onDelete {
                        guard let index = $0.first else { return }
                        context.delete(products[index])
                    }
                }
                .toolbar { 
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Menu {
                            ForEach(Array(Set(products.map({ $0.category }))), id: \.self) { category in
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
            }
        }
        .navigationTitle("List")
        .navigationBarTitleDisplayMode(.inline)
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
