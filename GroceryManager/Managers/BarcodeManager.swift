//
//  BarcodeManager.swift
//  GroceryManager
//
//  Created by Daniel on 11/11/23.
//

import Foundation

actor BarcodeManager {
    
    /// Fetches barcode information from server
    func parseBarcode(_ value: String) async throws -> BarcodeProduct {
        let headers = [
            "X-RapidAPI-Key": "c66cf5d0b1msh4690ec3aeda3c31p1fcf10jsn892990cad750",
            "X-RapidAPI-Host": "barcodes-lookup.p.rapidapi.com"
        ]

        var request = URLRequest(url: URL(string: "https://barcodes-lookup.p.rapidapi.com/?query=\(value)")!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let result = try await URLSession.shared.data(for: request)
        let data = result.0
        
        guard let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let product = jsonData["product"] else { throw URLError(.cannotDecodeRawData) }
        
        let productData = try JSONSerialization.data(withJSONObject: product)
        let model = try JSONDecoder().decode(BarcodeProduct.self, from: productData)
        
        return model
    }
}
