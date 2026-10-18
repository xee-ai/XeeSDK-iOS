// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeConsentToCollectingDataParameters.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 19.03.2025.
//

import Foundation

struct XeeConsentToCollectingDataParameters: Sendable {
    let consent: Bool
}

extension XeeConsentToCollectingDataParameters: Codable {
    enum CodingKeys: String, CodingKey {
        case consent
    }
}
