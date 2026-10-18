// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  BackendRequest.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 11.11.2025.
//

protocol BackendRequest: Sendable, HTTPRequest {
    var stamp: String { get }
    var requestName: BackendRequestName { get }
    var logParams: EventParameters? { get }
}

extension BackendRequest {
    var logParams: EventParameters? { nil }
}

protocol BackendEncodableRequest: BackendRequest, HTTPEncodableRequest {}

enum BackendRequestName: String {
    case fetchProductStates = "get_products"
    case createProfile = "create_profile"
    case fetchProfile = "get_profile"
    case updateProfile = "update_profile"
    case fetchPaywallVariants = "get_paywall_variants"
    case fetchOnboardingVariations = "get_onboarding_variations"
    case fetchFallbackPaywallVariants = "get_fallback_paywall_variants"
    case fetchFallbackOnboardingVariations = "get_fallback_onboarding_variations"
    case fetchPaywallVariantsForDefaultAudience = "get_paywall_variants_for_default_audience"
    case fetchOnboardingVariationsForDefaultAudience = "get_onboarding_variations_for_default_audience"

    case fetchUISchema = "get_paywall_variant_builder"
    case fetchFallbackUISchema = "get_fallback_paywall_variant_builder"
    case fetchCrossPaywallState = "get_cross_paywall_state"
    case fetchOnboarding = "get_onboarding"
    case fetchPaywallVariant = "get_paywall"

    case fetchFallbackPaywallVariant = "get_fallback_paywall"

    case validateTransaction = "validate_transaction"
    case validateReceipt = "validate_receipt"

    case sendASAToken = "set_asa_token"
    case setAttributionData = "set_attribution_data"
    case setIntegrationIdentifier = "set_integration_identifier"
    case signSubscriptionOffer = "sign_offer"

    case fetchNetworkConfig = "get_net_config"

    case fetchAllProductInfo = "get_all_products_info"

    case reqisterInstall = "reqister_install"
    case sendEvents = "send_events"
}
