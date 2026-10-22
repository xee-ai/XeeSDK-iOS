// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  PurchasePayloadStorage.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 25.10.2022
//

import Foundation

private let log = Log.storage

@PurchasePayloadStorage.InternalActor
final class PurchasePayloadStorage {
    @globalActor
    actor InternalActor {
        package static let shared = InternalActor()
    }

    private enum Constants {
        static let deprecatedPaywallVariantsIds = "XeeSDK_Cached_Variations_Ids"
        static let purchasePayloadByProductId = "XeeSDK_Purchase_Payload_By_Product"
        static let purchasePayloadByTransactionId = "XeeSDK_Purchase_Payload_By_Transaction"
        static let persistentPaywallVariantsIds = "XeeSDK_Variations_Ids"
        static let unfinishedTransactionState = "XeeSDK_Unfinished_Transaction_State"
    }

    private static let userDefaults = Storage.userDefaults

    private static var purchasePayloadByProductId: [String: PurchasePayload] = (try? userDefaults.getJSON([String: PurchasePayload].self, forKey: Constants.purchasePayloadByProductId)) ?? [:]

    private static func setPurchasePayload(_ payload: PurchasePayload, forProductId productId: String) -> Bool {
        guard payload != purchasePayloadByProductId.updateValue(payload, forKey: productId) else { return false }
        try? userDefaults.setJSON(purchasePayloadByProductId, forKey: Constants.purchasePayloadByProductId)
        log.debug("Saving variationsIds for paywall")
        return true
    }

    private static func removePurchasePayload(forProductId productId: String) -> Bool {
        guard purchasePayloadByProductId.removeValue(forKey: productId) != nil else { return false }
        try? userDefaults.setJSON(purchasePayloadByProductId, forKey: Constants.purchasePayloadByProductId)
        log.debug("Remove purchase payload for productId = \(productId)")
        return true
    }

    private static var purchasePayloadByTransactionId: [String: PurchasePayload] = (try? userDefaults.getJSON([String: PurchasePayload].self, forKey: Constants.purchasePayloadByTransactionId)) ?? [:]

    private static func setPurchasePayload(_ payload: PurchasePayload, forTransactionId transactionId: String) -> Bool {
        guard payload != purchasePayloadByTransactionId.updateValue(payload, forKey: transactionId) else { return false }
        try? userDefaults.setJSON(purchasePayloadByTransactionId, forKey: Constants.purchasePayloadByTransactionId)
        log.debug("Saving purchase payload for transactionId: \(transactionId)")
        return true
    }

    private static func removePurchasePayload(forTransactionId transactionId: String) -> Bool {
        guard purchasePayloadByTransactionId.removeValue(forKey: transactionId) != nil else { return false }
        try? userDefaults.setJSON(purchasePayloadByTransactionId, forKey: Constants.purchasePayloadByTransactionId)
        log.debug("Remove purchase payload for transactionId = \(transactionId)")
        return true
    }

    private static var persistentPaywallVariantsIds: [String: String] = userDefaults
        .dictionary(forKey: Constants.persistentPaywallVariantsIds) as? [String: String] ?? [:]

    private static func setPersistentPaywallVariantId(_ variationId: String, forProductId productId: String) -> Bool {
        guard variationId != persistentPaywallVariantsIds.updateValue(variationId, forKey: productId) else { return false }
        userDefaults.set(persistentPaywallVariantsIds, forKey: Constants.persistentPaywallVariantsIds)
        return true
    }

    private static var unfinishedTransactionState: [String: Bool] = userDefaults
        .dictionary(forKey: Constants.unfinishedTransactionState) as? [String: Bool] ?? [:]

    private static func setUnfinishedTransactionState(synced: Bool, forTransactionId transactionId: String) -> Bool {
        let changing = unfinishedTransactionState[transactionId].map { !$0 && synced } ?? true
        if changing {
            unfinishedTransactionState[transactionId] = synced
            userDefaults.set(unfinishedTransactionState, forKey: Constants.unfinishedTransactionState)
        }
        log.debug("Saving state (\(synced ? "unsynced" : "synced"))  for transactionId: \(transactionId)")
        return changing
    }

    private static func removeUnfinishedTransactionState(forTransactionId transactionId: String) -> Bool {
        guard unfinishedTransactionState.removeValue(forKey: transactionId) != nil else { return false }
        userDefaults.set(unfinishedTransactionState, forKey: Constants.unfinishedTransactionState)
        log.debug("Remove state for transactionId: \(transactionId)")
        return true
    }

    static func removeAllUnfinishedTransactionState() -> Bool {
        guard !unfinishedTransactionState.isEmpty else { return false }
        unfinishedTransactionState = [:]
        userDefaults.removeObject(forKey: Constants.unfinishedTransactionState)
        log.debug("Remove all states for transaction")
        return true
    }

    static func migration(for userId: XeeUserId) {
        guard userDefaults.object(forKey: Constants.purchasePayloadByProductId) == nil else { return }

        let paywallVariantsIds = userDefaults
            .dictionary(forKey: Constants.deprecatedPaywallVariantsIds) as? [String: String]

        guard let paywallVariantsIds, !paywallVariantsIds.isEmpty else { return }

        let payloads = paywallVariantsIds.mapValues { variationId in
            PurchasePayload(
                userId: userId,
                paywallVariantId: variationId,
                persistentPaywallVariantId: variationId
            )
        }

        do {
            try userDefaults.setJSON(payloads, forKey: Constants.purchasePayloadByProductId)
            userDefaults.removeObject(forKey: Constants.deprecatedPaywallVariantsIds)
            log.info("PurchasePayloadStorage migration done")
        } catch {
            log.info("PurchasePayloadStorage migration failed with error: \(error)")
        }
    }

    static func clear() {
        purchasePayloadByProductId = [:]

        userDefaults.removeObject(forKey: Constants.deprecatedPaywallVariantsIds)
        userDefaults.removeObject(forKey: Constants.persistentPaywallVariantsIds)
        userDefaults.removeObject(forKey: Constants.purchasePayloadByProductId)
        userDefaults.removeObject(forKey: Constants.purchasePayloadByTransactionId)
        userDefaults.removeObject(forKey: Constants.unfinishedTransactionState)

        log.debug("Clear variationsIds for paywallVariants.")
    }
}

extension PurchasePayloadStorage {
    func purchasePayload(byProductId productId: String, orCreateFor userId: XeeUserId) -> PurchasePayload {
        Self.purchasePayloadByProductId[productId] ?? .init(
            userId: userId,
            persistentPaywallVariantId: Self.persistentPaywallVariantsIds[productId]
        )
    }

    func setPaywallVariantId(_ variationId: String, productId: String, userId: XeeUserId) {
        if Self.setPurchasePayload(
            .init(
                userId: userId,
                paywallVariantId: variationId,
                persistentPaywallVariantId: variationId
            ),
            forProductId: productId
        ) {
            Xee.trackSystemEvent(XeeInternalEventParameters(
                eventName: "did_set_variations_ids",
                params: [
                    "payload_by_product": Self.purchasePayloadByProductId,
                ]
            ))
        }

        if Self.setPersistentPaywallVariantId(variationId, forProductId: productId) {
            Xee.trackSystemEvent(XeeInternalEventParameters(
                eventName: "did_set_variations_ids_persistent",
                params: [
                    "variation_by_product": Self.persistentPaywallVariantsIds,
                ]
            ))
        }
    }

    func removePurchasePayload(forProductId productId: String) {
        guard Self.removePurchasePayload(forProductId: productId) else { return }
        Xee.trackSystemEvent(XeeInternalEventParameters(
            eventName: "did_set_variations_ids",
            params: [
                "payload_by_product": Self.purchasePayloadByProductId,
            ]
        ))
    }

    func purchasePayload(byTransaction transaction: SKTransaction, orCreateFor userId: XeeUserId) -> PurchasePayload {
        if let payload = Self.purchasePayloadByTransactionId[transaction.unfIdentifier] {
            return payload
        }

        let payload = purchasePayload(byProductId: transaction.unfProductId, orCreateFor: userId)
        setPurchasePayload(payload, forTransaction: transaction)
        return payload
    }

    func setPurchasePayload(_ payload: PurchasePayload, forTransaction transaction: SKTransaction) {
        if Self.setPurchasePayload(
            payload,
            forTransactionId: transaction.unfIdentifier
        ) {
            Xee.trackSystemEvent(XeeInternalEventParameters(
                eventName: "did_set_variations_ids",
                params: [
                    "payload_by_transaction": Self.purchasePayloadByTransactionId,
                ]
            ))
        }
        removePurchasePayload(forProductId: transaction.unfProductId)
    }

    func removePurchasePayload(forTransaction transaction: SKTransaction) {
        if Self.removePurchasePayload(forTransactionId: transaction.unfIdentifier) {
            Xee.trackSystemEvent(XeeInternalEventParameters(
                eventName: "did_set_variations_ids",
                params: [
                    "payload_by_transaction": Self.purchasePayloadByTransactionId,
                ]
            ))
        }
        removePurchasePayload(forProductId: transaction.unfProductId)
    }

    func unfinishedTransactionIds() -> Set<String> {
        Set(Self.unfinishedTransactionState.keys)
    }

    func isSyncedTransaction(_ transactionId: String) -> Bool {
        Self.unfinishedTransactionState[transactionId] ?? false
    }

    func addUnfinishedTransaction(_ transactionId: String) -> Bool {
        let added = Self.setUnfinishedTransactionState(synced: false, forTransactionId: transactionId)
        if added {
            log.debug("Storage after add state of unfinishedTransaction:\(transactionId) all:\(Self.unfinishedTransactionState)")
            Xee.trackSystemEvent(XeeInternalEventParameters(
                eventName: "did_change_unfinished_transaction",
                params: [
                    "state": Self.unfinishedTransactionState,
                ]
            ))
        }
        return added
    }

    func canFinishSyncedTransaction(_ transactionId: String) -> Bool {
        guard Self.unfinishedTransactionState[transactionId] != nil else { return true }
        if Self.setUnfinishedTransactionState(synced: true, forTransactionId: transactionId) {
            log.debug("Storage after change state of unfinishedTransaction:\(transactionId) all: \(Self.unfinishedTransactionState)")

            Xee.trackSystemEvent(XeeInternalEventParameters(
                eventName: "did_change_unfinished_transaction",
                params: [
                    "state": Self.unfinishedTransactionState,
                ]
            ))
        }
        return false
    }

    func removeUnfinishedTransaction(_ transactionId: String) {
        guard Self.unfinishedTransactionState[transactionId] != nil else { return }
        if Self.removeUnfinishedTransactionState(forTransactionId: transactionId) {
            log.debug("Storage after remove state of unfinishedTransaction:\(transactionId) all: \(Self.unfinishedTransactionState)")
            Xee.trackSystemEvent(XeeInternalEventParameters(
                eventName: "did_change_unfinished_transaction",
                params: [
                    "state": Self.unfinishedTransactionState,
                ]
            ))
        }
    }
}
