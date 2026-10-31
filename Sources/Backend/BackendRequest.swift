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

    case fetchUISchema = "get_paywall_variant_builder"

    case validateTransaction = "validate_transaction"

    case sendASAToken = "set_asa_token"
    case setAttributionData = "set_attribution_data"


    case fetchAllProductInfo = "get_all_products_info"

    case reqisterInstall = "reqister_install"
    case sendEvents = "send_events"
}
