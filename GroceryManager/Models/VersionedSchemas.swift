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
        [Product.self]
    }
    
    static var versionIdentifier: Schema.Version = .init(1, 0, 0)
}

extension SchemaV1 {
 
    @Model
    class Product {
        var title: String
        var info: String
        let brand: String?
        let manufacturer: String?
        
        var barcode: String
        var category: String
        let features: [String]
        let ingredients: [String]?
        let attributes: [String : String]?

        init(from product: BarcodeProduct, barcode: String) {
            self.title = product.title
            self.barcode = barcode
            self.brand = product.brand
            self.info = product.description ?? ""
            self.category = product.category?.first ?? ""
            self.ingredients = product.ingredients
            self.manufacturer = product.manufacturer
            self.features = product.features
            self.attributes = product.attributes
        }
        
        init(title: String, barcode: String = "", brand: String? = nil, info: String = "", category: String = "", ingredients: [String]? = nil, manufacturer: String? = nil, features: [String] = [], attributes: [String: String] = [:]) {
            self.title = title
            self.barcode = barcode
            self.brand = brand
            self.info = info
            self.category = category
            self.ingredients = ingredients
            self.manufacturer = manufacturer
            self.features = features
            self.attributes = attributes
        }
        
        static var dummy: Product {
            Product(title: "Raspberry", barcode: "94104914991", brand: "Tesco", info: "a Dajidwna wdadj aijndad nawdn aoiwdbab dawbd", category: "Fruit and veg", ingredients: ["Raspberry"], manufacturer: "Kellings", features: ["300g", "300g", "300g"], attributes: ["weight": "300g", "size": "30x30"])
        }
    }
}
