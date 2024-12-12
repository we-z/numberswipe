//
//  StoreKitManager.swift
//  PO2
//
//  Created by Wheezy Capowdis on 12/11/24.
//

import Foundation
import StoreKit

class StoreKitManager: ObservableObject {
    let productID = "tip"

    // Purchase the product
    func purchase() async throws -> Transaction? {
        // Fetch the product using the productID
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            print("Product not found")
            return nil
        }

        let result = try await product.purchase()

        switch result {
        case let .success(verificationResult):
            switch verificationResult {
            case .verified(let transaction):
                // Deliver the product to the user
                // Always finish the transaction
                await transaction.finish()
                return transaction
            case .unverified:
                // Handle failed verification
                print("Transaction failed verification")
                return nil
            }
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
}

