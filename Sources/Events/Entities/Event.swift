// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Event.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 14.09.2024
//

import Foundation

enum Event: Sendable {
    case appOpened
    case paywallShowed(XeePaywallShowedParameters)
    case paywallVariantAssigned(XeePaywallVariantAssignedParameters)
    case сonsentToCollectingRefundData(XeeConsentToCollectingDataParameters)
    case refundPreference(XeeRefundPreferenceParameters)
    case activity(XeeActivityParameters)
    case system(XeeSystemEventParameters)
}

extension Event {
    var isLowPriority: Bool {
        switch self {
        case .system: true
        default: false
        }
    }
}

extension Event: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Event.CodingKeys.self)
        switch self {
        case .appOpened:
            break
        case let .paywallShowed(value):
            try value.encode(to: encoder)
        case let .paywallVariantAssigned(value):
            try value.encode(to: encoder)
        case let .сonsentToCollectingRefundData(value):
            try value.encode(to: encoder)
        case let .refundPreference(value):
            try value.encode(to: encoder)
        case let .activity(value):
            try value.encode(to: encoder)
        case let .system(value):
            let data = try Event.encoder.encode(value)
            let string = String(decoding: data, as: UTF8.self)
            try container.encode(string, forKey: .customData)
        }
    }
}
