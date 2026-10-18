// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SK2Product.SubscriptionOffer.PaymentMode.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2024
//

import StoreKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
extension SK2Product.SubscriptionOffer.PaymentMode {
    var asPaymentMode: XeeSubscriptionOffer.PaymentMode {
        switch self {
        case .payAsYouGo: .payAsYouGo
        case .payUpFront: .payUpFront
        case .freeTrial: .freeTrial
        default: .unknown
        }
    }
}
