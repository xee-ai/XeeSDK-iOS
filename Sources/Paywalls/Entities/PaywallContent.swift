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
    var locale: XeeLocale? {
        var remoteConfigLocale = remoteConfig?.xeeLocale
        if remoteConfigLocale?.equalLanguageCode(.defaultPaywallLocale) ?? false {
            remoteConfigLocale = nil
        }
        return remoteConfigLocale
    }


    
    func has(languageCode otherLocale: XeeLocale, orDefault: Bool = false) -> Bool {
        let locale = locale ?? .defaultPaywallLocale
        if locale.equalLanguageCode(otherLocale) { return true }
        else if orDefault, locale.equalLanguageCode(.defaultPaywallLocale) { return true }
        else { return false }
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

    func has(languageCode locale: XeeLocale, orDefault: Bool = false) -> Bool {
        value.has(languageCode: locale, orDefault: orDefault)
    }

    func has(variationId: String?) -> Bool {
        value.has(variationId: variationId)
    }
}
