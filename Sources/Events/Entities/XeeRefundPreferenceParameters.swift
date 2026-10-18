// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeRefundPreferenceParameters.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 19.03.2025.
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
