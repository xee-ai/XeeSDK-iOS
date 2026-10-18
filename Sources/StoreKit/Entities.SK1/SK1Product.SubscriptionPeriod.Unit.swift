// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SK1Product.SubscriptionPeriod.Unit.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2024
//

import StoreKit

extension SK1Product.SubscriptionPeriod {
    typealias Unit = SKProduct.PeriodUnit
}

extension SK1Product.SubscriptionPeriod.Unit {
    var asXeeSubscriptionPeriodUnit: XeeSubscriptionPeriod.Unit {
        switch self {
        case .day: .day
        case .week: .week
        case .month: .month
        case .year: .year
        @unknown default: .unknown
        }
    }
}
