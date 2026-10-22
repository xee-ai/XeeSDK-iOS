// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+Events.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 24.09.2022.
//

import Foundation

extension Xee {
    @EventsManagerActor
    static let eventsManager = EventsManager()

    @EventsManagerActor
    static func trackEvent(
        _ event: Event,
        for userId: XeeUserId? = nil,
        date: Date = Date()
    ) async throws(XeeError) {
        let userId =
            if let userId {
                userId
            } else {
                await ProfileStorage.userId
            }

        let event = await Event.Unpacked(
            event: event,
            userId: userId,
            environment: Environment.instance,
            createdAt: date
        )
        do {
            try eventsManager.trackEvent(event)
        } catch {
            throw error.asXeeError
        }
    }

    package nonisolated static func trackSystemEvent(
        _ params: XeeSystemEventParameters,
        for userId: XeeUserId? = nil,
        date: Date = Date()
    ) {
        Task.detached(priority: .utility) {
            try? await trackEvent(
                .system(params),
                for: userId,
                date: date
            )
        }
    }

    /// Reports a purchase or a restore and how it ended, for the profile's activity in the dashboard.
    /// It never throws and never waits: the purchase's own result is what the caller gets.
    nonisolated static func trackActivity(
        _ kind: XeeActivityParameters.Kind,
        _ result: XeeActivityParameters.Result,
        productId: String? = nil,
        variationId: String? = nil,
        error: Error? = nil,
        date: Date = Date()
    ) {
        let parameters = XeeActivityParameters(
            kind: kind,
            result: result,
            productId: productId,
            variationId: variationId,
            error: error.map { String(describing: $0).prefix(300).description }
        )
        Task.detached(priority: .utility) {
            try? await trackEvent(.activity(parameters), date: date)
        }
    }

    nonisolated static func trackEventIfNeed(
        _ chosen: XeePaywallChosen<some PaywallContent>,
        date: Date = Date()
    ) {
        guard case let .draw(draw) = chosen else {
            return
        }
        let event: Event
        if let paywallVariant = draw.content as? XeePaywallVariant {
            event = .paywallVariantAssigned(.init(
                variationId: paywallVariant.variationId,
                viewConfigurationId: nil,
                paywallAudienceVersionId: draw.paywallAudienceVersionId
            ))

            Log.crossAB.verbose("-> trackEvent paywallVariantAssigned variationId = \(paywallVariant.variationId)")

        } else {
            Log.crossAB.warn("-> Warnning: unknown content type for variationAssigned event, variationId = \(draw.content.variationId)")
            return
        }

        Task.detached(priority: .utility) {
            try? await trackEvent(
                event,
                for: draw.userId,
                date: date
            )
        }
    }
}

public extension Xee {
    /// Call this method to notify Xee SDK, that particular paywall was shown to user.
    ///
    /// Xee helps you to measure the performance of the paywall variants. We automatically collect all the metrics related to purchases except for paywall views. This is because only you know when the paywall was shown to a customer.
    /// Whenever you show a paywall to your user, call .logShowPaywallVariant(paywall) to log the event, and it will be accumulated in the paywall metrics.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - paywall: A ``XeePaywallVariant`` object.
    ///  - Throws: An ``XeeError`` object
    nonisolated static func logShowPaywallVariant(_ paywallVariant: XeePaywallVariant) async throws(XeeError) {
        let now = Date()
        try await withActivatedSDK(methodName: .logShowPaywallVariant) { _ throws(XeeError) in
            try await trackEvent(
                .paywallShowed(.init(
                    variationId: paywallVariant.variationId,
                    viewConfigurationId: nil
                )),
                date: now
            )
        }
    }

    /// Call this method to update the current user's refund data consent.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - consent: `Bool` value whether user gave the consent or not.
    /// - Throws: An ``XeeError`` object
    nonisolated static func updateCollectingRefundDataConsent(_ consent: Bool) async throws(XeeError) {
        let now = Date()
        try await withActivatedSDK(methodName: .updateCollectingRefundDataConsent) { _ throws(XeeError) in
            try await trackEvent(
                .сonsentToCollectingRefundData(.init(consent: consent)),
                date: now
            )
        }
    }

    /// Call this method to set the refund preference individually for current user.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - refundPreference: ``XeeRefundPreference`` value.
    /// - Throws: An ``XeeError`` object
    nonisolated static func updateRefundPreference(_ refundPreference: XeeRefundPreference) async throws(XeeError) {
        let now = Date()
        try await withActivatedSDK(methodName: .updateRefundPreference) { _ throws(XeeError) in
            try await trackEvent(
                .refundPreference(.init(refundPreference: refundPreference)),
                date: now
            )
        }
    }
}
