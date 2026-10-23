// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeSystemEventParameters.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 29.03.2023
//

import Foundation

package protocol XeeSystemEventParameters: Sendable, Encodable {}

private enum CodingKeys: String, CodingKey {
    case name = "event_name"
    case stamp = "sdk_flow_id"
    case requestData = "request_data"
    case responseData = "response_data"
    case eventData = "event_data"

    case backendRequestId = "api_request_id"
    case success
    case error
    case metrics
    case headers
}

typealias EventParameters = [String: (any Sendable & Encodable)?]

extension EventParameters {
    var removeNil: EventParameters {
        var result: EventParameters = [:]
        for (key, value) in self {
            guard let value else { continue }
            result[key] = value
        }
        return result
    }
}

private extension Encoder {
    func encode(_ params: EventParameters?) throws {
        guard let params else { return }
        var container = container(keyedBy: AnyCodingKeys.self)
        try params.forEach {
            guard let value = $1 else { return }
            try container.encode(value, forKey: AnyCodingKeys(stringValue: $0))
        }
    }
}

struct XeeBackendAPIRequestParameters: XeeSystemEventParameters {
    let name: BackendRequestName
    let stamp: String
    let params: EventParameters?

    init(requestName: BackendRequestName, requestStamp: String, params: EventParameters? = nil) {
        self.name = requestName
        self.stamp = requestStamp
        self.params = params
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("api_request_\(name.rawValue)", forKey: .name)
        try container.encode(stamp, forKey: .stamp)
        try encoder.encode(params)
    }
}

struct XeeBackendAPIResponseParameters: XeeSystemEventParameters {
    let name: BackendRequestName
    let stamp: String
    let backendRequestId: String?
    let metrics: HTTPMetrics?
    let error: String?
    let headers: HTTPHeaders?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("api_response_\(name)", forKey: .name)
        try container.encode(stamp, forKey: .stamp)
        try container.encodeIfPresent(backendRequestId, forKey: .backendRequestId)
        try container.encodeIfPresent(metrics, forKey: .metrics)
        try container.encodeIfPresent(headers, forKey: .headers)

        if let error {
            try container.encode(false, forKey: .success)
            try container.encode(error, forKey: .error)
        } else {
            try container.encode(true, forKey: .success)
        }
    }

    init(requestName: BackendRequestName, requestStamp: String, _ error: Error) {
        let httpError = error as? HTTPError
        self.name = requestName
        self.stamp = requestStamp
        self.backendRequestId = httpError?.headers?.getBackendRequestId()
        self.metrics = httpError?.metrics
        self.headers = httpError?.headers?.filtered
        self.error = httpError?.description ?? error.localizedDescription
    }

    init(requestName: BackendRequestName, requestStamp: String, _ response: HTTPResponse<some Sendable>) {
        self.name = requestName
        self.stamp = requestStamp
        self.backendRequestId = response.headers.getBackendRequestId()
        self.metrics = response.metrics
        self.headers = response.headers.filtered
        self.error = nil
    }
}

private extension HTTPHeaders {
    private enum Suffix {
        static let cacheStatus = "cache-status"
    }

    var filtered: HTTPHeaders? {
        let filtered = filter { $0.key.lowercased().hasSuffix(Suffix.cacheStatus) }
        return filtered.nonEmptyOrNil
    }
}

enum MethodName: String {
    case activate
    case identify
    case logout

    case getProfile = "get_profile"
    case updateProfile = "update_profile"
    case updateAttribution = "update_attribution"
    case updateAttributionData = "update_attribution_data"

    case setVariationId = "set_variation_id"
    case manualFinishTransaction = "manual_finish_transaction"

    case reportSK1Transaction = "report_transaction_sk1"
    case reportSK2Transaction = "report_transaction_sk2"
    case getPaywallVariantProducts = "get_paywall_variant_products"
    case getPaywallVariantProductsWithoutDeterminingOffer = "get_paywall_variant_products_without_determining_offer"
    case makePurchase = "make_purchase"
    case getUnfinishedTransactions = "get_unfinished_transactions"

    case getCurrentInstallationStatus = "get_current_installation_status"
    case restorePurchases = "restore_purchases"

    case getPaywallVariant = "get_paywall"

    case getPaywallVariantForDefaultAudience = "get_paywall_variant_for_default_audience"

    case setFallback = "set_fallback_file"

    case logShowPaywallVariant = "log_show_paywall"

    case logShowView = "log_show_view"

    case presentCodeRedemptionSheet = "present_code_redemption_sheet"

    case updateCollectingRefundDataConsent = "update_collecting_refund_data_consent"
    case updateRefundPreference = "update_refund_preference"
}

struct XeeSDKMethodRequestParameters: XeeSystemEventParameters {
    let name: MethodName
    let stamp: String
    let params: EventParameters?

    init(methodName: MethodName, stamp: String, params: EventParameters? = nil) {
        self.name = methodName
        self.stamp = stamp
        self.params = params
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("sdk_request_\(name)", forKey: .name)
        try container.encode(stamp, forKey: .stamp)
        try encoder.encode(params)
    }
}

struct XeeSDKMethodResponseParameters: XeeSystemEventParameters {
    let name: MethodName
    let stamp: String?
    let params: EventParameters?
    let error: String?

    init(methodName: MethodName, stamp: String? = nil, params: EventParameters? = nil, error: String? = nil) {
        self.name = methodName
        self.stamp = stamp
        self.params = params
        self.error = error
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("sdk_response_\(name)", forKey: .name)
        try container.encodeIfPresent(stamp, forKey: .stamp)
        if let error {
            try container.encode(false, forKey: .success)
            try container.encode(error, forKey: .error)
        } else {
            try container.encode(true, forKey: .success)
        }
        try encoder.encode(params)
    }
}

enum AppleMethodName: String {
    case fetchASAToken = "fetch_ASA_Token"
    case fetchSK2Products = "fetch_sk2_products"

    case getAllSK2Transactions = "get_all_sk2_transactions"
    case getSK2CurrentEntitlements = "get_sk2_current_entitlements"
    case getUnfinishedSK2Transactions = "get_unfinished_sk2_transactions"


    case finishTransaction = "finish_transaction"
    case addPayment = "add_payment"
    case productPurchase = "product_purchase"

    case subscriptionInfoStatus = "subscription_info_status"
    case isEligibleForIntroOffer = "is_eligible_for_intro_offer"
}

struct XeeAppleRequestParameters: XeeSystemEventParameters {
    let name: AppleMethodName
    let stamp: String?
    let params: EventParameters?

    init(methodName: AppleMethodName, stamp: String? = nil, params: EventParameters? = nil) {
        self.name = methodName
        self.stamp = stamp
        self.params = params
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("apple_request_\(name)", forKey: .name)
        try container.encodeIfPresent(stamp, forKey: .stamp)
        try encoder.encode(params)
    }
}

struct XeeAppleResponseParameters: XeeSystemEventParameters {
    let name: AppleMethodName
    let stamp: String?
    let params: EventParameters?
    let error: String?

    init(methodName: AppleMethodName, stamp: String? = nil, params: EventParameters? = nil, error: String? = nil) {
        self.name = methodName
        self.stamp = stamp
        self.params = params
        self.error = error
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("apple_response_\(name)", forKey: .name)
        try container.encodeIfPresent(stamp, forKey: .stamp)
        try encoder.encode(params)
        if let error {
            try container.encode(false, forKey: .success)
            try container.encode(error, forKey: .error)
        } else {
            try container.encode(true, forKey: .success)
        }
    }
}

struct XeeAppleEventQueueHandlerParameters: XeeSystemEventParameters {
    let eventName: String
    let stamp: String?
    let params: EventParameters?
    let error: String?

    init(eventName: String, stamp: String? = nil, params: EventParameters? = nil, error: String? = nil) {
        self.eventName = eventName
        self.stamp = stamp
        self.params = params
        self.error = error
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("apple_event_\(eventName)", forKey: .name)
        try container.encodeIfPresent(stamp, forKey: .stamp)
        try encoder.encode(params)
        if let error {
            try container.encode(error, forKey: .error)
        }
    }
}

struct XeeInternalEventParameters: XeeSystemEventParameters {
    let eventName: String
    let params: EventParameters?
    let error: String?

    init(eventName: String, params: EventParameters? = nil, error: String? = nil) {
        self.eventName = eventName
        self.params = params
        self.error = error
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("internal_\(eventName)", forKey: .name)
        try encoder.encode(params)
        if let error {
            try container.encode(error, forKey: .error)
        }
    }
}
