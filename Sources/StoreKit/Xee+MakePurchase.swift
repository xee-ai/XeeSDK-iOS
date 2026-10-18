// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+MakePurchase.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.05.2023
//

import StoreKit

public extension Xee {
    /// To make the purchase, you have to call this method.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - product: a ``XeePaywallVariantProduct`` object retrieved from the paywall.
    /// - Returns: The ``XeePurchaseResult`` object.
    /// - Throws: An ``XeeError`` object
    nonisolated static func makePurchase(
        product: XeePaywallVariantProduct
    ) async throws(XeeError) -> XeePurchaseResult {
        try await withActivatedSDK(
            methodName: .makePurchase,
            logParams: [
                "paywall_variant_name": product.paywallVariantName,
                "variation_id": product.variationId,
                "product_id": product.vendorProductId,
            ]
        ) { sdk throws(XeeError) in
            guard let purchaser = sdk.purchaser else { throw .cantMakePayments() }
            let userId = sdk.userId ?? sdk.profileStorage.userId
            let appAccountToken = purchaseAccountToken(
                profileToken: sdk.profileStorage.profile?.value.storeAccountToken,
                explicit: sdk.profileStorage.appAccountToken(),
                customerUserId: userId.customerId
            )

            return try await purchaser.makePurchase(
                userId: userId,
                appAccountToken: appAccountToken,
                product: product
            )
        }
    }

    /// To make the purchase, you have to call this method.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - product: a ``XeeDeferredProduct`` object retrieved from the delegate.
    /// - Returns: The ``XeePurchaseResult`` object.
    /// - Throws: An ``XeeError`` object
    nonisolated static func makePurchase(
        product: XeeDeferredProduct
    ) async throws(XeeError) -> XeePurchaseResult {
        try await withActivatedSDK(
            methodName: .makePurchase,
            logParams: [
                "product_id": product.vendorProductId,
            ]
        ) { sdk throws(XeeError) in
            guard let manager = sdk.sk1QueueManager else { throw .cantMakePayments() }
            return try await manager.makePurchase(product: product)
        }
    }

    /// To restore purchases, you have to call this method.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Returns: The ``XeeProfile`` object. This model contains info about access levels, subscriptions, and non-subscription purchases. Generally, you have to check only access level status to determine whether the user has premium access to the app.
    /// - Throws: An ``XeeError`` object
    nonisolated static func restorePurchases() async throws(XeeError) -> XeeProfile {
        try await withActivatedSDK(methodName: .restorePurchases) { sdk throws(XeeError) in
            let manager = try await sdk.createdProfileManager
            try await sdk.syncTransactionHistory(for: manager.userId, forceSync: true)
            return await manager.fetchProfile()
        }
    }
}

extension Xee {
    /// The `appAccountToken` a purchase carries. The server grants access only from Apple's
    /// notifications, matched by this token, so it must be the one the server holds for the profile:
    /// that is the profile's own token, which exists for anonymous users too. Without a profile from
    /// the server yet, the token the app passed, then a customer user ID that is itself a UUID.
    nonisolated static func purchaseAccountToken(profileToken: UUID?, explicit: UUID?, customerUserId: String?) -> UUID? {
        profileToken ?? explicit ?? customerUserId.flatMap(UUID.init(uuidString:))
    }
}
