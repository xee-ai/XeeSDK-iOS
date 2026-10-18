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
    ///   - locale: The identifier of the paywall [localization](https://xee.invalid/docs).
    ///             This parameter is expected to be a language code composed of one or more subtags separated by the "-" character. The first subtag is for the language, the second one is for the region (The support for regions will be added later).
    ///             Example: "en" means English, "en-US" represents US English.
    ///             If the parameter is omitted, the paywall will be returned in the default locale.
    ///   - fetchPolicy: by default SDK will try to load data from server and will return cached data in case of failure. Otherwise use `.returnCacheDataElseLoad` to return cached data if it exists.
    /// - Returns: The ``XeePaywallVariant`` object. This model contains the list of the products ids, paywall's identifier, custom payload, and several other properties.
    /// - Throws: An ``XeeError`` object
    public nonisolated static func getPaywallVariantForDefaultAudience(
        paywallId: String,
        locale: String? = nil,
        fetchPolicy: XeePaywallFetchPolicy = .default
    ) async throws(XeeError) -> XeePaywallVariant {
        let locale = locale.trimmed.nonEmptyOrNil.map { XeeLocale($0) } ?? .defaultPaywallLocale
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

    public nonisolated static func getOnboardingForDefaultAudience(
        paywallId: String,
        locale: String? = nil,
        fetchPolicy: XeePaywallFetchPolicy = .default
    ) async throws(XeeError) -> XeeOnboarding {
        let locale = locale.trimmed.nonEmptyOrNil.map { XeeLocale($0) } ?? .defaultPaywallLocale
        let paywallId = paywallId.trimmed
        // TODO: throw error if paywallId isEmpty

        let logParams: EventParameters = [
            "paywall_id": paywallId,
            "locale": locale,
            "fetch_policy": fetchPolicy,
        ]

        return try await withActivatedSDK(methodName: .getOnboardingForDefaultAudience, logParams: logParams) { sdk throws(XeeError) in
            let onboarding: XeeOnboarding = try await sdk.getPaywallForDefaultAudience(
                paywallId,
                locale,
                fetchPolicy
            )

            return onboarding
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
                orDefaultLocale: true,
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
                    orDefaultLocale: false,
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
                crossPaywallEligible: false,
                variationIdResolver: nil,
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
                locale,
                withCrossPlacmentABTest: false
            ) else {
                throw error.asXeeError
            }
            return content
        }
    }
}
