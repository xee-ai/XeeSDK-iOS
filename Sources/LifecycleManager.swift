// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  LifecycleManager.swift
//  XeeSDK
//
//  Created by Aleksey Goncharov on 27.10.2022.
//

import Foundation
import StoreKit

#if canImport(UIKit)
import UIKit
#endif

private let log = Log.Category(name: "LifecycleManager")

@XeeActor
final class LifecycleManager {
    private enum Constants {
        static let appOpenedSendInterval: TimeInterval = 60.0
        static let profileUpdateInterval: TimeInterval = 60.0
        static let profileUpdateShortInterval: TimeInterval = 10.0

        static let idfaStatusCheckDuration: TimeInterval = 600.0
        static let idfaStatusCheckInterval: TimeInterval = 5.0
    }

    static let shared = LifecycleManager()

    private var appOpenedSentAt: Date?
    private var newStorefrontCountryAvailable: String?

    private var profileUpdateRegularTask: Task<Void, Error>?

    func initialize() {
        log.info("LifecycleManager initialize")

        subscribeForLifecycleEvents()
        subscribeForStorefrontUpdate()
        profileUpdateRegularTask = scheduleProfileUpdate(skipFirstSleep: false)
        scheduleIDFAUpdate()
    }

    private func subscribeForStorefrontUpdate() {
        Task { @XeeActor [weak self] in
            for await value in XeeStorefront.updates {
                self?.newStorefrontCountryAvailable = value.countryCode
            }
        }
    }

    // MARK: - Sync Profile Logic

    private var profileIsSyncing = false

    private func scheduleProfileUpdate(skipFirstSleep: Bool) -> Task<Void, Error> {
        let stamp = Log.stamp

        log.verbose("LifecycleManager: \(stamp) scheduleProfileUpdate")

        return Task { @XeeActor [weak self] in
            if !skipFirstSleep {
                try await Task.sleep(seconds: Constants.profileUpdateInterval)
            }

            while !Task.isCancelled {
                let updateInterval: TimeInterval

                do {
                    try await self?.syncProfile(logStamp: stamp)
                    updateInterval = Constants.profileUpdateInterval
                } catch {
                    log.warn("LifecycleManager: \(stamp) syncProfile Error: \(error)")
                    updateInterval = Constants.profileUpdateShortInterval
                }

                log.debug("LifecycleManager: \(stamp) update after: \(updateInterval) sec.")
                try await Task.sleep(seconds: updateInterval)
            }
            throw CancellationError()
        }
    }

    private func syncProfile(logStamp stamp: String) async throws {
        guard !profileIsSyncing else { return }

        defer { profileIsSyncing = false }
        profileIsSyncing = true

        if let storeCountry = newStorefrontCountryAvailable {
            let params = XeeProfileParameters(storeCountry: storeCountry)

            log.verbose("LifecycleManager: \(stamp) syncProfile with storeCountry = \(storeCountry)")
            try await Xee.updateProfile(params: params)
            newStorefrontCountryAvailable = nil
        } else {
            log.verbose("LifecycleManager: \(stamp) syncProfile")
            _ = try await Xee.getProfile()
        }
    }

    // MARK: - App Open Event Logic

    private func subscribeForLifecycleEvents() {
        #if canImport(UIKit)
        Task {
            let didBecomeActiveNotification = UIApplication.didBecomeActiveNotification
            NotificationCenter.default.addObserver(
                forName: didBecomeActiveNotification,
                object: nil,
                queue: nil,
                using: handleDidBecomeActiveNotification
            )
        }
        #endif
    }

    @Sendable
    private nonisolated func handleDidBecomeActiveNotification(_: Notification) {
        Task { @XeeActor in
            log.verbose("handleDidBecomeActiveNotification")
            Xee.trackSystemEvent(XeeInternalEventParameters(eventName: "app_become_active"))

            profileUpdateRegularTask?.cancel()
            self.profileUpdateRegularTask = self.scheduleProfileUpdate(skipFirstSleep: true)

            Xee.applicationDidBecomeActive()

            if let appOpenedSentAt, Date().timeIntervalSince(appOpenedSentAt) < Constants.appOpenedSendInterval {
                log.verbose("handleDidBecomeActiveNotification SKIP")
                return
            }
            appOpenedSentAt = Date()

            Task.detached(priority: .utility) {
                try? await Xee.trackEvent(.appOpened)
            }
            log.verbose("handleDidBecomeActiveNotification track")
        }
    }

    // MARK: - IDFA Update Logic

    private func scheduleIDFAUpdate() {
        Task { @XeeActor in
            let timerStartedAt = Date()

            while true {
                let now = Date()
                if now.timeIntervalSince1970 - timerStartedAt.timeIntervalSince1970 > Constants.idfaStatusCheckDuration {
                    log.verbose("stop IdfaUpdateTimer")
                    return
                }

                let status = await Environment.Device.idfaRetrievalStatus
                log.verbose("idfaUpdateTimer tick, status = \(status)")

                switch status {
                case .allowed:
                    _ = try? await Xee.getProfile()
                    return
                case .notDetermined:
                    try await Task.sleep(seconds: Constants.idfaStatusCheckInterval)
                case .denied, .notAvailable:
                    return
                }
            }
        }
    }
}
