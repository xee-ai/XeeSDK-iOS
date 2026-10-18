// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeOnboardingVariationAssignedParameters.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 14.04.2025.
//

import Foundation

struct XeeOnboardingVariationAssignedParameters: Sendable {
    let variationId: String
    let paywallAudienceVersionId: String
}

extension XeeOnboardingVariationAssignedParameters: Codable {
    enum CodingKeys: String, CodingKey {
        case variationId = "variation_id"
        case paywallAudienceVersionId = "paywall_audience_version_id"
    }
}
