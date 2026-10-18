// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  StoreKitManagerError.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 25.10.2022
//

import StoreKit

enum StoreKitManagerError: Error {
    case interrupted(XeeError.Source)
    case noProductIDsFound(XeeError.Source)
    case receiptIsEmpty(XeeError.Source, error: Error?)
    case refreshReceiptFailed(XeeError.Source, error: Error)
    case requestSKProductsFailed(XeeError.Source, error: Error)
    case productPurchaseFailed(XeeError.Source, transactionError: Error?)
    case unknownTransactionId(XeeError.Source)
    case transactionUnverified(XeeError.Source, error: Error?)
    case invalidOffer(XeeError.Source, error: String)
    case getSubscriptionInfoStatusFailed(XeeError.Source, error: Error)
    case paymentPendingError(XeeError.Source)
}

extension StoreKitManagerError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .interrupted(source):
            "StoreKitManagerError.interrupted(\(source))"
        case let .noProductIDsFound(source):
            "StoreKitManagerError.noProductIDsFound(\(source))"
        case let .receiptIsEmpty(source, error):
            if let error {
                "StoreKitManagerError.receiptIsEmpty(\(source), \(error))"
            } else {
                "StoreKitManagerError.receiptIsEmpty(\(source))"
            }
        case let .refreshReceiptFailed(source, error):
            "StoreKitManagerError.refreshReceiptFailed(\(source), \(error))"
        case let .requestSKProductsFailed(source, error):
            "StoreKitManagerError.requestSKProductsFailed(\(source), \(error))"
        case let .productPurchaseFailed(source, error):
            if let error {
                "StoreKitManagerError.productPurchaseFailed(\(source), \(error))"
            } else {
                "StoreKitManagerError.productPurchaseFailed(\(source))"
            }
        case let .unknownTransactionId(source):
            "StoreKitManagerError.unknownTransactionId(\(source))"
        case let .transactionUnverified(source, error):
            if let error {
                "StoreKitManagerError.transactionUnverified(\(source), \(error))"
            } else {
                "StoreKitManagerError.transactionUnverified(\(source))"
            }
        case let .invalidOffer(source, error):
            "StoreKitManagerError.invalidOffer(\(source), \"\(error)\")"
        case let .getSubscriptionInfoStatusFailed(source, error):
            "StoreKitManagerError.getSubscriptionInfoStatusFailed(\(source), \(error))"
        case let .paymentPendingError(source):
            "StoreKitManagerError.paymentPendingError(\(source))"
        }
    }
}

extension StoreKitManagerError {
    var source: XeeError.Source {
        switch self {
        case let .productPurchaseFailed(src, _),
             let .noProductIDsFound(src),
             let .receiptIsEmpty(src, _),
             let .refreshReceiptFailed(src, _),
             let .requestSKProductsFailed(src, _),
             let .interrupted(src),
             let .unknownTransactionId(src),
             let .transactionUnverified(src, _),
             let .invalidOffer(src, _),
             let .getSubscriptionInfoStatusFailed(src, _),
             let .paymentPendingError(src): src
        }
    }

    var originalError: Error? {
        switch self {
        case let .receiptIsEmpty(_, error),
             let .productPurchaseFailed(_, error),
             let .transactionUnverified(_, error): error
        case let .refreshReceiptFailed(_, error),
             let .getSubscriptionInfoStatusFailed(_, error),
             let .requestSKProductsFailed(_, error): error
        default: nil
        }
    }

    var skError: SKError? {
        guard let originalError else { return nil }
        return originalError as? SKError
    }
}

extension StoreKitManagerError {
    static func noProductIDsFound(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .noProductIDsFound(XeeError.Source(file: file, function: function, line: line))
    }

    static func productPurchaseFailed(
        _ error: Error?,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .productPurchaseFailed(XeeError.Source(file: file, function: function, line: line), transactionError: error)
    }

    static func paymentPendingError(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .paymentPendingError(XeeError.Source(file: file, function: function, line: line))
    }

    static func receiptIsEmpty(
        _ error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .receiptIsEmpty(XeeError.Source(file: file, function: function, line: line), error: error)
    }

    static func refreshReceiptFailed(
        _ error: Error,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .refreshReceiptFailed(XeeError.Source(file: file, function: function, line: line), error: error)
    }

    static func requestSK1ProductsFailed(
        _ error: Error,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .requestSKProductsFailed(XeeError.Source(file: file, function: function, line: line), error: error)
    }

    static func requestSK2ProductsFailed(
        _ error: Error,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .requestSKProductsFailed(XeeError.Source(file: file, function: function, line: line), error: error)
    }

    static func requestSK2IsEligibleForIntroOfferFailed(
        _ error: Error,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .requestSKProductsFailed(XeeError.Source(file: file, function: function, line: line), error: error)
    }

    static func interrupted(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .interrupted(XeeError.Source(file: file, function: function, line: line))
    }

    static func unknownTransactionId(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .unknownTransactionId(XeeError.Source(file: file, function: function, line: line))
    }

    static func transactionUnverified(
        _ error: Error,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .transactionUnverified(XeeError.Source(file: file, function: function, line: line), error: error)
    }

    static func invalidOffer(
        _ error: String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .invalidOffer(XeeError.Source(file: file, function: function, line: line), error: error)
    }

    static func getSubscriptionInfoStatusFailed(
        _ error: Error,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        .getSubscriptionInfoStatusFailed(XeeError.Source(file: file, function: function, line: line), error: error)
    }
}
