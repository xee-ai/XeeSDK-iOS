// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+ReportTransaction.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 06.10.2024
//

import StoreKit

public extension Xee {
    package nonisolated static func reportTransaction(
        _ transactionId: String,
        withVariationId variationId: String?
    ) async throws(XeeError) {
        let variationId = variationId.trimmed.nonEmptyOrNil
        let transactionId = transactionId.trimmed
        // TODO: throw error if transactionId isEmpty

        return try await withActivatedSDK(methodName: .setVariationId, logParams: [
            "variation_id": variationId,
            "transaction_id": transactionId,
        ]) { sdk throws(XeeError) in
            let userId = sdk.profileStorage.userId
            try await sdk.sendTransactionId(
                transactionId,
                with: variationId,
                for: userId
            )
        }
    }

    private static func _reportTransaction(
        _ transaction: SKTransaction,
        withVariationId variationId: String?
    ) async throws(XeeError) {
        let variationId = variationId.trimmed.nonEmptyOrNil
        try await withActivatedSDK(methodName: .reportSK1Transaction, logParams: [
            "variation_id": variationId,
            "transaction_id": transaction.unfIdentifier,
        ]) { sdk throws(XeeError) in
            let userId = try await sdk.createdProfileManager.userId

            guard !transaction.isXcodeEnvironment else { return }

            let productOrNil = try? await sdk.productsManager.fetchProduct(
                id: transaction.unfProductId,
                fetchPolicy: .returnCacheDataElseLoad
            )

            try await sdk.report(
                .init(
                    product: productOrNil,
                    transaction: transaction
                ),
                payload: .init(
                    userId: userId,
                    paywallVariantId: variationId
                ),
                reason: .setVariation
            )
        }
    }

    /// Link purchased transaction with paywall's variationId.
    ///
    /// In [Observer mode](https://xee.invalid/docs), Xee SDK doesn't know, where the purchase was made from. If you display products using our [Paywall variants](https://xee.invalid/docs) or [A/B Tests](https://xee.invalid/docs), you can manually assign variation to the purchase. After doing this, you'll be able to see metrics in Xee Dashboard.
    ///
    /// - Parameters:
    ///   - transaction: A purchased transaction (note, that this method is suitable only for Store Kit version 1) [SKPaymentTransaction](https://developer.apple.com/documentation/storekit/skpaymenttransaction).
    ///   - withVariationId:  A string identifier of variation. You can get it using variationId property of ``XeePaywallVariant``.
    /// - Throws: An ``XeeError`` object
    nonisolated static func reportTransaction(
        _ transaction: StoreKit.SKPaymentTransaction,
        withVariationId variationId: String? = nil
    ) async throws(XeeError) {
        guard transaction.transactionState == .purchased || transaction.transactionState == .restored,
              let transaction = SK1TransactionWithIdentifier(transaction)
        else {
            throw .wrongParamPurchasedTransaction()
        }

        return try await _reportTransaction(transaction, withVariationId: variationId)
    }

    /// Link purchased transaction with paywall's variationId.
    ///
    /// In [Observer mode](https://xee.invalid/docs), Xee SDK doesn't know, where the purchase was made from. If you display products using our [Paywall variants](https://xee.invalid/docs) or [A/B Tests](https://xee.invalid/docs), you can manually assign variation to the purchase. After doing this, you'll be able to see metrics in Xee Dashboard.
    ///
    /// - Parameters:
    ///   - transaction: A purchased transaction (note, that this method is suitable only for Store Kit version 2) [Transaction](https://developer.apple.com/documentation/storekit/transaction).
    ///   - withVariationId:  A string identifier of variation. You can get it using variationId property of `XeePaywallVariant`.
    /// - Throws: An ``XeeError`` object
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    nonisolated static func reportTransaction(
        _ transaction: StoreKit.Transaction,
        withVariationId variationId: String? = nil
    ) async throws(XeeError) {
        try await _reportTransaction(transaction, withVariationId: variationId)
    }

    /// Link purchased transaction with paywall's variationId.
    ///
    /// In [Observer mode](https://xee.invalid/docs), Xee SDK doesn't know, where the purchase was made from. If you display products using our [Paywall variants](https://xee.invalid/docs) or [A/B Tests](https://xee.invalid/docs), you can manually assign variation to the purchase. After doing this, you'll be able to see metrics in Xee Dashboard.
    ///
    /// - Parameters:
    ///   - transaction: A purchased verification result of transaction (note, that this method is suitable only for Store Kit version 2) [Transaction](https://developer.apple.com/documentation/storekit/verificationresult).
    ///   - withVariationId:  A string identifier of variation. You can get it using variationId property of `XeePaywallVariant`.
    /// - Throws: An ``XeeError`` object
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    nonisolated static func reportTransaction(
        _ transaction: StoreKit.VerificationResult<StoreKit.Transaction>,
        withVariationId variationId: String? = nil
    ) async throws(XeeError) {
        let sk2Transaction: SK2Transaction
        do {
            sk2Transaction = try transaction.payloadValue
        } catch {
            throw StoreKitManagerError.transactionUnverified(error).asXeeError
        }

        return try await _reportTransaction(sk2Transaction, withVariationId: variationId)
    }

    /// Link product purchase result with paywall's variationId.
    ///
    /// In [Observer mode](https://xee.invalid/docs), Xee SDK doesn't know, where the purchase was made from. If you display products using our [Paywall variants](https://xee.invalid/docs) or [A/B Tests](https://xee.invalid/docs), you can manually assign variation to the purchase. After doing this, you'll be able to see metrics in Xee Dashboard.
    ///
    /// - Parameters:
    ///   - purchaseResult: A product purchase result (note, that this method is suitable only for Store Kit version 2) [Product.PurchaseResult](https://developer.apple.com/documentation/storekit/product/purchaseresult).
    ///   - withVariationId:  A string identifier of variation. You can get it using variationId property of `XeePaywallVariant`.
    /// - Throws: An ``XeeError`` object
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    nonisolated static func reportPurchaseResult(
        _ purchaseResult: StoreKit.Product.PurchaseResult,
        withVariationId variationId: String? = nil
    ) async throws(XeeError) {
        switch purchaseResult {
        case let .success(verificationResult):
            try await reportTransaction(verificationResult, withVariationId: variationId)
        case .userCancelled:
            return
        case .pending:
            throw StoreKitManagerError.paymentPendingError().asXeeError
        @unknown default:
            throw StoreKitManagerError.productPurchaseFailed(nil).asXeeError
        }
    }
}
