// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SK1PaywallVariantProducts.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.05.2023
//

import Foundation

private let log = Log.sk1ProductManager

extension Xee {
    func getSK1PaywallVariantProductsWithoutOffers(
        paywallVariant: XeePaywallVariant,
        productsManager: SK1ProductsManager
    ) async throws(XeeError) -> [XeePaywallVariantProductWithoutDeterminingOffer] {
        try await productsManager.fetchSK1ProductsInSameOrder(
            ids: paywallVariant.vendorProductIds,
            fetchPolicy: .returnCacheDataElseLoad
        )
        .compactMap { sk1Product in
            let vendorId = sk1Product.productIdentifier

            guard let reference = paywallVariant.products.first(where: { $0.productInfo.vendorId == vendorId }) else {
                return nil
            }

            return XeeSK1PaywallVariantProductWithoutDeterminingOffer(
                skProduct: sk1Product,
                xeeProductId: reference.xeeProductId,
                productInfo: reference.productInfo,
                paywallVariantProductIndex: reference.paywallVariantProductIndex,
                variationId: paywallVariant.variationId,
                paywallVariantABTestName: paywallVariant.paywall.abTestName,
                paywallVariantName: paywallVariant.name,
                webPaywallVariantBaseUrl: paywallVariant.webPaywallVariantBaseUrl
            )
        }
    }

    func getSK1PaywallVariantProduct(
        xeeProductId: String,
        productInfo: BackendProductInfo,
        paywallVariantProductIndex: Int,
        subscriptionOfferIdentifier: XeeSubscriptionOffer.Identifier?,
        variationId: String,
        paywallVariantABTestName: String,
        paywallVariantName: String,
        productsManager: SK1ProductsManager,
        webPaywallVariantBaseUrl: URL?
    ) async throws(XeeError) -> XeeSK1PaywallVariantProduct {
        let sk1Product = try await productsManager.fetchSK1Product(id: productInfo.vendorId, fetchPolicy: .returnCacheDataElseLoad)

        let subscriptionOffer: XeeSubscriptionOffer? =
            if let subscriptionOfferIdentifier {
                if let offer = sk1Product.subscriptionOffer(by: subscriptionOfferIdentifier) {
                    offer
                } else {
                    throw StoreKitManagerError.invalidOffer("StoreKit1 product don't have offer id: `\(subscriptionOfferIdentifier.offerId ?? "nil")` with type:\(subscriptionOfferIdentifier.offerType.rawValue) ").asXeeError
                }
            } else {
                nil
            }

        return XeeSK1PaywallVariantProduct(
            skProduct: sk1Product,
            xeeProductId: xeeProductId,
            productInfo: productInfo,
            paywallVariantProductIndex: paywallVariantProductIndex,
            subscriptionOffer: subscriptionOffer,
            variationId: variationId,
            paywallVariantABTestName: paywallVariantABTestName,
            paywallVariantName: paywallVariantName,
            webPaywallVariantBaseUrl: webPaywallVariantBaseUrl
        )
    }

    func getSK1PaywallVariantProducts(
        paywallVariant: XeePaywallVariant,
        productsManager: SK1ProductsManager
    ) async throws(XeeError) -> [XeePaywallVariantProduct] {
        typealias ProductTuple = (
            product: SK1Product,
            reference: XeePaywallVariant.ProductReference,
            offer: XeeSubscriptionOffer?,
            determinedOffer: Bool
        )

        let sk1Products = try await productsManager.fetchSK1ProductsInSameOrder(
            ids: paywallVariant.vendorProductIds,
            fetchPolicy: .returnCacheDataElseLoad
        )

        var products: [ProductTuple] = sk1Products.compactMap { sk1Product in
            let vendorId = sk1Product.productIdentifier
            guard let reference = paywallVariant.products.first(where: { $0.productInfo.vendorId == vendorId }) else {
                return nil
            }

            let (offer, determinedOffer): (XeeSubscriptionOffer?, Bool) =
                if let promotionalOffer = promotionalOffer(reference.promotionalOfferId, sk1Product) {
                    (promotionalOffer, true)
                } else if sk1Product.introductoryOfferNotApplicable {
                    (nil, true)
                } else {
                    (nil, false)
                }

            return (product: sk1Product, reference: reference, offer: offer, determinedOffer: determinedOffer)
        }

        let vendorProductIds: [String] = products.compactMap {
            guard !$0.determinedOffer else { return nil }
            return $0.product.productIdentifier
        }

        if vendorProductIds.isNotEmpty {
            let introductoryOfferEligibility = await getIntroductoryOfferEligibility(vendorProductIds: vendorProductIds)
            products = products.map {
                guard !$0.determinedOffer else { return $0 }
                return if let introductoryOffer = $0.product.subscriptionOffer(by: .introductory),
                          introductoryOfferEligibility.contains($0.product.productIdentifier)
                {
                    (product: $0.product, reference: $0.reference, offer: introductoryOffer, determinedOffer: true)
                } else {
                    (product: $0.product, reference: $0.reference, offer: nil, determinedOffer: true)
                }
            }
        }

        return products.map {
            XeeSK1PaywallVariantProduct(
                skProduct: $0.product,
                xeeProductId: $0.reference.xeeProductId,
                productInfo: $0.reference.productInfo,
                paywallVariantProductIndex: $0.reference.paywallVariantProductIndex,
                subscriptionOffer: $0.offer,
                variationId: paywallVariant.variationId,
                paywallVariantABTestName: paywallVariant.paywall.abTestName,
                paywallVariantName: paywallVariant.name,
                webPaywallVariantBaseUrl: paywallVariant.webPaywallVariantBaseUrl
            )
        }
    }

    private func promotionalOffer(_ offerId: String?, _ sk1Product: SK1Product) -> XeeSubscriptionOffer? {
        guard let offerId else { return nil }
        guard let offer = sk1Product.subscriptionOffer(by: .promotional(offerId)) else {
            log.warn("no promotional offer found with id:\(offerId) in productId:\(sk1Product.productIdentifier)")
            return nil
        }
        return offer
    }

    private func getProfileState() -> (userId: XeeUserId, ineligibleProductIds: Set<String>)? {
        guard let manager = profileManager else { return nil }

        return (
            manager.userId,
            manager.backendIntroductoryOfferEligibilityStorage.getIneligibleProductIds()
        )
    }

    private func getIntroductoryOfferEligibility(vendorProductIds: [String]) async -> [String] {
        guard let (userId, ineligibleProductIds) = getProfileState() else { return [] }

        let vendorProductIds = vendorProductIds.filter { !ineligibleProductIds.contains($0) }
        guard vendorProductIds.isNotEmpty else { return [] }

        do {
            try await syncTransactionHistory(for: userId)
        } catch {
            return []
        }

        let lastResponse = try? profileManager(withProfileId: userId)?
            .backendIntroductoryOfferEligibilityStorage
            .getLastResponse()

        do {
            let response = try
                await httpSession.fetchIntroductoryOfferEligibility(
                    userId: userId,
                    responseHash: lastResponse?.hash
                )

            if let manager = try? profileManager(withProfileId: userId) {
                return manager.backendIntroductoryOfferEligibilityStorage.save(response)
            } else {
                return response.value.filter(\.value).map(\.vendorId)
            }

        } catch {
            return []
        }
    }
}
