// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  ProfileManager.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 24.10.2022.
//

import Foundation

@XeeActor
final class ProfileManager {
    let userId: XeeUserId

    private var cachedProfile: VH<XeeProfile>
    private var onceSentEnvironment: SentEnvironment
    private let storage: ProfileStorage

    let crossPlacmentStorage = CrossPaywallStorage()
    let paywallStorage = PaywallStorage()
    let backendIntroductoryOfferEligibilityStorage = BackendIntroductoryOfferEligibilityStorage()

    var currentProfile: XeeProfile { cachedProfile.value }
    var isTestUser: Bool { cachedProfile.value.isTestUser }
    var segmentId: String { cachedProfile.value.segmentId }
    var lastResponseHash: String? { cachedProfile.hash }

    @XeeActor
    init(
        storage: ProfileStorage,
        profile: VH<XeeProfile>,
        sentEnvironment: SentEnvironment
    ) {
        self.userId = profile.userId
        self.cachedProfile = profile
        self.onceSentEnvironment = sentEnvironment
        self.storage = storage

        Task { @XeeActor [weak self] in
            guard let sdk = Xee.optionalSDK else { return }
            sdk.updateASATokenIfNeed(for: profile)

            let currentProfile = await sdk.profileWithOfflineAccessLevels(profile.value)
            Xee.callDelegate { $0.didLoadLatestProfile(currentProfile) }

            if sentEnvironment == .none {
                _ = await self?.fetchProfile()
            } else {
                try? await sdk.syncTransactionHistory(for: profile.userId)
            }
        }
    }

    fileprivate func saveProfileAndStartNotifyTask(
        _ newProfile: VH<XeeProfile>
    ) throws(WrongProfileIdError) -> Task<XeeProfile, Never>? {
        guard newProfile.isEqualProfileId(userId) else { throw WrongProfileIdError() }

        if newProfile.IsNotEqualHash(cachedProfile),
           newProfile.isNewerOrEqualVersion(cachedProfile)
        {
            cachedProfile = newProfile
        }

        do {
            try storage.updateProfile(newProfile)
        } catch {
            return nil
        }

        return Task {
            await notifyProfileDidChanged()
        }
    }

    fileprivate func notifyProfileDidChanged() async -> XeeProfile {
        let profile = await profileWithOfflineAccessLevels
        Xee.callDelegate { $0.didLoadLatestProfile(profile) }
        return profile
    }

    /// The  profile with offline access levels
    var profileWithOfflineAccessLevels: XeeProfile {
        get async {
            if let sdk = Xee.optionalSDK {
                await sdk.profileWithOfflineAccessLevels(cachedProfile.value)
            } else {
                cachedProfile.value
            }
        }
    }

    func fetchSegmentId() async -> String {
        await fetchProfile().segmentId
    }

    func updateProfile(params: XeeProfileParameters) async throws(XeeError) -> XeeProfile {
        if let analyticsDisabled = params.analyticsDisabled {
            try? storage.setExternalAnalyticsDisabled(analyticsDisabled, for: userId)
        }
        return try await syncProfile(params: params)
    }

    func fetchProfile() async -> XeeProfile {
        if let profile = try? await syncProfile(params: nil) {
            return profile
        }
        return await profileWithOfflineAccessLevels
    }

    private func syncProfile(
        params: XeeProfileParameters?
    ) async throws(XeeError) -> XeeProfile {
        let analyticsDisabled = (params?.analyticsDisabled ?? false)
            || ((try? storage.externalAnalyticsDisabled(for: userId)) ?? false)
        let meta = await onceSentEnvironment.getValueIfNeedSend(analyticsDisabled: analyticsDisabled)

        let httpSession = try await Xee.activatedSDK.httpSession
        let old = cachedProfile
        let response: VH<XeeProfile>?

        do throws(HTTPError) {
            if params == nil, meta == nil {
                Task { @XeeActor in
                    try? await Xee.optionalSDK?.syncTransactionHistory(for: userId)
                }
                response = try await httpSession.fetchProfile(
                    userId: old.userId,
                    responseHash: old.hash
                )
            } else {
                response = try await httpSession.updateProfile(
                    userId: old.userId,
                    parameters: params,
                    environmentMeta: meta,
                    responseHash: old.hash
                )

                if let meta {
                    onceSentEnvironment = meta.sentEnvironment
                }
            }
        } catch {
            throw error.asXeeError
        }

        if let response,
           let profile = try? await saveProfileAndStartNotifyTask(response)?.value
        {
            return profile
        }

        return await profileWithOfflineAccessLevels
    }
}

extension Xee {
    /// Handles the server profile response.
    /// If the profile is newer, it will be persisted and delivered to the delegate.
    /// - Parameter response: Server response containing a profile. User ID comparison is not required.
    /// - Returns: if the manager is working with the same user, returns Task
    func handleProfileResponse(_ response: VH<XeeProfile>?) {
        guard let response else { return }
        _ = try? profileManager?.saveProfileAndStartNotifyTask(response)
    }

    /// Handles the server profile response.
    /// If the profile is newer, it will be persisted and delivered to the delegate.
    /// - Parameter response: Server response containing a profile. User ID comparison is not required.
    /// - Returns: if the manager is working with the same user, returns Task
    func handleTransactionResponse(_ response: VH<XeeProfile>) {
        try? profileStorage.setSyncedTransactionsHistory(true, for: response.userId)
        _ = try? profileManager?.saveProfileAndStartNotifyTask(response)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    func recalculateOfflineAccessLevels() async -> XeeProfile {
        await (transactionManager as? SK2TransactionManager)?.clearCache()

        if let manger = profileManager {
            return await manger.notifyProfileDidChanged()
        }

        let manger = offlineProfileManager ?? OfflineProfileManager(userId: profileStorage.userId)
        return await profileWithOfflineAccessLevels(manger.currentProfile)
    }

    func syncTransactionHistory(for userId: XeeUserId, forceSync: Bool = false) async throws(XeeError) {
        try await transactionManager.syncUnfinishedTransactions()

        guard let syncedTransactionsHistory = try? profileStorage.syncedTransactionsHistory(for: userId) else {
            return
        }

        guard forceSync || !syncedTransactionsHistory else { return }
        try await transactionManager.syncTransactionHistory(for: userId)
    }

    func profileWithOfflineAccessLevels(_ serverProfile: XeeProfile) async -> XeeProfile {
        guard #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *),
              let transactionManager = transactionManager as? SK2TransactionManager,
              let productsManager = productsManager as? SK2ProductsManager
        else {
            return serverProfile
        }
        var verifiedCurrentEntitlements = await transactionManager.getVerifiedCurrentEntitlements()

        if await !transactionManager.hasUnfinishedTransactions {
            verifiedCurrentEntitlements = verifiedCurrentEntitlements.filter {
                $0.unfEnvironment == SK2Transaction.xcodeEnvironment
            }
        }

        guard !verifiedCurrentEntitlements.isEmpty else { return serverProfile }

        return await serverProfile.added(
            transactions: verifiedCurrentEntitlements,
            productManager: productsManager
        )
    }
}
