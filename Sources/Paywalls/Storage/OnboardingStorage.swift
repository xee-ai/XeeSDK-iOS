// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  OnboardingStorage.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 21.04.2025.
//

import Foundation

private let log = Log.storage

@XeeActor
final class OnboardingStorage {
    private enum Constants {
        static let onboardingStorageKey = "XeeSDK_Cached_Onboarding"
        static let onboardingStorageVersionKey = "XeeSDK_Cached_Onboarding_Version"
        static let currentOnboardingStorageVersion = 1
    }

    private static let userDefaults = Storage.userDefaults

    static var onboardingByPaywallId: [String: VH<XeeOnboarding>] = {
        guard userDefaults.integer(forKey: Constants.onboardingStorageVersionKey) == Constants.currentOnboardingStorageVersion else {
            return [:]
        }
        do {
            var userInfo = CodingUserInfo()
            userInfo.setRequestLocale(.defaultPaywallLocale)
            return try userDefaults.getJSON(
                [VH<XeeOnboarding>].self,
                forKey: Constants.onboardingStorageKey,
                userInfo: userInfo
            )?.asOnboardingByPaywallId ?? [:]
        } catch {
            log.error(error.localizedDescription)
            return [:]
        }
    }()

    static func setOnboarding(_ onboarding: XeeOnboarding) {
        onboardingByPaywallId[onboarding.paywall.id] = VH(onboarding, time: Date())
        let array = Array(onboardingByPaywallId.values)
        guard array.isNotEmpty else {
            userDefaults.removeObject(forKey: Constants.onboardingStorageKey)
            return
        }

        do {
            try userDefaults.setJSON(array, forKey: Constants.onboardingStorageKey)
            userDefaults.set(Constants.currentOnboardingStorageVersion, forKey: Constants.onboardingStorageVersionKey)

            log.debug("Saving onboarding success.")
        } catch {
            log.error("Saving onboarding fail. \(error.localizedDescription)")
        }
    }

    static func clear() {
        onboardingByPaywallId = [:]
        userDefaults.removeObject(forKey: Constants.onboardingStorageKey)
        log.debug("Clear onboarding's.")
    }
}

private extension Sequence<VH<XeeOnboarding>> {
    var asOnboardingByPaywallId: [String: VH<XeeOnboarding>] {
        Dictionary(map { ($0.value.paywall.id, $0) }, uniquingKeysWith: { first, second in
            first.value.paywall.isNewerThan(second.value.paywall) ? first : second
        })
    }
}
