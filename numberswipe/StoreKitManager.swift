//
//  StoreKitManager.swift
//  PO2
//
//  Created by Wheezy Capowdis on 12/11/24.
//

import Foundation
import StoreKit

class StoreKitManager: ObservableObject {
    let productID = "tip2"

    // Purchase the product
    func purchase() async throws -> Transaction? {
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
                await transaction.finish()
                return transaction
            case .unverified:
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

