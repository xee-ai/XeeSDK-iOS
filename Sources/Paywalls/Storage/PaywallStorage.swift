// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  PaywallStorage.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 22.10.2022.
//

import Foundation

private let log = Log.storage

@XeeActor
final class PaywallStorage {
    private static func getPaywall<Content: PaywallContent>(_ paywallId: String) -> VH<Content>? {
        if Content.self == XeePaywallVariant.self {
            return PaywallVariantStorage.paywallVariantByPaywallId[paywallId] as? VH<Content>
        } else if Content.self == XeeOnboarding.self {
            return OnboardingStorage.onboardingByPaywallId[paywallId] as? VH<Content>
        } else {
            return nil
        }
    }

    private static func setPaywall(_ content: some PaywallContent) {
        if let paywallVariant = content as? XeePaywallVariant {
            PaywallVariantStorage.setPaywallVariant(paywallVariant)
        } else if let onboarding = content as? XeeOnboarding {
            OnboardingStorage.setOnboarding(onboarding)
        } else {
            return
        }
    }

    func restorePaywallVariant(
        _ paywallId: String,
        withVariationId: String,
        withInstanceIdentity: String,
        withPaywallVersion: Int64,
        withPaywallRevision: Int
    ) -> XeePaywallVariant? {
        guard let paywallVariant: XeePaywallVariant = Self.getPaywall(paywallId)?.value,
              paywallVariant.variationId == withVariationId,
              paywallVariant.instanceIdentity == withInstanceIdentity,
              paywallVariant.paywall.version == withPaywallVersion,
              paywallVariant.paywall.revision == withPaywallRevision
        else {
            return nil
        }

        return paywallVariant
    }

    func getPaywallById<Content: PaywallContent>(
        _ paywallId: String,
        withLocale locale: XeeLocale,
        orDefaultLocale: Bool,
        withVariationId variationId: String?
    ) -> VH<Content>? {
        guard
            var content: VH<Content> = Self.getPaywall(paywallId),
            content.has(variationId: variationId),
            content.has(languageCode: locale, orDefault: orDefaultLocale)
        else { return nil }

        content.requestLocale = locale
        return content
    }

    private func getNewerPaywall<Content: PaywallContent>(than content: Content) -> Content? {
        guard var cached: Content = Self.getPaywall(content.paywall.id)?.value,
              cached.remoteConfig?.xeeLocale == content.remoteConfig?.xeeLocale,
              cached.variationId == content.variationId,
              cached.paywall.isNewerThan(content.paywall)
        else { return nil }
        cached.requestLocale = content.requestLocale
        return cached
    }

    func savedPaywallChosen<Content: PaywallContent>(_ chosen: XeePaywallChosen<Content>) -> XeePaywallChosen<Content> {
        let content = chosen.content

        Log.crossAB.verbose("savedPaywallChosen variationId: \(content.variationId), paywallId: \(content.paywall.id), version: \(content.paywall.version)")

        if let newer = getNewerPaywall(than: content) { return XeePaywallChosen.restore(newer) }

        Self.setPaywall(content)
        return chosen
    }

    static func clear() {
        PaywallVariantStorage.clear()
        OnboardingStorage.clear()
    }
}
