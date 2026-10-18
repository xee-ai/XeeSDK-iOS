// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywallVariantProduct.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 20.10.2022.
//

import StoreKit

public protocol XeePaywallVariantProductWithoutDeterminingOffer: XeeProduct {
    /// An internal Xee Product Identifier
    var xeeProductId: String { get }

    /// An access level id which was selected in Xee Dashboard for this product, e.g. `premium`
    var accessLevelId: String { get }

    /// A product type which was selected in Xee Dashboard for this product, e.g. `weekly`, `monthly`,  `annual`, etc.
    var xeeProductType: String { get }

    var paywallVariantProductIndex: Int { get }

    /// Same as `variationId` property of the parent XeePaywallVariant.
    var variationId: String { get }

    /// Same as `abTestName` property of the parent XeePaywallVariant.
    var paywallVariantABTestName: String { get }

    /// Same as `name` property of the parent XeePaywallVariant.
    var paywallVariantName: String { get }
}

public protocol XeePaywallVariantProduct: XeePaywallVariantProductWithoutDeterminingOffer {
    var subscriptionOffer: XeeSubscriptionOffer? { get }
}
