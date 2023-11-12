//
//  BarcodeProduct.swift
//  GroceryManager
//
//  Created by Daniel on 11/12/23.
//

import Foundation

struct BarcodeProduct: Codable {
    let title: String
    let description: String?
    let brand: String?
    let manufacturer: String?
    
    let category: [String]?
    let features: [String]
    let ingredients: [String]?
    let attributes: [String: String]?
    
    let artist: String?
    let author: String?
    let images: [URL]?

    enum CodingKeys: String, CodingKey {
        case artist, attributes, author
        case brand, category, description, features, images, ingredients, manufacturer
        case title
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.artist = try container.decodeIfPresent(String.self, forKey: .artist)
        self.attributes = try? container.decodeIfPresent([String : String].self, forKey: .attributes)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.brand = try container.decodeIfPresent(String.self, forKey: .brand)
        self.category = try container.decodeIfPresent([String].self, forKey: .category)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.features = try container.decode([String].self, forKey: .features)
        self.images = try container.decodeIfPresent([URL].self, forKey: .images)
        self.ingredients = try container.decodeIfPresent([String].self, forKey: .ingredients)
        self.manufacturer = try container.decodeIfPresent(String.self, forKey: .manufacturer)
        self.title = try container.decode(String.self, forKey: .title)
    }

}
