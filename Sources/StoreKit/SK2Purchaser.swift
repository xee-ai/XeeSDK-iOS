// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SK2Purchaser.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.10.2024
//

import StoreKit

private let log = Log.sk2TransactionManager

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
actor SK2Purchaser {
    private let transactionSynchronizer: StoreKitTransactionSynchronizer
    private let storage: PurchasePayloadStorage
    private let sk2ProductManager: SK2ProductsManager
    
    private init(
        transactionSynchronizer: StoreKitTransactionSynchronizer,
        storage: PurchasePayloadStorage,
        sk2ProductManager: SK2ProductsManager
    ) {
        self.transactionSynchronizer = transactionSynchronizer
        self.storage = storage
        self.sk2ProductManager = sk2ProductManager
    }
    
    @XeeActor
    private static var isObservingStarted = false
    
    @XeeActor
    static func startObserving(
        transactionSynchronizer: StoreKitTransactionSynchronizer,
        sk2ProductsManager: SK2ProductsManager,
        storage: PurchasePayloadStorage
    ) -> SK2Purchaser? {
        Task {
            for await sk2SignedTransaction in SK2Transaction.updates {
                switch sk2SignedTransaction {
                case let .unverified(sk2Transaction, error):
                    log.error("Transaction \(sk2Transaction.unfIdentifier) (originalId: \(sk2Transaction.unfOriginalIdentifier),  productId: \(sk2Transaction.unfProductId)) is unverified. Error: \(error.localizedDescription)")
                    await sk2Transaction.finish()
                    log.warn("Finish unverified updated transaction: \(sk2Transaction) for product: \(sk2Transaction.unfProductId) error: \(error.localizedDescription)")

                    await storage.removePurchasePayload(forTransaction: sk2Transaction)
                    await storage.removeUnfinishedTransaction(sk2Transaction.unfIdentifier)
                    Xee.trackSystemEvent(XeeAppleRequestParameters(
                        methodName: .finishTransaction,
                        params: sk2Transaction.logParams(other: ["unverified": error.localizedDescription])
                    ))
                case let .verified(sk2Transaction):
                    log.debug("Transaction \(sk2Transaction.unfIdentifier) (originalId: \(sk2Transaction.unfOriginalIdentifier),  productId: \(sk2Transaction.unfProductId), revocationDate:\(sk2Transaction.revocationDate?.description ?? "nil"), expirationDate:\(sk2Transaction.expirationDate?.description ?? "nil") \((sk2Transaction.expirationDate.map { $0 < Date() } ?? false) ? "[expired]" : "") , isUpgraded:\(sk2Transaction.isUpgraded) ) ")

                    Task.detached {
                        await Xee.callDelegate { $0.onUnfinishedTransaction(XeeUnfinishedTransaction(sk2SignedTransaction: sk2SignedTransaction)) }
                        
                        guard !sk2Transaction.isXcodeEnvironment else {
                            log.verbose("Skip sending to backend for Xcode environment transaction \(sk2Transaction.id)")
                            _ = await transactionSynchronizer.recalculateOfflineAccessLevels()
                            await transactionSynchronizer.attemptToFinish(transaction: sk2Transaction, logSource: "updated")
                            return
                        }
                        
                        do {
                            let productOrNil = try? await sk2ProductsManager.fetchProduct(
                                id: sk2Transaction.unfProductId,
                                fetchPolicy: .returnCacheDataElseLoad
                            )
                                
                            try await transactionSynchronizer.report(
                                .init(
                                    product: productOrNil,
                                    transaction: sk2Transaction
                                ),
                                payload: storage.purchasePayload(
                                    byTransaction: sk2Transaction,
                                    orCreateFor: ProfileStorage.userId
                                ),
                                reason: .observing
                            )
                           
                            await transactionSynchronizer.attemptToFinish(transaction: sk2Transaction, logSource: "updated")
                        } catch {
                            _ = await transactionSynchronizer.recalculateOfflineAccessLevels()
                            log.error("Failed to validate transaction: \(sk2Transaction) for product: \(sk2Transaction.unfProductId)")
                        }
                    }
                }
            }
        }
        isObservingStarted = true
        
        return SK2Purchaser(
            transactionSynchronizer: transactionSynchronizer,
            storage: storage,
            sk2ProductManager: sk2ProductsManager
        )
    }
    
    func makePurchase(
        userId: XeeUserId,
        appAccountToken: UUID?,
        product: XeePaywallVariantProduct
    ) async throws(XeeError) -> XeePurchaseResult {
        guard let product = product as? XeeSK2PaywallVariantProduct else {
            throw .cantMakePayments()
        }
        
        var options = Set<Product.PurchaseOption>()
        
        // options.insert(.simulatesAskToBuyInSandbox(true))
        
        if let uuid = appAccountToken {
            options.insert(.appAccountToken(uuid))
        }
        
        if let offer = product.subscriptionOffer {
            switch offer.offerIdentifier {
            case let .promotional(offerId):
                // Promotional offers need a server signature, and Xee does not sign offers.
                throw StoreKitManagerError.invalidOffer("Promotional offers are not supported: offerId:\(offerId) for productId: \(product.vendorProductId)").asXeeError

            case let .winBack(offerId):
                if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *),
                   let winBackOffer = product.skProduct.sk2ProductSubscriptionOffer(by: .winBack(offerId))
                {
                    options.insert(.winBackOffer(winBackOffer))
                } else {
                    throw StoreKitManagerError.invalidOffer("StoreKit2 Not found winBackOfferId:\(offerId) for productId: \(product.vendorProductId)").asXeeError
                }
                
            default:
                break
            }
        }
        
        await sk2ProductManager.storeProductInfo(productInfo: [product.productInfo])
        await storage.setPaywallVariantId(product.variationId, productId: product.vendorProductId, userId: userId)
        let payload = PurchasePayload(
            userId: userId,
            paywallVariantId: product.variationId,
            persistentPaywallVariantId: product.variationId
        )
        return try await makePurchase(product.skProduct, options, payload, for: userId)
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private func makePurchase(
        _ sk2Product: SK2Product,
        _ options: Set<Product.PurchaseOption>,
        _ payload: PurchasePayload,
        for userId: XeeUserId
    ) async throws(XeeError) -> XeePurchaseResult {
        let stamp = Log.stamp
        
        Xee.trackSystemEvent(XeeAppleRequestParameters(
            methodName: .productPurchase,
            stamp: stamp,
            params: [
                "product_id": sk2Product.id,
            ]
        ))
        
        let purchaseResult: Product.PurchaseResult
        do {
            purchaseResult = try await sk2Product.unfPurchase(options: options)
        } catch {
            Xee.trackSystemEvent(XeeAppleResponseParameters(
                methodName: .productPurchase,
                stamp: stamp,
                error: error.localizedDescription
            ))
            log.error("Failed to purchase product: \(sk2Product.id) \(error.localizedDescription)")
            throw StoreKitManagerError.productPurchaseFailed(error).asXeeError
        }
        
        let sk2SignedTransaction: SK2SignedTransaction
        switch purchaseResult {
        case let .success(verificationResult):
            switch verificationResult {
            case let .verified(sk2Transaction):
                Xee.trackSystemEvent(XeeAppleResponseParameters(
                    methodName: .productPurchase,
                    stamp: stamp,
                    params: [
                        "verified": true,
                    ]
                ))
                await storage.setPurchasePayload(payload, forTransaction: sk2Transaction)
                sk2SignedTransaction = verificationResult
            case let .unverified(sk2Transaction, error):
                Xee.trackSystemEvent(XeeAppleResponseParameters(
                    methodName: .productPurchase,
                    stamp: stamp,
                    error: error.localizedDescription
                ))
                
                await sk2Transaction.finish()
                
                log.error("Finish unverified purchase transaction: \(sk2Transaction) of product: \(sk2Transaction.unfProductId) error: \(error.localizedDescription)")
                await storage.removePurchasePayload(forTransaction: sk2Transaction)
                await storage.removeUnfinishedTransaction(sk2Transaction.unfIdentifier)
                Xee.trackSystemEvent(XeeAppleRequestParameters(
                    methodName: .finishTransaction,
                    params: sk2Transaction.logParams(other: ["unverified": error.localizedDescription])
                ))
                throw StoreKitManagerError.transactionUnverified(error).asXeeError
            }
        case .pending:
            Xee.trackSystemEvent(XeeAppleResponseParameters(
                methodName: .productPurchase,
                stamp: stamp,
                params: [
                    "pending": true,
                ]
            ))
            log.info("Pending purchase product: \(sk2Product.id)")
            return .pending
        case .userCancelled:
            Xee.trackSystemEvent(XeeAppleResponseParameters(
                methodName: .productPurchase,
                stamp: stamp,
                params: [
                    "cancelled": true,
                ]
            ))
            log.info("User cancelled purchase product: \(sk2Product.id)")
            return .userCancelled
        @unknown default:
            Xee.trackSystemEvent(XeeAppleResponseParameters(
                methodName: .productPurchase,
                stamp: stamp,
                params: [
                    "unknown": true,
                ]
            ))
            log.error("Unknown purchase result of product: \(sk2Product.id)")
            throw StoreKitManagerError.productPurchaseFailed(nil).asXeeError
        }
        
        let sk2Transaction = sk2SignedTransaction.unsafePayloadValue
        
        await Xee.callDelegate { $0.onUnfinishedTransaction(XeeUnfinishedTransaction(sk2SignedTransaction: sk2SignedTransaction)) }
        
        guard !sk2Transaction.isXcodeEnvironment else {
            log.verbose("Skip validation on backend for Xcode environment transaction \(sk2Transaction.id)")
            await transactionSynchronizer.attemptToFinish(transaction: sk2Transaction, logSource: "purchased")
            let profile = await transactionSynchronizer.recalculateOfflineAccessLevels()
            return .success(profile: profile, transaction: sk2SignedTransaction)
        }
        
        do {
            let profile = try await transactionSynchronizer.validate(
                .init(
                    product: sk2Product.asXeeProduct,
                    transaction: sk2Transaction
                ),
                payload: payload
            )
            await transactionSynchronizer.attemptToFinish(transaction: sk2Transaction, logSource: "purchased")
            return .success(profile: profile, transaction: sk2SignedTransaction)
        } catch {
            log.error("Failed to validate transaction: \(sk2Transaction) for product: \(sk2Product.id)")
            let profile = await transactionSynchronizer.recalculateOfflineAccessLevels()
            return .success(profile: profile, transaction: sk2SignedTransaction)
        }
    }
}
