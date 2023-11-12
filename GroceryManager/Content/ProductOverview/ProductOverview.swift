//
//  ProductOverview.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import SwiftUI
import SwiftData

struct ProductOverview: View {
    @Bindable var product: Product
    
    init(for product: Product) {
        self.product = product
    }
    
    var body: some View {
        Form {
            Section("General info") {
                TextField("Title", text: $product.title)
                TextField("Description", text: $product.info, axis: .vertical)
                    .lineLimit(nil)
                
                if let brand = product.brand {
                    LabeledContent("Brand:", value: brand)
                }
                
                LabeledContent("Category:") {
                    TextField("Fruits", text: $product.category)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section("Additional") {
                LabeledContent("UPC:") {
                    TextField("UPC", text: $product.barcode)
                        .multilineTextAlignment(.trailing)
                }
                
                if let manufacturer = product.manufacturer {
                    LabeledContent("Manufacturer:", value: manufacturer)
                }
                
                if !product.features.isEmpty {
                    DisclosureGroup("Features") {
                        ForEach(product.features, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                if let ingredients = product.ingredients,
                   !ingredients.isEmpty {
                    DisclosureGroup("Ingredients") {
                        ForEach(ingredients, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                if let attributes = product.attributes,
                   !attributes.isEmpty {
                    DisclosureGroup("Attributes") {
                        ForEach(Array(attributes), id: \.key) {
                            LabeledContent($0.key.capitalized, value: $0.value)
                        }
                    }
                }
                
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    @State var dependencies: Dependencies = Dependencies()
    
    return SwiftDataPreview(preview: PreviewContainer(schema: SchemaV1.self)) {
        Text("")
            .sheet(item: .constant(Product.dummy)) { ProductOverview(for: $0).presentationDetents([.large]).presentationDragIndicator(.hidden) }
    }
    .environment(dependencies)
}
