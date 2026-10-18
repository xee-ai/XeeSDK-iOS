// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywallVariantAssignedParameters.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 07.10.2022.
//

import Foundation

struct XeePaywallVariantAssignedParameters: Sendable {
    let variationId: String
    let viewConfigurationId: String?
    let paywallAudienceVersionId: String
}

extension XeePaywallVariantAssignedParameters: Codable {
    enum CodingKeys: String, CodingKey {
        case variationId = "variation_id"
        case viewConfigurationId = "paywall_variant_builder_id"
        case paywallAudienceVersionId = "paywall_audience_version_id"
    }
}
