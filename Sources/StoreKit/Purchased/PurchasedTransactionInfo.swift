// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  PurchasedTransactionInfo.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 08.09.2022.
//

import Foundation

struct PurchasedTransactionInfo: Sendable {
    let transactionId: String
    let originalTransactionId: String
    let vendorProductId: String
    let price: Decimal?
    let priceLocale: String?
    let storeCountry: String?
    let subscriptionOffer: PurchasedSubscriptionOfferInfo?
    let environment: String

    init(
        product: XeeProduct?,
        transaction: SKTransaction
    ) {
        self.transactionId = transaction.unfIdentifier
        self.originalTransactionId = transaction.unfOriginalIdentifier
        self.vendorProductId = transaction.unfProductId
        self.price = product?.price
        self.priceLocale = product?.priceLocale.unfCurrencyCode
        self.storeCountry = product?.priceLocale.unfRegionCode
        self.subscriptionOffer = .init(transaction: transaction, product: product)
        self.environment = transaction.unfEnvironment
    }
}


