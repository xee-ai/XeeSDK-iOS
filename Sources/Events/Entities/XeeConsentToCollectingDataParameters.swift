//  XeeConsentToCollectingDataParameters.swift
//  XeeSDK
//
//  Created by Xee team.
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
