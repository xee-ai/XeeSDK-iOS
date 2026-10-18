// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeOnboarding.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 08.04.2025.
//

import Foundation

public struct XeeOnboarding: PaywallContent {
    public let paywall: XeePaywall

    public let instanceIdentity: String

    public let variationId: String

    /// A onboarding name.
    public let name: String

    public let remoteConfig: XeeRemoteConfig?

    public var hasViewConfiguration: Bool { true }

    package let viewConfiguration: ViewConfiguration

    package var shouldTrackShown: Bool { paywall.shouldTrackOnboardingShown }

    var requestLocale: XeeLocale

    package var requestLocaleIdentifier: String {
        requestLocale.normalizedIdentifier
    }
}

extension XeeOnboarding: CustomStringConvertible {
    public var description: String {
        "(paywall:\(paywall), instanceIdentity: \(instanceIdentity), name: \(name), variationId: \(variationId), hasViewConfiguration: \(hasViewConfiguration)"
            + (remoteConfig.map { ", remoteConfig: \($0)" } ?? "")
            + ", requestLocale: \(requestLocale.id))"
    }
}

extension XeeOnboarding: Codable {
    enum CodingKeys: String, CodingKey {
        case instanceIdentity = "onboarding_id"
        case variationId = "variation_id"
        case name = "onboarding_name"
        case remoteConfig = "remote_config"
        case viewConfiguration = "onboarding_builder"
        case requestLocale = "request_locale"
    }

    public init(from decoder: Decoder) throws {
        paywall = try decoder.userInfo.paywallOrNil ?? XeePaywall(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        instanceIdentity = try container.decode(String.self, forKey: .instanceIdentity)
        name = try container.decode(String.self, forKey: .name)
        variationId = try container.decode(String.self, forKey: .variationId)
        remoteConfig = try container.decodeIfPresent(XeeRemoteConfig.self, forKey: .remoteConfig)
        viewConfiguration = try container.decode(ViewConfiguration.self, forKey: .viewConfiguration)
        requestLocale = try decoder.userInfo.requestLocaleOrNil ?? container.decode(XeeLocale.self, forKey: .requestLocale)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(instanceIdentity, forKey: .instanceIdentity)
        try container.encode(name, forKey: .name)
        try container.encode(variationId, forKey: .variationId)
        try container.encodeIfPresent(remoteConfig, forKey: .remoteConfig)
        try container.encode(viewConfiguration, forKey: .viewConfiguration)
        try container.encode(requestLocale, forKey: .requestLocale)
        try paywall.encode(to: encoder)
    }
}
