// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SK1PaymentDiscount.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 01.02.2024
//

import StoreKit

typealias SK1PaymentDiscount = SKPaymentDiscount

extension SK1PaymentDiscount {
    convenience init(offerId: String, signature: XeeSubscriptionOffer.Signature) {
        self.init(
            identifier: offerId,
            keyIdentifier: signature.keyIdentifier,
            nonce: signature.nonce,
            signature: signature.signature.base64EncodedString(),
            timestamp: signature.timestamp as NSNumber
        )
    }
}
