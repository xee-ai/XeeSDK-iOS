// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  StorekitPurchaser.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 06.08.2025.
//

import StoreKit

protocol StorekitPurchaser: Actor, Sendable {
    func makePurchase(
        userId: XeeUserId,
        appAccountToken: UUID?,
        product: XeePaywallVariantProduct
    ) async throws(XeeError) -> XeePurchaseResult
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
extension SK2Purchaser: StorekitPurchaser {}
