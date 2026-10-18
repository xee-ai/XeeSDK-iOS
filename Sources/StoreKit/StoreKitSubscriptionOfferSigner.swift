// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  StoreKitSubscriptionOfferSigner.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 14.08.2025.
//

import Foundation

protocol StoreKitSubscriptionOfferSigner: AnyObject, Sendable {
    func sign(
        offerId: String,
        subscriptionVendorId: String,
        for userId: XeeUserId,
        with appAccountToken: UUID?
    ) async throws(XeeError) -> XeeSubscriptionOffer.Signature
}

extension Xee: StoreKitSubscriptionOfferSigner {
    func sign(
        offerId: String,
        subscriptionVendorId: String,
        for userId: XeeUserId,
        with appAccountToken: UUID?
    ) async throws(XeeError) -> XeeSubscriptionOffer.Signature {
        do {
            let response = try await httpSession.signSubscriptionOffer(
                userId: userId,
                vendorProductId: subscriptionVendorId,
                offerId: offerId,
                appAccountToken: appAccountToken
            )
            return response
        } catch {
            throw error.asXeeError
        }
    }
}
