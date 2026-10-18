// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SK2Product.SubscriptionPeriod.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2024
//

import StoreKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
extension SK2Product.SubscriptionPeriod {
    var asXeeSubscriptionPeriod: XeeSubscriptionPeriod {
        .init(unit: unit.asXeeSubscriptionPeriodUnit, numberOfUnits: value)
    }
}
