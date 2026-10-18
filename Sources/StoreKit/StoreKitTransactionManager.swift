// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  StoreKitTransactionManager.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 05.10.2024
//

import StoreKit

protocol StoreKitTransactionManager: Actor, Sendable {

    func syncTransactionHistory(for userId: XeeUserId) async throws(XeeError)
    func syncUnfinishedTransactions()  async throws(XeeError)
}

extension StoreKitReceiptManager: StoreKitTransactionManager {
    func syncUnfinishedTransactions()  async throws(XeeError) {}
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
extension SK2TransactionManager: StoreKitTransactionManager {}


