//  XeeRefundPreferenceParameters.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

struct XeeRefundPreferenceParameters: Sendable {
    let refundPreference: XeeRefundPreference
}

extension XeeRefundPreferenceParameters: Codable {
    enum CodingKeys: String, CodingKey {
        case refundPreference = "custom_preference"
    }
}
