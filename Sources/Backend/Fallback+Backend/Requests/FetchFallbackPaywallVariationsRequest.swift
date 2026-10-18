// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  FetchFallbackPaywallVariationsRequest.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 26.03.2024
//

import Foundation

private struct FetchFallbackPaywallVariationsRequest: BackendRequest {
    let endpoint: HTTPEndpoint
    let stamp = Log.stamp
    let queryItems: QueryItems
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

private extension BackendExecutor {
    func performFetchFallbackPaywallVariationsRequest<Content: PaywallContent>(
        apiKeyPrefix: String,
        userId: XeeUserId,
        paywallId: String,
        locale: XeeLocale,
        requestLocale: XeeLocale,
        cached: Content?,
        crossPaywallEligible: Bool,
        variationIdResolver: XeePaywallChosen<Content>.VariationIdResolver?,
        disableServerCache: Bool,
        timeoutInterval: TimeInterval?
    ) async throws(HTTPError) -> XeePaywallChosen<Content> {
        let endpoint: HTTPEndpoint
        let requestName: BackendRequestName
        if Content.self == XeePaywallVariant.self {
            endpoint = HTTPEndpoint(
                method: .get,
                path: "/sdk/in-apps/\(apiKeyPrefix)/paywall/variations/\(paywallId)/app_store/\(locale.languageCode.lowercased())/\(Xee.uiBuilderVersion)/fallback.json"
            )
            requestName = kind == .fallback ? .fetchFallbackPaywallVariants : .fetchPaywallVariantsForDefaultAudience

        } else {
            endpoint = HTTPEndpoint(
                method: .get,
                path: "/sdk/in-apps/\(apiKeyPrefix)/onboarding/variations/\(paywallId)/\(locale.languageCode.lowercased())/fallback.json"
            )
            requestName = kind == .fallback ? .fetchFallbackOnboardingVariations : .fetchOnboardingVariationsForDefaultAudience
        }

        let request = FetchFallbackPaywallVariationsRequest(
            endpoint: endpoint,
            disableServerCache: disableServerCache,
            timeoutInterval: timeoutInterval,
            logName: requestName,
            logParams: [
                "api_prefix": apiKeyPrefix,
                "paywall_id": paywallId,
                "language_code": locale.languageCode,
                "request_locale": requestLocale.id,
                "builder_version": Xee.uiBuilderVersion,
                "builder_config_format_version": Xee.uiSchemaVersion,
                "disable_server_cache": disableServerCache,
            ]
        )

        let startRequestTime = Date()

        do {
            let response = try await perform(request, withDecoder: XeePaywallChosen.createDecoder(
                withUserId: userId,
                withPaywallId: paywallId,
                withRequestLocale: requestLocale,
                withCached: cached,
                variationIdResolver: variationIdResolver
            ))

            return response.body

        } catch {
            guard error.statusCode == 404,
                  !locale.equalLanguageCode(XeeLocale.defaultPaywallLocale)
            else {
                throw error
            }

            return try await performFetchFallbackPaywallVariationsRequest(
                apiKeyPrefix: apiKeyPrefix,
                userId: userId,
                paywallId: paywallId,
                locale: .defaultPaywallLocale,
                requestLocale: requestLocale,
                cached: cached,
                crossPaywallEligible: crossPaywallEligible,
                variationIdResolver: variationIdResolver,
                disableServerCache: disableServerCache,
                timeoutInterval: timeoutInterval?.added(startRequestTime.timeIntervalSinceNow)
            )
        }
    }
}

extension Backend.FallbackExecutor {
    func fetchFallbackPaywallVariations<Content: PaywallContent>(
        apiKeyPrefix: String,
        userId: XeeUserId,
        paywallId: String,
        locale: XeeLocale,
        cached: Content?,
        crossPaywallEligible: Bool,
        variationIdResolver: XeePaywallChosen<Content>.VariationIdResolver?,
        disableServerCache: Bool,
        timeoutInterval: TimeInterval?
    ) async throws(HTTPError) -> XeePaywallChosen<Content> {
        try await performFetchFallbackPaywallVariationsRequest(
            apiKeyPrefix: apiKeyPrefix,
            userId: userId,
            paywallId: paywallId,
            locale: locale,
            requestLocale: locale,
            cached: cached,
            crossPaywallEligible: crossPaywallEligible,
            variationIdResolver: variationIdResolver,
            disableServerCache: disableServerCache,
            timeoutInterval: timeoutInterval
        )
    }
}

extension Backend.ConfigsExecutor {
    func fetchPaywallVariationsForDefaultAudience<Content: PaywallContent>(
        apiKeyPrefix: String,
        userId: XeeUserId,
        paywallId: String,
        locale: XeeLocale,
        cached: Content?,
        crossPaywallEligible: Bool,
        variationIdResolver: XeePaywallChosen<Content>.VariationIdResolver?,
        disableServerCache: Bool,
        timeoutInterval: TimeInterval?
    ) async throws(HTTPError) -> XeePaywallChosen<Content> {
        try await performFetchFallbackPaywallVariationsRequest(
            apiKeyPrefix: apiKeyPrefix,
            userId: userId,
            paywallId: paywallId,
            locale: locale,
            requestLocale: locale,
            cached: cached,
            crossPaywallEligible: crossPaywallEligible,
            variationIdResolver: variationIdResolver,
            disableServerCache: disableServerCache,
            timeoutInterval: timeoutInterval
        )
    }
}
