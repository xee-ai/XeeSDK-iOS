// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+WebPaywallVariant.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 01.06.2025
//

import Foundation

#if os(iOS)
    import SafariServices
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

public extension Xee {
    nonisolated static func openWebPaywallVariant(
        for product: XeePaywallVariantProduct,
        in presentation: XeeWebPresentation = .externalBrowser
    ) async throws(XeeError) {
        try await withActivatedSDK(
            methodName: .openWebPaywallVariant,
            logParams: [
                "paywall_variant_name": product.paywallVariantName,
                "variation_id": product.variationId,
                "product_id": product.vendorProductId,
                "web_purchase_url": (product as? WebPaywallVariantURLProviding)?.webPaywallVariantBaseUrl,
                "paywall_variant_product_index": product.paywallVariantProductIndex,
                "presentation": presentation.rawValue,
            ]
        ) { sdk throws(XeeError) in
            try await sdk.openWebPaywallVariant(for: product, presentation: presentation)
        }
    }

    nonisolated static func createWebPaywallVariantUrl(
        for product: XeePaywallVariantProduct
    ) async throws(XeeError) -> URL {
        try await withActivatedSDK(
            methodName: .createWebPaywallVariantUrl,
            logParams: [
                "paywall_variant_name": product.paywallVariantName,
                "variation_id": product.variationId,
                "product_id": product.vendorProductId,
                "web_purchase_url": (product as? WebPaywallVariantURLProviding)?.webPaywallVariantBaseUrl,
                "paywall_variant_product_index": product.paywallVariantProductIndex,
                "product_locale": product.localizedPrice,
            ]
        ) { sdk throws(XeeError) in
            try sdk.createWebPaywallVariantUrl(for: product)
        }
    }

    nonisolated static func openWebPaywallVariant(
        for paywallVariant: XeePaywallVariant,
        in presentation: XeeWebPresentation = .externalBrowser
    ) async throws(XeeError) {
        try await withActivatedSDK(
            methodName: .openWebPaywallVariant,
            logParams: [
                "paywall_variant_name": paywallVariant.name,
                "variation_id": paywallVariant.variationId,
                "web_purchase_url": paywallVariant.webPaywallVariantBaseUrl,
                "presentation": presentation.rawValue,
            ]
        ) { sdk throws(XeeError) in
            try await sdk.openWebPaywallVariant(for: paywallVariant, presentation: presentation)
        }
    }

    nonisolated static func createWebPaywallVariantUrl(
        for paywallVariant: XeePaywallVariant
    ) async throws(XeeError) -> URL {
        try await withActivatedSDK(
            methodName: .createWebPaywallVariantUrl,
            logParams: [
                "paywall_variant_name": paywallVariant.name,
                "variation_id": paywallVariant.variationId,
                "web_purchase_url": paywallVariant.webPaywallVariantBaseUrl,
            ]
        ) { sdk throws(XeeError) in
            try sdk.createWebPaywallVariantUrl(for: paywallVariant)
        }
    }

    private func openWebPaywallVariant(
        for product: XeePaywallVariantProduct,
        presentation: XeeWebPresentation
    ) async throws(XeeError) {
        let url = try createWebPaywallVariantUrl(for: product)
        guard await url.open(presentation: presentation) else {
            throw .failedOpeningWebPaywallVariantUrl(url)
        }
        profileStorage.setLastOpenedWebPaywallVariantDate()
    }

    private func openWebPaywallVariant(
        for paywallVariant: XeePaywallVariant,
        presentation: XeeWebPresentation
    ) async throws(XeeError) {
        let url = try createWebPaywallVariantUrl(for: paywallVariant)
        guard await url.open(presentation: presentation) else {
            throw .failedOpeningWebPaywallVariantUrl(url)
        }
        profileStorage.setLastOpenedWebPaywallVariantDate()
    }

    private func createWebPaywallVariantUrl(
        for paywallVariant: XeePaywallVariant
    ) throws(XeeError) -> URL {
        guard let webPaywallVariantBaseUrl = paywallVariant.webPaywallVariantBaseUrl else {
            throw .paywallVariantWithoutPurchaseUrl(paywallVariant: paywallVariant)
        }

        let parameters = [
            "adapty_profile_id": profileStorage.profileId,
            "adapty_variation_id": paywallVariant.variationId,
        ]

        return try webPaywallVariantBaseUrl.appendOrOverwriteQueryParameters(parameters)
    }

    private func createWebPaywallVariantUrl(
        for product: XeePaywallVariantProduct
    ) throws(XeeError) -> URL {
        guard let webPaywallVariantBaseUrl = (product as? WebPaywallVariantURLProviding)?.webPaywallVariantBaseUrl else {
            throw .productWithoutPurchaseUrl(xeeProductId: product.xeeProductId)
        }

        var parameters = [
            "adapty_profile_id": profileStorage.profileId,
            "adapty_variation_id": product.variationId,
            "adapty_product_id": product.xeeProductId,
            "adapty_chosen_product_idx": String(product.paywallVariantProductIndex),
            "adapty_product_locale": product.priceLocale.identifier,
        ]

        if let offer = product.subscriptionOffer {
            parameters["adapty_offer_category"] = offer.offerType.rawValue
            parameters["adapty_offer_type"] = offer.paymentMode.encodedValue ?? "unknown"
            let period = offer.subscriptionPeriod
            parameters["adapty_offer_period_units"] = period.unit.encodedValue
            parameters["adapty_offer_number_of_units"] = String(period.numberOfUnits)
        }

        return try webPaywallVariantBaseUrl.appendOrOverwriteQueryParameters(parameters)
    }
}

extension URL {
    @MainActor
    package func open(presentation: XeeWebPresentation) async -> Bool {
        #if os(iOS)
            switch presentation {
            case .externalBrowser:
                return await UIApplication.shared.open(self, options: [:])
            case .inAppBrowser:
                guard let topViewController = UIApplication.shared.topPresentedController else {
                    return await UIApplication.shared.open(self, options: [:])
                }

                let safariViewController = SFSafariViewController(url: self)
                topViewController.present(safariViewController, animated: true)
                return true
            }
        #elseif os(macOS)
            NSWorkspace.shared.open(self)
            return true
        #endif
    }

    func appendOrOverwriteQueryParameters(
        _ parameters: [String: String]
    ) throws(XeeError) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            throw .failedDecodingWebPaywallVariantUrl(url: self)
        }

        var existingParams = components.queryItems?.reduce(into: [String: String]()) {
            $0[$1.name] = $1.value
        } ?? [:]

        for (key, value) in parameters {
            existingParams[key] = value
        }

        components.queryItems = existingParams.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = components.url else {
            throw .failedDecodingWebPaywallVariantUrl(url: self)
        }
        return url
    }
}
