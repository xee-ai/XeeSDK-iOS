//  XeePaywallShowedParameters.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

struct XeePaywallShowedParameters: Sendable {
    let variationId: String
    let viewConfigurationId: String?
}

extension XeePaywallShowedParameters: Codable {
    enum CodingKeys: String, CodingKey {
        case variationId = "variation_id"
        case viewConfigurationId = "paywall_variant_builder_id"
    }
}
