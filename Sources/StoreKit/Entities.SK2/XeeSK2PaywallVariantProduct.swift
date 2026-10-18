// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeSK2PaywallVariantProduct.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 20.10.2022.
//

import StoreKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
struct XeeSK2PaywallVariantProduct: XeeSK2Product, XeePaywallVariantProduct, WebPaywallVariantURLProviding {
    let skProduct: SK2Product

    public let xeeProductId: String

    let productInfo: BackendProductInfo
    
    public var accessLevelId: String { productInfo.accessLevelId }
    public var xeeProductType: String { productInfo.period.rawValue }

    public let paywallVariantProductIndex: Int

    public let subscriptionOffer: XeeSubscriptionOffer?

    /// Same as `variationId` property of the parent XeePaywallVariant.
    public let variationId: String

    /// Same as `abTestName` property of the parent XeePaywallVariant.
    public let paywallVariantABTestName: String

    /// Same as `name` property of the parent XeePaywallVariant.
    public let paywallVariantName: String

    let webPaywallVariantBaseUrl: URL?

    public var description: String {
        "(xeeProductId: \(xeeProductId), info: \(productInfo), paywallVariantName: \(paywallVariantName), variationId: \(variationId), paywallVariantABTestName: \(paywallVariantABTestName), subscriptionOffer:\(subscriptionOffer.map { $0.description } ?? "nil") , skProduct:\(skProduct)"
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
struct XeeSK2PaywallVariantProductWithoutDeterminingOffer: XeeSK2Product, XeePaywallVariantProductWithoutDeterminingOffer, WebPaywallVariantURLProviding {
    let skProduct: SK2Product

    public let xeeProductId: String

    let productInfo: BackendProductInfo
    public var accessLevelId: String { productInfo.accessLevelId }
    public var xeeProductType: String { productInfo.period.rawValue }

    public let paywallVariantProductIndex: Int

    /// Same as `variationId` property of the parent XeePaywallVariant.
    public let variationId: String

    /// Same as `abTestName` property of the parent XeePaywallVariant.
    public let paywallVariantABTestName: String

    /// Same as `name` property of the parent XeePaywallVariant.
    public let paywallVariantName: String

    let webPaywallVariantBaseUrl: URL?

    public var description: String {
        "(xeeProductId: \(xeeProductId), info: \(productInfo), paywallVariantName: \(paywallVariantName), variationId: \(variationId), paywallVariantABTestName: \(paywallVariantABTestName), skProduct:\(skProduct)"
    }
}
