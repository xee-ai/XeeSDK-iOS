// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  PaywallContent.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 08.04.2025.
//

protocol PaywallContent: Sendable, Codable {
    var paywall: XeePaywall { get }
    var instanceIdentity: String { get }
    var variationId: String { get }
    var name: String { get }
    var remoteConfig: XeeRemoteConfig? { get }

    var requestLocale: XeeLocale { get set }
}

extension PaywallContent {
    /// Whether this copy was fetched for `other`: the server translated it for that request, so a copy
    /// fetched in another language is not reused, even one the server answered in the same language.
    func matches(requestLocale other: XeeLocale) -> Bool {
        (requestLocale.normalized ?? requestLocale).id == (other.normalized ?? other).id
    }

    func has(variationId: String?) -> Bool {
        guard let variationId else { return true }
        return self.variationId == variationId
    }
}

extension VH where Value: PaywallContent {
    var requestLocale: XeeLocale {
        get { value.requestLocale }
        mutating set {
            guard newValue != value.requestLocale else { return }
            self = mapValue {
                var content = $0
                content.requestLocale = newValue
                return content
            }
        }
    }

    func matches(requestLocale locale: XeeLocale) -> Bool {
        value.matches(requestLocale: locale)
    }

    func has(variationId: String?) -> Bool {
        value.has(variationId: variationId)
    }
}
