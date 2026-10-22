// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  InternalXeeError.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 30.10.2022.
//

import Foundation
import StoreKit

enum InternalXeeError: Error {
    case unknown(XeeError.Source, String, error: Error)
    case taskCancelled(XeeError.Source)
    case activateOnceError(XeeError.Source)
    case cantMakePayments(XeeError.Source)
    case notAllowedInObserveMode(XeeError.Source)

    case notActivated(XeeError.Source)
    case unidentifiedUserLogout(XeeError.Source)

    case profileWasChanged(XeeError.Source)
    case fetchFailed(XeeError.Source, String, error: Error)
    case decodingFailed(XeeError.Source, String, error: Error)

    case wrongParam(XeeError.Source, String)
}

extension InternalXeeError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .unknown(source, description, error: error):
            "XeeError.unknown(\(source), \(description), \(error))"
        case .taskCancelled:
            "XeeError.taskCancelled(\(source))"
        case let .activateOnceError(source):
            "XeeError.activateOnceError(\(source))"
        case let .unidentifiedUserLogout(source):
            "XeeError.unidentifiedUserLogout(\(source))"
        case let .cantMakePayments(source):
            "XeeError.cantMakePayments(\(source))"
        case let .notAllowedInObserveMode(source):
            "XeeError.notAllowedInObserveMode(\(source))"
        case let .notActivated(source):
            "XeeError.notActivated(\(source))"
        case let .profileWasChanged(source):
            "XeeError.profileWasChanged(\(source))"
        case let .fetchFailed(source, description, error):
            "XeeError.fetchFailed(\(source), \(description), \(error))"
        case let .decodingFailed(source, description, error):
            "XeeError.decodingFailed(\(source), \(description), \(error))"
        case let .wrongParam(source, description):
            "XeeError.wrongParam(\(source), \(description))"
        }
    }
}

extension InternalXeeError {
    var source: XeeError.Source {
        switch self {
        case let .unknown(src, _, _),
             let .taskCancelled(src),
             let .activateOnceError(src),
             let .unidentifiedUserLogout(src),
             let .cantMakePayments(src),
             let .notAllowedInObserveMode(src),
             let .notActivated(src),
             let .profileWasChanged(src),
             let .fetchFailed(src, _, _),
             let .decodingFailed(src, _, _),
             let .wrongParam(src, _):
            src
        }
    }

    var originalError: Error? {
        switch self {
        case let .unknown(_, _, error),
             let .decodingFailed(_, _, error),
             let .fetchFailed(_, _, error):
            error
        default:
            nil
        }
    }
}

extension InternalXeeError: CustomNSError {
    static let errorDomain = XeeError.XeeErrorDomain

    var xeeErrorCode: XeeError.ErrorCode {
        switch self {
        case .unknown: .unknown
        case .taskCancelled: .operationInterrupted
        case .activateOnceError: .activateOnceError
        case .unidentifiedUserLogout: .unidentifiedUserLogout
        case .cantMakePayments: .cantMakePayments
        case .notAllowedInObserveMode: .cantMakePayments
        case .notActivated: .notActivated
        case .profileWasChanged: .profileWasChanged
        case .fetchFailed: .networkFailed
        case .decodingFailed: .decodingFailed
        case .wrongParam: .wrongParam
        }
    }

    var errorCode: Int { xeeErrorCode.rawValue }

    var errorUserInfo: [String: Any] {
        var data: [String: Any] = [
            XeeError.UserInfoKey.description: debugDescription,
            XeeError.UserInfoKey.source: source.description,
        ]

        if let originalError {
            data[NSUnderlyingErrorKey] = originalError as NSError
        }
        return data
    }
}

extension XeeError {
    static func taskCancelled(file: String = #fileID, function: String = #function, line: UInt = #line) -> Self {
        InternalXeeError.taskCancelled(XeeError.Source(file: file, function: function, line: line)).asXeeError
    }

    static func activateOnceError(file: String = #fileID, function: String = #function, line: UInt = #line) -> Self {
        InternalXeeError.activateOnceError(XeeError.Source(file: file, function: function, line: line)).asXeeError
    }

    static func unidentifiedUserLogout(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.unidentifiedUserLogout(XeeError.Source(file: file, function: function, line: line)).asXeeError
    }

    static func cantMakePayments(file: String = #fileID, function: String = #function, line: UInt = #line) -> Self {
        InternalXeeError.cantMakePayments(XeeError.Source(file: file, function: function, line: line)).asXeeError
    }

    static func notAllowedInObserveMode(file: String = #fileID, function: String = #function, line: UInt = #line) -> Self {
        InternalXeeError.notAllowedInObserveMode(XeeError.Source(file: file, function: function, line: line)).asXeeError
    }

    static func notActivated(file: String = #fileID, function: String = #function, line: UInt = #line) -> Self {
        InternalXeeError.notActivated(XeeError.Source(file: file, function: function, line: line)).asXeeError
    }

    static func profileWasChanged(file: String = #fileID, function: String = #function, line: UInt = #line) -> Self {
        InternalXeeError.profileWasChanged(XeeError.Source(file: file, function: function, line: line)).asXeeError
    }

    static func decodingFallback(
        _ error: Error,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.decodingFailed(XeeError.Source(file: file, function: function, line: line), "Decoding Fallback PaywallVariants failed", error: error).asXeeError
    }

    static func isNotFileUrl(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.wrongParam(
            XeeError.Source(file: file, function: function, line: line), "Is not file URL"
        ).asXeeError
    }

    static func wrongVersionFallback(
        _ text: String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.wrongParam(XeeError.Source(file: file, function: function, line: line), text).asXeeError
    }

    static func decodingViewConfiguration(
        _ error: Error,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.decodingFailed(XeeError.Source(file: file, function: function, line: line), "Decoding ViewConfiguration failed", error: error).asXeeError
    }

    static func wrongParamPurchasedTransaction(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.wrongParam(XeeError.Source(file: file, function: function, line: line), "Transaction is not in \"purchased\" state").asXeeError
    }

    static func wrongKeyOfCustomAttribute(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.wrongParam(XeeError.Source(file: file, function: function, line: line), "The key must be string not more than 30 characters. Only letters, numbers, dashes, points and underscores allowed").asXeeError
    }

    static func wrongStringValueOfCustomAttribute(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.wrongParam(XeeError.Source(file: file, function: function, line: line), "The value must not be empty and not more than 50 characters.").asXeeError
    }

    static func wrongCountCustomAttributes(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.wrongParam(XeeError.Source(file: file, function: function, line: line), "The total number of custom attributes must be no more than 30").asXeeError
    }

    static func wrongAttributeData(
        _ error: Error,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.wrongParam(XeeError.Source(file: file, function: function, line: line), error.localizedDescription).asXeeError
    }

    static func isNoViewConfigurationInPaywallVariant(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.wrongParam(XeeError.Source(file: file, function: function, line: line), "XeePaywallVariant.viewConfiguration is nil").asXeeError
    }

    static func paywallVariantWithoutPurchaseUrl(
        paywallVariant: XeePaywallVariant,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.wrongParam(XeeError.Source(file: file, function: function, line: line), "Current method is not available for the paywall (paywallId: \(paywallVariant.paywall.id), name: \(paywallVariant.name), variationId: \(paywallVariant.variationId))").asXeeError
    }

    static func productWithoutPurchaseUrl(
        xeeProductId: String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.wrongParam(XeeError.Source(file: file, function: function, line: line), "Current method is not available for the product:\(xeeProductId)").asXeeError
    }

    static func unknown(
        _ error: Error,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        InternalXeeError.unknown(XeeError.Source(file: file, function: function, line: line), "Unexpected error", error: error).asXeeError
    }
}
