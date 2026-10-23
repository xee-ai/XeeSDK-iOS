// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+PaywallForDefaultAudience.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 12.08.2024
//

import Foundation

extension Xee {
    /// This method enables you to retrieve the paywall from the Default Audience without having to wait for the Xee SDK to send all the user information required for segmentation to the server.
    ///
    /// - Parameters:
    ///   - paywallId: The identifier of the desired paywall. This is the value you specified when you created the paywall in the Xee Dashboard.
    ///   - locale: The language to show the paywall's text in, such as "fr" or "pt-BR". Leave it out: the
    ///             paywall comes in the language the app runs in (`Bundle.main.preferredLocalizations`) when the
    ///             app offers that language in Xee (Settings › Languages), otherwise in the app's source language.
    ///   - fetchPolicy: by default SDK will try to load data from server and will return cached data in case of failure. Otherwise use `.returnCacheDataElseLoad` to return cached data if it exists.
    /// - Returns: The ``XeePaywallVariant`` object. This model contains the list of the products ids, paywall's identifier, custom payload, and several other properties.
    /// - Throws: An ``XeeError`` object
    public nonisolated static func getPaywallVariantForDefaultAudience(
        paywallId: String,
        locale: String? = nil,
        fetchPolicy: XeePaywallFetchPolicy = .default
    ) async throws(XeeError) -> XeePaywallVariant {
        let locale = Xee.requestLocale(locale)
        let paywallId = paywallId.trimmed
        // TODO: throw error if paywallId isEmpty

        let logParams: EventParameters = [
            "paywall_id": paywallId,
            "locale": locale,
            "fetch_policy": fetchPolicy,
        ]

        return try await withActivatedSDK(methodName: .getPaywallVariantForDefaultAudience, logParams: logParams) { sdk throws(XeeError) in
            let paywallVariant: XeePaywallVariant = try await sdk.getPaywallForDefaultAudience(
                paywallId,
                locale,
                fetchPolicy
            )

            return paywallVariant
        }
    }

    private func getPaywallForDefaultAudience<Content: PaywallContent>(
        _ paywallId: String,
        _ locale: XeeLocale,
        _ fetchPolicy: XeePaywallFetchPolicy
    ) async throws(XeeError) -> Content {
        let manager = profileManager
        let userId = manager?.userId ?? profileStorage.userId

        let cached: Content? = manager?
            .paywallStorage
            .getPaywallById(
                paywallId,
                withLocale: locale,
                withVariationId: nil
            )?
            .withFetchPolicy(fetchPolicy)?
            .value

        if let cached { return cached }

        return try await self.fetchPaywallForDefaultAudience(
            userId,
            paywallId,
            locale
        )
    }

    private func fetchPaywallForDefaultAudience<Content: PaywallContent>(
        _ userId: XeeUserId,
        _ paywallId: String,
        _ locale: XeeLocale
    ) async throws(XeeError) -> Content {
        let (cached, isTestUser): (Content?, Bool) = {
            guard let manager = try? profileManager(withProfileId: userId) else { return (nil, false) }
            return (
                manager.paywallStorage.getPaywallById(
                    paywallId,
                    withLocale: locale,
                    withVariationId: nil
                )?.value,
                manager.isTestUser
            )
        }()

        do {
            var chosen: XeePaywallChosen<Content> = try await httpConfigsSession.fetchPaywallVariationsForDefaultAudience(
                apiKeyPrefix: apiKeyPrefix,
                userId: userId,
                paywallId: paywallId,
                locale: locale,
                cached: cached,
                disableServerCache: isTestUser,
                timeoutInterval: nil
            )

            if let manager = try? profileManager(withProfileId: userId) {
                chosen = manager.paywallStorage.savedPaywallChosen(chosen)
            }

            Xee.trackEventIfNeed(chosen)
            return chosen.content

        } catch {
            guard let content: Content = getCacheOrFallbackFilePaywall(
                userId,
                paywallId,
                locale
            ) else {
                throw error.asXeeError
            }
            return content
        }
    }
}
