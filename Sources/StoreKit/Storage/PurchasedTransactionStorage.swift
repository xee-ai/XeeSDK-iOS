// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  PurchasedTransactionStorage.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 25.07.2025.
//

import Foundation

private let log = Log.storage

@PurchasedTransactionStorage.InternalActor
final class PurchasedTransactionStorage {
    @globalActor
    actor InternalActor {
        package static let shared = InternalActor()
    }

    private enum Constants {
        static let transactions = "XeeSDK_Transactions"
    }

    private static let userDefaults = Storage.userDefaults

    static var transactions: [Data]? = userDefaults.object(forKey: Constants.transactions) as? [Data]

    static func setTransactions(_ value: [Data]) {
        userDefaults.set(value, forKey: Constants.transactions)
        transactions = value
        log.debug("Save Transactions success (count:\(value.count))")
    }

    static func clear() {
        userDefaults.removeObject(forKey: Constants.transactions)
        transactions = nil
    }
}
