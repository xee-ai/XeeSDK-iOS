// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeOnboarding.ViewConfiguration.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 21.04.2025.
//

import Foundation

package extension XeeOnboarding {
    struct ViewConfiguration: Sendable, Hashable {
        package let url: URL
    }
}

extension XeeOnboarding.ViewConfiguration: Codable {
    enum CodingKeys: String, CodingKey {
        case url = "config_url"
    }
}
