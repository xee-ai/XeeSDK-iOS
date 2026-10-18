// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeUIOnboardingScreenShowedParameters.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 14.04.2025.
//

import Foundation

package struct XeeUIOnboardingScreenShowedParameters: Sendable {
    package let variationId: String
    package let screenName: String?
    package let screenOrder: String
    package let isLatestScreen: Bool

    package init(
        variationId: String,
        screenName: String?,
        screenOrder: String,
        isLatestScreen: Bool
    ) {
        self.variationId = variationId
        self.screenName = screenName
        self.screenOrder = screenOrder
        self.isLatestScreen = isLatestScreen
    }
}

extension XeeUIOnboardingScreenShowedParameters: Codable {
    enum CodingKeys: String, CodingKey {
        case variationId = "variation_id"
        case screenName = "onboarding_screen_name"
        case screenOrder = "onboarding_screen_order"
        case isLatestScreen = "onboarding_latest_screen"
    }
}
