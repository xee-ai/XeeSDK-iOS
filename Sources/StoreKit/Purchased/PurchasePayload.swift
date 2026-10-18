// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  PurchasePayload.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 08.09.2022.
//

import Foundation

struct PurchasePayload: Sendable, Hashable {
    let userId: XeeUserId
    let paywallVariantId: String?
    let persistentPaywallVariantId: String?
    let persistentOnboardingVariationId: String?

    init(
        userId: XeeUserId,
        paywallVariantId: String? = nil,
        persistentPaywallVariantId: String? = nil,
        persistentOnboardingVariationId: String? = nil
    ) {
        self.userId = userId
        self.paywallVariantId = paywallVariantId
        self.persistentPaywallVariantId = persistentPaywallVariantId
        self.persistentOnboardingVariationId = persistentOnboardingVariationId
    }
}

extension PurchasePayload {
    var logParams: EventParameters {
        [
            "user_id": userId,
            "variation_id": paywallVariantId,
            "persited_variation_id": persistentPaywallVariantId,
            "onboarding_variation_id": persistentOnboardingVariationId
        ].removeNil
    }
}

extension PurchasePayload: Codable {
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case paywallVariantId = "paywall_variant_id"
        case persistentPaywallVariantId = "persistent_paywall_variant_id"
        case persistentOnboardingVariationId = "onboarding_variation_id"
    }
}
