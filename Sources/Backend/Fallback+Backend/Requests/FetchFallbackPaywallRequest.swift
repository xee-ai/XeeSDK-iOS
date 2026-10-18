// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  FetchFallbackPaywallRequest.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.01.2025.
//

import Foundation

private struct FetchFallbackPaywallRequest: BackendRequest {
    let endpoint: HTTPEndpoint
    let queryItems: QueryItems
    let stamp = Log.stamp
    let timeoutInterval: TimeInterval?
    let requestName: BackendRequestName
    let logParams: EventParameters?

    init(
        endpoint: HTTPEndpoint,
        disableServerCache: Bool,
        timeoutInterval: TimeInterval?,
        logName: BackendRequestName,
        logParams: EventParameters
    ) {
        self.timeoutInterval =
            if let timeoutInterval {
                min(max(0.5, timeoutInterval), 60)
            } else {
                nil
            }

        self.endpoint = endpoint
        queryItems = QueryItems().setDisableServerCache(disableServerCache)

        requestName = logName
        self.logParams = logParams
    }
}

extension Backend.FallbackExecutor {
    @inlinable
    func fetchFallbackPaywall<Content: PaywallContent>(
        apiKeyPrefix: String,
        userId: XeeUserId,
        paywallId: String,
        paywallVariantId: String,
        locale: XeeLocale,
        cached: Content?,
        disableServerCache: Bool,
        timeoutInterval: TimeInterval?
    ) async throws(HTTPError) -> XeePaywallChosen<Content> {
        try await _fetchFallbackPaywall(
            apiKeyPrefix,
            userId,
            paywallId,
            paywallVariantId,
            locale: locale,
            locale,
            cached,
            disableServerCache,
            timeoutInterval
        )
    }

    private func _fetchFallbackPaywall<Content: PaywallContent>(
        _ apiKeyPrefix: String,
        _ userId: XeeUserId,
        _ paywallId: String,
        _ paywallVariantId: String,
        locale: XeeLocale,
        _ requestLocale: XeeLocale,
        _ cached: Content?,
        _ disableServerCache: Bool,
        _ timeoutInterval: TimeInterval?
    ) async throws(HTTPError) -> XeePaywallChosen<Content> {
        let endpoint: HTTPEndpoint
        let requestName: BackendRequestName

        if Content.self == XeePaywallVariant.self {
            endpoint = HTTPEndpoint(
                method: .get,
                path: "/sdk/in-apps/\(apiKeyPrefix)/paywall/variations/\(paywallId)/\(paywallVariantId)/app_store/\(locale.languageCode)/\(Xee.uiBuilderVersion)/fallback.json"
            )
            requestName = .fetchFallbackPaywallVariant
        } else {
            endpoint = HTTPEndpoint(
                method: .get,
                path: "/sdk/in-apps/\(apiKeyPrefix)/onboarding/variations/\(paywallId)/\(paywallVariantId)/\(locale.languageCode)/fallback.json"
            )
            requestName = .fetchFallbackPaywallVariant
        }

        let logParams: EventParameters = [
            "api_prefix": apiKeyPrefix,
            "paywall_id": paywallId,
            "variation_id": paywallVariantId,
            "builder_version": Xee.uiBuilderVersion,
            "builder_config_format_version": Xee.uiSchemaVersion,
            "language_code": locale.languageCode,
            "request_locale": requestLocale.id,
            "disable_server_cache": disableServerCache,
        ]

        let request = FetchFallbackPaywallRequest(
            endpoint: endpoint,
            disableServerCache: disableServerCache,
            timeoutInterval: timeoutInterval,
            logName: requestName,
            logParams: logParams
        )

        let startRequestTime = Date()

        do {
            let response = try await perform(request, withDecoder: XeePaywallChosen.createDecoder(
                withUserId: userId,
                withRequestLocale: requestLocale,
                withCached: cached
            ))

            return response.body
        } catch {
            guard error.statusCode == 404,
                  !locale.equalLanguageCode(XeeLocale.defaultPaywallLocale)
            else {
                throw error
            }

            return try await _fetchFallbackPaywall(
                apiKeyPrefix,
                userId,
                paywallId,
                paywallVariantId,
                locale: .defaultPaywallLocale,
                requestLocale,
                cached,
                disableServerCache,
                timeoutInterval?.added(startRequestTime.timeIntervalSinceNow)
            )
        }
    }
}
