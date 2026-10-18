// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeSubscriptionOffer.PaymentMode.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 20.10.2022.
//

import Foundation

public extension XeeSubscriptionOffer {
    enum PaymentMode: UInt, Sendable {
        case payAsYouGo
        case payUpFront
        case freeTrial
        case unknown
    }
}

extension XeeSubscriptionOffer.PaymentMode {
    private enum CodingValues: String {
        case payAsYouGo = "pay_as_you_go"
        case payUpFront = "pay_up_front"
        case freeTrial = "free_trial"
        case unknown
    }

    package var encodedValue: String? {
        let value: CodingValues? =
            switch self {
            case .payAsYouGo: .payAsYouGo
            case .payUpFront: .payUpFront
            case .freeTrial: .freeTrial
            case .unknown: nil
            }

        return value.map { $0.rawValue }
    }
}

extension XeeSubscriptionOffer.PaymentMode: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(encodedValue ?? CodingValues.unknown.rawValue)
    }
}
