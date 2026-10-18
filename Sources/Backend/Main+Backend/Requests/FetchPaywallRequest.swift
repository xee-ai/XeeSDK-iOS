// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  FetchPaywallRequest.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.01.2025.
//

import Foundation

struct FetchPaywallVariantRequest: BackendRequest {
    let endpoint: HTTPEndpoint
    let headers: HTTPHeaders
    let queryItems: QueryItems
    let stamp = Log.stamp

    let requestName = BackendRequestName.fetchPaywallVariant
    let logParams: EventParameters?

    init(
        apiKeyPrefix: String,
        userId: XeeUserId,
        paywallId: String,
        variationId: String,
        locale: XeeLocale,
        disableServerCache: Bool
    ) {
        let md5Hash = "{\"builder_version\":\"\(Xee.uiBuilderVersion)\",\"locale\":\"\(locale.id.lowercased())\",\"store\":\"app_store\"}".md5.hexString

        endpoint = HTTPEndpoint(
            method: .get,
            path: "/sdk/in-apps/\(apiKeyPrefix)/paywall/variations/\(paywallId)/\(md5Hash)/\(variationId)/"
        )

        headers = HTTPHeaders()
            .setPaywallVariantLocale(locale)
            .setUserProfileId(userId)
            .setPaywallVersion(XeePaywallVersions.version(for: paywallId))
            .setPaywallVariantBuilderVersion(Xee.uiBuilderVersion)
            .setPaywallVariantBuilderConfigurationFormatVersion(Xee.uiSchemaVersion)

        queryItems = QueryItems().setDisableServerCache(disableServerCache)

        logParams = [
            "api_prefix": apiKeyPrefix,
            "paywall_id": paywallId,
            "variation_id": variationId,
            "locale": locale,
            "builder_version": Xee.uiBuilderVersion,
            "builder_config_format_version": Xee.uiSchemaVersion,
            "md5": md5Hash,
            "disable_server_cache": disableServerCache,
        ]
    }
}

private struct FetchOnboardingRequest: BackendRequest {
    let endpoint: HTTPEndpoint
    let headers: HTTPHeaders
    let queryItems: QueryItems
    let stamp = Log.stamp

    let requestName = BackendRequestName.fetchOnboarding
    let logParams: EventParameters?

    init(
        apiKeyPrefix: String,
        userId: XeeUserId,
        paywallId: String,
        variationId: String,
        locale: XeeLocale,
        disableServerCache: Bool
    ) {
        let md5Hash = "{\"locale\":\"\(locale.id.lowercased())\"}".md5.hexString

        endpoint = HTTPEndpoint(
            method: .get,
            path: "/sdk/in-apps/\(apiKeyPrefix)/onboarding/variations/\(paywallId)/\(md5Hash)/\(variationId)/"
        )

        headers = HTTPHeaders()
            .setOnboardingLocale(locale)
            .setUserProfileId(userId)
            .setOnboardingUIVersion(XeeOnboarding.ViewConfiguration.uiVersion)

        queryItems = QueryItems().setDisableServerCache(disableServerCache)

        logParams = [
            "api_prefix": apiKeyPrefix,
            "paywall_id": paywallId,
            "variation_id": variationId,
            "locale": locale,
            "md5": md5Hash,
            "disable_server_cache": disableServerCache,
        ]
    }
}

extension Backend.MainExecutor {
    func fetchPaywall<Content: PaywallContent>(
        apiKeyPrefix: String,
        userId: XeeUserId,
        paywallId: String,
        variationId: String,
        locale: XeeLocale,
        cached: Content?,
        disableServerCache: Bool
    ) async throws(HTTPError) -> XeePaywallChosen<Content> {
        let request: BackendRequest =
            if Content.self == XeePaywallVariant.self {
                FetchPaywallVariantRequest(
                    apiKeyPrefix: apiKeyPrefix,
                    userId: userId,
                    paywallId: paywallId,
                    variationId: variationId,
                    locale: locale,
                    disableServerCache: disableServerCache
                )

            } else {
                FetchOnboardingRequest(
                    apiKeyPrefix: apiKeyPrefix,
                    userId: userId,
                    paywallId: paywallId,
                    variationId: variationId,
                    locale: locale,
                    disableServerCache: disableServerCache
                )
            }

        let response = try await perform(request, withDecoder: XeePaywallChosen.createDecoder(
            withUserId: userId,
            withRequestLocale: locale,
            withCached: cached
        ))

        return response.body
    }
}
