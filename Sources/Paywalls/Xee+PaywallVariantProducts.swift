// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+PaywallVariantProducts.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.05.2023
//

import Foundation

public extension Xee {
    /// Once you have a ``XeePaywallVariant``, fetch corresponding products array using this method.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - paywall: the ``XeePaywallVariant`` for which you want to get a products
    /// - Returns: A result containing the ``XeePaywallVariantProduct`` objects array. The order will be the same as in the paywall variants object. You can present them in your UI
    /// - Throws: An ``XeeError`` object
    nonisolated static func getPaywallVariantProducts(paywallVariant: XeePaywallVariant) async throws(XeeError) -> [XeePaywallVariantProduct] {
        try await withActivatedSDK(
            methodName: .getPaywallVariantProducts,
            logParams: ["paywall_id": paywallVariant.paywall.id]
        ) { sdk throws(XeeError) in
            guard let manager = sdk.productsManager as? SK2ProductsManager else { return [] }
            return try await sdk.getSK2PaywallVariantProducts(
                paywallVariant: paywallVariant,
                productsManager: manager
            )
        }
    }

    nonisolated static func getPaywallVariantProductsWithoutDeterminingOffer(paywallVariant: XeePaywallVariant) async throws(XeeError) -> [XeePaywallVariantProductWithoutDeterminingOffer] {
        try await withActivatedSDK(
            methodName: .getPaywallVariantProductsWithoutDeterminingOffer,
            logParams: ["paywall_id": paywallVariant.paywall.id]
        ) { sdk throws(XeeError) in
            guard let manager = sdk.productsManager as? SK2ProductsManager else { return [] }
            return try await sdk.getSK2PaywallVariantProductsWithoutOffers(
                paywallVariant: paywallVariant,
                productsManager: manager
            )
        }
    }
}
