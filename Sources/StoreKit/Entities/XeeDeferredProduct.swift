// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeDeferredProduct.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 20.10.2022.
//

import StoreKit

public final class XeeDeferredProduct: @unchecked Sendable {
    public var subscriptionOffer: XeeSubscriptionOffer? {
        guard let promotionalOfferId = payment.paymentDiscount?.identifier else { return nil }
        return skProduct.subscriptionOffer(by: .promotional(promotionalOfferId))
    }

    let payment: SKPayment
    let skProduct: SK1Product

    init(sk1Product: SK1Product, payment: SKPayment) {
        self.payment = payment
        self.skProduct = sk1Product
    }
}

extension XeeDeferredProduct: XeeSK1Product {}
