// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywallVariant.ProductReference.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 11.05.2023
//

import Foundation

extension XeePaywallVariant {
    struct ProductReference: Sendable, Hashable {
        let paywallVariantProductIndex: Int
        let xeeProductId: String
        let productInfo: BackendProductInfo
        let promotionalOfferId: String?
        let winBackOfferId: String?
    }
}

extension XeePaywallVariant.ProductReference: CustomStringConvertible {
    public var description: String {
        "(vendorId: \(productInfo.vendorId), xeeProductId: \(xeeProductId), promotionalOfferId: \(promotionalOfferId ?? "nil")))"
    }
}

extension XeePaywallVariant.ProductReference: Encodable {
    enum CodingKeys: String, CodingKey {
        case vendorId = "vendor_product_id"
        case xeeProductId = "adapty_product_id"
        case promotionalOfferEligibility = "promotional_offer_eligibility"
        case promotionalOfferId = "promotional_offer_id"
        case winBackOfferId = "win_back_offer_id"
        case accessLevelId = "access_level_id"
        case backendProductPeriod = "product_type"
    }

    init(from container: KeyedDecodingContainer<CodingKeys>, index: Int) throws {
        self.paywallVariantProductIndex = index
        self.winBackOfferId = try container.decodeIfPresent(String.self, forKey: .winBackOfferId)
        self.xeeProductId = try container.decode(String.self, forKey: .xeeProductId)
        self.productInfo = try BackendProductInfo(
            vendorId: container.decode(String.self, forKey: .vendorId),
            accessLevelId: container.decode(String.self, forKey: .accessLevelId),
            period: container.decode(BackendProductInfo.Period.self, forKey: .backendProductPeriod)
        )
        self.promotionalOfferId =
            if (try? container.decode(Bool.self, forKey: .promotionalOfferEligibility)) ?? true {
                try container.decodeIfPresent(String.self, forKey: .promotionalOfferId)
            } else {
                nil
            }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(productInfo.vendorId, forKey: .vendorId)
        try container.encode(xeeProductId, forKey: .xeeProductId)
        try container.encodeIfPresent(promotionalOfferId, forKey: .promotionalOfferId)
        try container.encodeIfPresent(winBackOfferId, forKey: .winBackOfferId)
        try container.encode(productInfo.accessLevelId, forKey: .accessLevelId)
        try container.encode(productInfo.period, forKey: .backendProductPeriod)
    }
}
