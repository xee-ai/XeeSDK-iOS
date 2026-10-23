// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+FallbackFile.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 24.09.2022.
//

import Foundation

extension Xee {
    static var fallbackPaywalls: FallbackPaywalls?

    /// To set fallback paywall variants, use this method. You should pass exactly the same payload you're getting from Xee backend. You can copy it from Xee Dashboard.
    ///
    /// Xee allows you to provide fallback paywall variants that will be used when a user opens the app for the first time and there's no internet connection. Or in the rare case when Xee backend is down and there's no cache on the device.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameters:
    ///   - fileURL:
    /// - Throws: An ``XeeError`` object
    public nonisolated static func setFallback(fileURL url: URL) async throws(XeeError) {
        try await withoutSDK(
            methodName: .setFallback
        ) { @XeeActor () throws(XeeError) in
            Xee.fallbackPaywalls = try FallbackPaywalls(fileURL: url)
        }
    }
}

private let log = Log.fallbackPaywalls

extension PaywallStorage {
    private func getPaywall<Content: PaywallContent>(
        byPaywallId paywallId: String,
        withVariationId variationId: String?,
        userId _: XeeUserId,
        locale: XeeLocale
    ) -> XeePaywallChosen<Content>? {
        guard let paywall: Content = getPaywallById(
            paywallId,
            withLocale: locale,
            withVariationId: variationId
        )?.value
        else { return nil }
        return XeePaywallChosen.restore(paywall)
    }

    func getPaywallWithFallback<Content: PaywallContent>(
        byPaywallId paywallId: String,
        withVariationId variationId: String?,
        userId: XeeUserId,
        locale: XeeLocale
    ) -> XeePaywallChosen<Content>? {
        let cachedA: XeePaywallChosen<Content>? = variationId == nil ? nil
            : getPaywall(byPaywallId: paywallId, withVariationId: variationId, userId: userId, locale: locale)

        let cachedB: XeePaywallChosen<Content>? = cachedA != nil ? nil
            : getPaywall(byPaywallId: paywallId, withVariationId: nil, userId: userId, locale: locale)

        let cached = cachedA ?? cachedB

        guard let fallbackFile = Xee.fallbackPaywalls, fallbackFile.contains(paywallId: paywallId) ?? true
        else {
            guard let cached else { return nil }
            Log.crossAB.verbose("return cached paywall content (paywallId: \(paywallId), variationId: \(cached.content.variationId), version: \(cached.content.paywall.version) no-fallback")
            return cached
        }

        switch (cachedA, cachedB) {
        case let (cached?, _):
            if fallbackFile.version > cached.content.paywall.version,
               let fallbacked: XeePaywallChosen<Content> = fallbackFile.getPaywall(
                   byPaywallId: paywallId,
                   withVariationId: variationId,
                   userId: userId,
                   requestLocale: locale
               )
            {
                Log.crossAB.verbose("return from fallback paywall content (paywallId: \(paywallId), variationId: \(fallbacked.content.variationId), version: \(fallbacked.content.paywall.version)) same-variation")
                return fallbacked
            } else {
                Log.crossAB.verbose("return cached paywall content (paywallId: \(paywallId), variationId: \(cached.content.variationId), version: \(cached.content.paywall.version) same-variation")
                return cached
            }

        case let (_, cached?):
            let fallBackedA: XeePaywallChosen<Content>? = variationId == nil ? nil
                : fallbackFile.getPaywall(
                    byPaywallId: paywallId,
                    withVariationId: variationId,
                    userId: userId,
                    requestLocale: locale
                )

            let fallBackedB: XeePaywallChosen<Content>? = (fallBackedA != nil || cached.content.paywall.version >= fallbackFile.version) ? nil
                : fallbackFile.getPaywall(
                    byPaywallId: paywallId,
                    withVariationId: nil,
                    userId: userId,
                    requestLocale: locale
                )

            if let fallBacked = fallBackedA ?? fallBackedB {
                Log.crossAB.verbose("return from fallback paywall content (paywallId: \(paywallId), variationId: \(fallBacked.content.variationId), version: \(fallBacked.content.paywall.version))")

                return fallBacked
            } else {
                Log.crossAB.verbose("return cached paywall content (paywallId: \(paywallId), variationId: \(cached.content.variationId), version: \(cached.content.paywall.version)")
                return cached
            }

        default:
            let fallBacked: XeePaywallChosen<Content>?
            if let variationId {
                fallBacked = fallbackFile.getPaywall(
                    byPaywallId: paywallId,
                    withVariationId: variationId,
                    userId: userId,
                    requestLocale: locale
                ) ?? fallbackFile.getPaywall(
                    byPaywallId: paywallId,
                    withVariationId: nil,
                    userId: userId,
                    requestLocale: locale
                )
            } else {
                fallBacked = fallbackFile.getPaywall(
                    byPaywallId: paywallId,
                    withVariationId: nil,
                    userId: userId,
                    requestLocale: locale
                )
            }

            guard let fallBacked else { return nil }

            Log.crossAB.verbose("return from fallback plqcement content (paywallId: \(paywallId), variationId: \(fallBacked.content.variationId), version: \(fallBacked.content.paywall.version)) no-cache")

            return fallBacked
        }
    }
}
