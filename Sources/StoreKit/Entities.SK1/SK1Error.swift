// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SK1Error.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2024
//

import StoreKit

typealias SK1Error = SKError

extension SK1Error {
    @inlinable
    var isPurchaseCancelled: Bool {
        (code == .paymentCancelled) || (code == .overlayCancelled)
    }
}
