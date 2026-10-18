// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SK1Product.SubscriptionPeriod.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2024
//

import StoreKit

extension SK1Product {
    typealias SubscriptionPeriod = SKProductSubscriptionPeriod
}

extension SK1Product.SubscriptionPeriod {
    var asXeeSubscriptionPeriod: XeeSubscriptionPeriod {
        .init(unit: unit.asXeeSubscriptionPeriodUnit, numberOfUnits: numberOfUnits)
    }
}
