//  XeePaywallVariantAssignedParameters.swift
//  XeeSDK
//
//  Created by Xee team.
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
