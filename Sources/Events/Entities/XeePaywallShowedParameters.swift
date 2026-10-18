// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywallShowedParameters.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 07.10.2022.
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
