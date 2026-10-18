// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  PaywallVariantStorage.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 21.04.2025.
//

import Foundation

private let log = Log.storage

@XeeActor
final class PaywallVariantStorage {
    private enum Constants {
        static let paywallVariantStorageKey = "XeeSDK_Cached_Purchase_Containers"
        static let paywallVariantStorageVersionKey = "XeeSDK_Cached_Purchase_Containers_Version"
        static let currentPaywallVariantsStorageVersion = 3
    }

    private static let userDefaults = Storage.userDefaults

    static var paywallVariantByPaywallId: [String: VH<XeePaywallVariant>] = {
        guard userDefaults.integer(forKey: Constants.paywallVariantStorageVersionKey) == Constants.currentPaywallVariantsStorageVersion else {
            return [:]
        }
        do {
            var userInfo = CodingUserInfo()
            userInfo.setRequestLocale(.defaultPaywallLocale)
            return try userDefaults.getJSON(
                [VH<XeePaywallVariant>].self,
                forKey: Constants.paywallVariantStorageKey,
                userInfo: userInfo
            )?.asPaywallVariantByPaywallId ?? [:]
        } catch {
            log.error(error.localizedDescription)
            return [:]
        }
    }()

    static func setPaywallVariant(_ paywallVariant: XeePaywallVariant) {
        paywallVariantByPaywallId[paywallVariant.paywall.id] = VH(paywallVariant, time: Date())
        let array = Array(paywallVariantByPaywallId.values)
        guard array.isNotEmpty else {
            userDefaults.removeObject(forKey: Constants.paywallVariantStorageKey)
            return
        }

        do {
            try userDefaults.setJSON(array, forKey: Constants.paywallVariantStorageKey)
            userDefaults.set(Constants.currentPaywallVariantsStorageVersion, forKey: Constants.paywallVariantStorageVersionKey)

            log.debug("Saving paywall success.")
        } catch {
            log.error("Saving paywall fail. \(error.localizedDescription)")
        }
    }

    static func clear() {
        paywallVariantByPaywallId = [:]
        userDefaults.removeObject(forKey: Constants.paywallVariantStorageKey)
        log.debug("Clear paywallVariants.")
    }
}

private extension Sequence<VH<XeePaywallVariant>> {
    var asPaywallVariantByPaywallId: [String: VH<XeePaywallVariant>] {
        Dictionary(map { ($0.value.paywall.id, $0) }, uniquingKeysWith: { first, second in
            first.value.paywall.isNewerThan(second.value.paywall) ? first : second
        })
    }
}
