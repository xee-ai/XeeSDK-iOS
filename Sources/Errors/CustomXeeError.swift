// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  CustomXeeError.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 27.01.2023
//

import StoreKit

package protocol CustomXeeError: CustomStringConvertible, CustomDebugStringConvertible, CustomNSError {
    var originalError: Error? { get }
    var xeeErrorCode: XeeError.ErrorCode { get }
}

extension CustomXeeError {
    var asXeeError: XeeError {
        XeeError(self)
    }
}

extension InternalXeeError: CustomXeeError {}

extension HTTPError: CustomXeeError {
    static let errorDomain = XeeError.HTTPErrorDomain

    var errorCode: Int { xeeErrorCode.rawValue }

    var errorUserInfo: [String: Any] {
        var data: [String: Any] = [
            XeeError.UserInfoKey.description: debugDescription,
            XeeError.UserInfoKey.source: source.description,
            XeeError.UserInfoKey.endpoint: endpoint.description,
        ]
        if let statusCode {
            data[XeeError.UserInfoKey.statusCode] = NSNumber(value: statusCode)
        }
        if let originalError {
            data[NSUnderlyingErrorKey] = originalError as NSError
        }
        return data
    }

    var xeeErrorCode: XeeError.ErrorCode {
        if isCancelled { return .operationInterrupted }
        switch self {
        case .perform: return .encodingFailed
        case .network: return .networkFailed
        case .decoding: return .decodingFailed
        case let .backend(_, _, statusCode, _, _, _):
            return Backend.toXeeErrorCode(statusCode: statusCode) ?? .networkFailed
        }
    }
}

extension EventsError: CustomXeeError {
    static let errorDomain = XeeError.EventsErrorDomain

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

    var xeeErrorCode: XeeError.ErrorCode {
        switch self {
        case .sending: .networkFailed
        case .encoding: .encodingFailed
        case .decoding: .decodingFailed
        }
    }
}

extension StoreKitManagerError: CustomXeeError {
    static let errorDomain = XeeError.SKManagerErrorDomain

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

    var xeeErrorCode: XeeError.ErrorCode {
        if let code = convertErrorCode(skError) { return code }
        return switch self {
        case .interrupted: .operationInterrupted
        case .noProductIDsFound: .noProductIDsFound
        case .requestSKProductsFailed: .productRequestFailed
        case .productPurchaseFailed: .productPurchaseFailed
        case .unknownTransactionId: .unknownTransactionId
        case let .transactionUnverified(_, error):
            if let customError = error as? CustomXeeError {
                customError.xeeErrorCode
            } else {
                .networkFailed
            }
        case .invalidOffer: .invalidOfferIdentifier
        case .getSubscriptionInfoStatusFailed: .fetchSubscriptionStatusFailed
        case .paymentPendingError: .paymentPendingError
        }
    }

    func convertErrorCode(_ error: SKError?) -> XeeError.ErrorCode? {
        guard let error else { return nil }
        return XeeError.ErrorCode(rawValue: error.code.rawValue)
    }
}
