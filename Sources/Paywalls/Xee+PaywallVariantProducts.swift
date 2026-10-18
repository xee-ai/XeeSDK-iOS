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
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *) {
                if let manager = sdk.productsManager as? SK2ProductsManager {
                    return try await sdk.getSK2PaywallVariantProducts(
                        paywallVariant: paywallVariant,
                        productsManager: manager
                    )
                }
            } else {
                if let manager = sdk.productsManager as? SK1ProductsManager {
                    return try await sdk.getSK1PaywallVariantProducts(
                        paywallVariant: paywallVariant,
                        productsManager: manager
                    )
                }
            }
            return []
        }
    }

    nonisolated static func getPaywallVariantProductsWithoutDeterminingOffer(paywallVariant: XeePaywallVariant) async throws(XeeError) -> [XeePaywallVariantProductWithoutDeterminingOffer] {
        try await withActivatedSDK(
            methodName: .getPaywallVariantProductsWithoutDeterminingOffer,
            logParams: ["paywall_id": paywallVariant.paywall.id]
        ) { sdk throws(XeeError) in
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *) {
                if let manager = sdk.productsManager as? SK2ProductsManager {
                    return try await sdk.getSK2PaywallVariantProductsWithoutOffers(
                        paywallVariant: paywallVariant,
                        productsManager: manager
                    )
                }
            } else {
                if let manager = sdk.productsManager as? SK1ProductsManager {
                    return try await sdk.getSK1PaywallVariantProductsWithoutOffers(
                        paywallVariant: paywallVariant,
                        productsManager: manager
                    )
                }
            }
            return []
        }
    }

    package nonisolated static func getPaywallVariantProduct(
        xeeProductId: String,
        productInfo: BackendProductInfo,
        paywallVariantProductIndex: Int,
        subscriptionOfferIdentifier: XeeSubscriptionOffer.Identifier?,
        variationId: String,
        paywallVariantABTestName: String,
        paywallVariantName: String,
        webPaywallVariantBaseUrl: URL?
    ) async throws(XeeError) -> XeePaywallVariantProduct {
        let sdk = try await Xee.activatedSDK

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *) {
            guard let manager = sdk.productsManager as? SK2ProductsManager else {
                throw .cantMakePayments()
            }
            return try await sdk.getSK2PaywallVariantProduct(
                xeeProductId: xeeProductId,
                productInfo: productInfo,
                paywallVariantProductIndex: paywallVariantProductIndex,
                subscriptionOfferIdentifier: subscriptionOfferIdentifier,
                variationId: variationId,
                paywallVariantABTestName: paywallVariantABTestName,
                paywallVariantName: paywallVariantName,
                webPaywallVariantBaseUrl: webPaywallVariantBaseUrl,
                productsManager: manager
            )

        } else {
            guard let manager = sdk.productsManager as? SK1ProductsManager else {
                throw .cantMakePayments()
            }
            return try await sdk.getSK1PaywallVariantProduct(
                xeeProductId: xeeProductId,
                productInfo: productInfo,
                paywallVariantProductIndex: paywallVariantProductIndex,
                subscriptionOfferIdentifier: subscriptionOfferIdentifier,
                variationId: variationId,
                paywallVariantABTestName: paywallVariantABTestName,
                paywallVariantName: paywallVariantName,
                productsManager: manager,
                webPaywallVariantBaseUrl: webPaywallVariantBaseUrl
            )
        }
    }

    package nonisolated static func persistOnboardingVariationId(
        _ variationId: String
    ) async {
        await Xee.optionalSDK?.purchasePayloadStorage.setOnboardingVariationId(variationId)
    }
}
