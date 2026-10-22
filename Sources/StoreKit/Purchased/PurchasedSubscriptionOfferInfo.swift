// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  PurchasedSubscriptionOfferInfo.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 08.09.2022.
//

import Foundation

struct PurchasedSubscriptionOfferInfo: Sendable {
    let id: String?
    let period: XeeSubscriptionPeriod?
    let paymentMode: XeeSubscriptionOffer.PaymentMode
    let offerType: XeeSubscriptionOfferType
    let price: Decimal?

    fileprivate init(
        identifier: XeeSubscriptionOffer.Identifier,
        period: XeeSubscriptionPeriod? = nil,
        paymentMode: XeeSubscriptionOffer.PaymentMode = .unknown,
        price: Decimal? = nil
    ) {
        self.id = identifier.offerId
        self.period = period
        self.paymentMode = paymentMode
        self.offerType = identifier.offerType
        self.price = price
    }
}

extension PurchasedSubscriptionOfferInfo {
    init?(
        transaction: SKTransaction,
        product: XeeProduct?
    ) {
        if let sk2Transaction = transaction as? SK2Transaction {
            self.init(sk2Transaction: sk2Transaction, sk2Product: product?.sk2Product)
        } else if let sk1Transaction = transaction as? SK1TransactionWithIdentifier {
            self.init(sk1Transaction: sk1Transaction, sk2Product: product?.sk2Product)
        } else {
            return nil
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    private init?(
        sk1Transaction: SK1TransactionWithIdentifier,
        sk2Product: SK2Product?
    ) {
        let offerIdentifier: XeeSubscriptionOffer.Identifier
        let sk2ProductOffer: SK2Product.SubscriptionOffer

        if let offerId = sk1Transaction.unfOfferId {
            offerIdentifier = .promotional(offerId)
            guard let value = sk2Product?.sk2ProductSubscriptionOffer(by: offerIdentifier) else {
                self.init(identifier: offerIdentifier)
                return
            }
            sk2ProductOffer = value
        } else {
            offerIdentifier = .introductory
            guard let value = sk2Product?.sk2ProductSubscriptionOffer(by: offerIdentifier) else {
                return nil
            }
            sk2ProductOffer = value
        }

        self.init(
            identifier: offerIdentifier,
            period: sk2ProductOffer.period.asXeeSubscriptionPeriod,
            paymentMode: sk2ProductOffer.paymentMode.asPaymentMode,
            price: sk2ProductOffer.price
        )
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    init?(
        sk2Transaction: SK2Transaction,
        sk2Product: SK2Product?
    ) {
        guard let offerIdentifier = sk2Transaction.subscriptionOfferIdentifier else { return nil }
        let sk2ProductOffer = sk2Product?.sk2ProductSubscriptionOffer(by: offerIdentifier)
        self.init(
            identifier: offerIdentifier,
            period: sk2ProductOffer?.period.asXeeSubscriptionPeriod,
            paymentMode: sk2ProductOffer?.paymentMode.asPaymentMode ?? .unknown,
            price: sk2ProductOffer?.price,
            for: sk2Transaction
        )
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    private init?(
        identifier: XeeSubscriptionOffer.Identifier,
        period: XeeSubscriptionPeriod?,
        paymentMode: XeeSubscriptionOffer.PaymentMode,
        price: Decimal?,
        for sk2Transaction: SK2Transaction
    ) {
        if #available(iOS 17.2, macOS 14.2, tvOS 17.2, watchOS 10.2, visionOS 1.1, *),
           let offer = sk2Transaction.offer
        {
            self.init(
                identifier: identifier,
                productOfferPeriod: period,
                price: price,
                for: offer
            )
        } else {
            self.init(
                identifier: identifier,
                period: period,
                paymentMode: paymentMode,
                price: price
            )
        }
    }

    @available(iOS 17.2, macOS 14.2, tvOS 17.2, watchOS 10.2, visionOS 1.1, *)
    private init?(
        identifier: XeeSubscriptionOffer.Identifier,
        productOfferPeriod: XeeSubscriptionPeriod?,
        price: Decimal?,
        for sk2TransactionOffer: SK2Transaction.Offer
    ) {
        var period: XeeSubscriptionPeriod?

        #if compiler(>=6.1)
        if #available(iOS 18.4, macOS 15.4, tvOS 18.4, watchOS 11.4, visionOS 2.4, *) {
            period = sk2TransactionOffer.period?.asXeeSubscriptionPeriod
        }
        #else
        period = productOfferPeriod
        #endif

        self.init(
            identifier: sk2TransactionOffer.subscriptionOfferIdentifier ?? identifier,
            period: period ?? productOfferPeriod,
            paymentMode: sk2TransactionOffer.paymentMode?.asPaymentMode ?? .unknown,
            price: price
        )
    }
}
