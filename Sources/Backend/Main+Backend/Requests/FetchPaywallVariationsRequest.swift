// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  FetchPaywallVariationsRequest.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 26.03.2024
//

import Foundation

struct FetchPaywallVariantsRequest: BackendRequest {
    let endpoint: HTTPEndpoint
    let headers: HTTPHeaders
    let queryItems: QueryItems
    let stamp = Log.stamp

    let requestName = BackendRequestName.fetchPaywallVariants
    let logParams: EventParameters?

    init(
        apiKeyPrefix: String,
        userId: XeeUserId,
        paywallId: String,
        locale: XeeLocale,
        segmentId: String,
        crossPaywallEligible: Bool,
        disableServerCache: Bool
    ) {
        let md5Hash = "{\"builder_version\":\"\(Xee.uiBuilderVersion)\",\(crossPaywallEligible ? "\"cross_paywall_eligibility\":true," : "")\"locale\":\"\(locale.id.lowercased())\",\"segment_hash\":\"\(segmentId)\",\"store\":\"app_store\"}".md5.hexString

        endpoint = HTTPEndpoint(
            method: .get,
            path: "/sdk/in-apps/\(apiKeyPrefix)/paywall/variations/\(paywallId)/\(md5Hash)/"
        )

        headers = HTTPHeaders()
            .setPaywallVariantLocale(locale)
            .setUserProfileId(userId)
            .setPaywallVersion(XeePaywallVersions.version(for: paywallId))
            .setPaywallVariantBuilderVersion(Xee.uiBuilderVersion)
            .setPaywallVariantBuilderConfigurationFormatVersion(Xee.uiSchemaVersion)
            .setCrossPaywallEligibility(crossPaywallEligible)
            .setSegmentId(segmentId)

        queryItems = QueryItems().setDisableServerCache(disableServerCache)

        logParams = [
            "api_prefix": apiKeyPrefix,
            "paywall_id": paywallId,
            "locale": locale,
            "segment_id": segmentId,
            "builder_version": Xee.uiBuilderVersion,
            "builder_config_format_version": Xee.uiSchemaVersion,
            "md5": md5Hash,
            "cross_paywall_eligibility": crossPaywallEligible,
            "disable_server_cache": disableServerCache,
        ]
    }
}

private struct FetchOnboardingVariationsRequest: BackendRequest {
    let endpoint: HTTPEndpoint
    let headers: HTTPHeaders
    let queryItems: QueryItems
    let stamp = Log.stamp

    let requestName = BackendRequestName.fetchOnboardingVariations
    let logParams: EventParameters?

    init(
        apiKeyPrefix: String,
        userId: XeeUserId,
        paywallId: String,
        locale: XeeLocale,
        segmentId: String,
        crossPaywallEligible: Bool,
        disableServerCache: Bool
    ) {
        let md5Hash = "{\"cross_paywall_eligibility\":\(crossPaywallEligible ? "true" : "false"),\"locale\":\"\(locale.id.lowercased())\",\"segment_hash\":\"\(segmentId)\"}".md5.hexString

        endpoint = HTTPEndpoint(
            method: .get,
            path: "/sdk/in-apps/\(apiKeyPrefix)/onboarding/variations/\(paywallId)/\(md5Hash)/"
        )

        headers = HTTPHeaders()
            .setOnboardingLocale(locale)
            .setUserProfileId(userId)
            .setOnboardingUIVersion(XeeOnboarding.ViewConfiguration.uiVersion)
            .setCrossPaywallEligibility(crossPaywallEligible)
            .setSegmentId(segmentId)

        queryItems = QueryItems()
            .setDisableServerCache(disableServerCache)

        logParams = [
            "api_prefix": apiKeyPrefix,
            "paywall_id": paywallId,
            "locale": locale,
            "segment_id": segmentId,
            "md5": md5Hash,
            "cross_paywall_eligibility": crossPaywallEligible,
            "disable_server_cache": disableServerCache,
        ]
    }
}

extension Backend.MainExecutor {
    func fetchPaywallVariations<Content: PaywallContent>(
        apiKeyPrefix: String,
        userId: XeeUserId,
        paywallId: String,
        locale: XeeLocale,
        segmentId: String,
        cached: Content?,
        crossPaywallEligible: Bool,
        variationIdResolver: XeePaywallChosen<Content>.VariationIdResolver?,
        disableServerCache: Bool
    ) async throws(HTTPError) -> XeePaywallChosen<Content> {
        let request: BackendRequest =
            if Content.self == XeePaywallVariant.self {
                FetchPaywallVariantsRequest(
                    apiKeyPrefix: apiKeyPrefix,
                    userId: userId,
                    paywallId: paywallId,
                    locale: locale,
                    segmentId: segmentId,
                    crossPaywallEligible: crossPaywallEligible,
                    disableServerCache: disableServerCache
                )

            } else {
                FetchOnboardingVariationsRequest(
                    apiKeyPrefix: apiKeyPrefix,
                    userId: userId,
                    paywallId: paywallId,
                    locale: locale,
                    segmentId: segmentId,
                    crossPaywallEligible: crossPaywallEligible,
                    disableServerCache: disableServerCache
                )
            }

        let response = try await perform(request, withDecoder: XeePaywallChosen.createDecoder(
            withUserId: userId,
            withPaywallId: paywallId,
            withRequestLocale: locale,
            withCached: cached,
            variationIdResolver: variationIdResolver
        ))

        return response.body
    }
}
