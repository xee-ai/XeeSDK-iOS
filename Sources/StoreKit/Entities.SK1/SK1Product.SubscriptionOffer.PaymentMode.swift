// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SK1Product.SubscriptionOffer.PaymentMode.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2024
//

import StoreKit

extension SK1Product.SubscriptionOffer.PaymentMode {
    var asPaymentMode: XeeSubscriptionOffer.PaymentMode {
        switch self {
        case .payAsYouGo: .payAsYouGo
        case .payUpFront: .payUpFront
        case .freeTrial: .freeTrial
        @unknown default: .unknown
        }
    }
}
