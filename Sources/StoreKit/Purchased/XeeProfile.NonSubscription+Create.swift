// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeProfile.NonSubscription+Create.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 01.08.2025.
//

//import StoreKit
//
//@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
//extension XeeProfile.NonSubscription {
//    init(
//        sk2Transaction: SK2Transaction
//    ) {
//        self.init(
//            purchaseId: UUID().uuidString,
//            store: "app_store",
//            vendorProductId: sk2Transaction.unfProductID,
//            vendorTransactionId: sk2Transaction.unfIdentifier,
//            purchasedAt: sk2Transaction.purchaseDate,
//            isSandbox: sk2Transaction.isSandbox,
//            isRefund: sk2Transaction.revocationDate != nil,
//            isConsumable: sk2Transaction.productType == .consumable
//        )
//    }
//}
