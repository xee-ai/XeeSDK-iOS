// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePurchaseResult.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 12.06.2023
//

import StoreKit

public enum XeePurchaseResult: Sendable {
    /// The user cancelled the purchase.
    case userCancelled
    /// The purchase is pending some user action.
    case pending
    /// The purchase succeeded with a `XeeProfile`.
    case success(profile: XeeProfile, transaction: any Sendable)

    @inlinable
    public var isPurchaseCancelled: Bool {
        if case .userCancelled = self {
            true
        } else {
            false
        }
    }

    @inlinable
    public var isPurchasePending: Bool {
        if case .pending = self {
            true
        } else {
            false
        }
    }

    @inlinable
    public var isPurchaseSuccess: Bool {
        if case .success = self {
            true
        } else {
            false
        }
    }

    /// An ``XeeProfile`` which contains the up-to-date inforation about the user.
    @inlinable
    public var profile: XeeProfile? {
        guard case let .success(profile, _) = self else {
            return nil
        }
        return profile
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    public var sk2SignedTransaction: VerificationResult<Transaction>? {
        guard case let .success(_, transaction) = self,
              let result = transaction as? VerificationResult<Transaction>
        else {
            return nil
        }
        return result
    }

    /// A transaction object, which represents the payment.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    public var sk2Transaction: Transaction? {
        sk2SignedTransaction?.unsafePayloadValue
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    public var jwsTransaction: String? {
        sk2SignedTransaction?.jwsRepresentation
    }
}
