//  ProfileManager.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

@XeeActor
final class ProfileManager {
    let userId: XeeUserId

    private var cachedProfile: VH<XeeProfile>
    /// When the server last confirmed `cachedProfile`, in this launch. Nil until then, so the first
    /// `getProfile(maxAge:)` after launch, `identify` or `logout` always asks the server.
    private var syncedAt: Date?
    /// When the server last confirmed `cachedProfile`, in this launch or an earlier one (kept in storage).
    private var confirmedAt: Date?
    private var onceSentEnvironment: SentEnvironment
    private let storage: ProfileStorage

    let paywallStorage = PaywallStorage()

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
        self.confirmedAt = storage.profileConfirmedAt(for: profile.userId)

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
        markSynced()

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

    /// The saved profile when the server confirmed it less than `maxAge` ago, else a fresh one.
    func fetchProfile(maxAge: TimeInterval) async -> XeeProfile {
        let levels = cachedProfile.value.accessLevels.values.map { (isActive: $0.isActive, expiresAt: $0.expiresAt) }
        if Self.isFresh(syncedAt: syncedAt, maxAge: maxAge, accessLevels: levels, now: Date()) {
            return await profileWithOfflineAccessLevels
        }
        return await fetchProfile()
    }

    /// The server confirmed the saved profile just now.
    private func markSynced() {
        let now = Date()
        syncedAt = now
        confirmedAt = now
        storage.setProfileConfirmedAt(now, for: userId)
    }

    /// How long after the server last confirmed it a saved profile may be answered from without asking first.
    nonisolated static let savedProfileMaxAge: TimeInterval = 7 * 24 * 3600

    /// How old a confirmation may be before `.savedThenRefresh` refreshes behind its answer: `getProfile`'s default.
    nonisolated static let refreshAfter: TimeInterval = Xee.defaultProfileMaxAge

    enum SavedAnswer: Equatable {
        case askServer
        /// Answer with the saved profile; `refresh`: also ask the server behind the answer.
        case saved(refresh: Bool)
    }

    /// What `.savedThenRefresh` does (the shape of RevenueCat's `cachedOrFetched`). The saved profile is answered at once,
    /// whatever its age within `savedProfileMaxAge`, but never when an access it reports as active has reached its end:
    /// a cache must never keep access alive. A profile the server never confirmed, or confirmed in the future by a
    /// changed clock, goes to the server.
    nonisolated static func savedAnswer(
        confirmedAt: Date?,
        syncedAt: Date?,
        accessLevels: [(isActive: Bool, expiresAt: Date?)],
        now: Date
    ) -> SavedAnswer {
        guard let confirmedAt else { return .askServer }
        let age = now.timeIntervalSince(confirmedAt)
        guard age >= 0, age < savedProfileMaxAge else { return .askServer }
        if accessLevels.contains(where: { $0.isActive && ($0.expiresAt.map { $0 <= now } ?? false) }) { return .askServer }
        let freshThisLaunch = isFresh(syncedAt: syncedAt, maxAge: refreshAfter, accessLevels: accessLevels, now: now)
        return .saved(refresh: !freshThisLaunch)
    }

    /// The saved profile at once, and a refresh behind it that reaches the app through `didLoadLatestProfile`.
    func fetchProfile(policy: XeeProfilePolicy) async -> XeeProfile {
        switch policy {
        case let .maxAge(seconds):
            return await fetchProfile(maxAge: seconds)
        case .savedThenRefresh:
            let levels = cachedProfile.value.accessLevels.values.map { (isActive: $0.isActive, expiresAt: $0.expiresAt) }
            switch Self.savedAnswer(confirmedAt: confirmedAt, syncedAt: syncedAt, accessLevels: levels, now: Date()) {
            case .askServer:
                return await fetchProfile()
            case let .saved(refresh):
                // Calls made while a refresh is on its way share it (`syncing`).
                if refresh { Task { @XeeActor [weak self] in _ = await self?.fetchProfile() } }
                return await profileWithOfflineAccessLevels
            }
        }
    }

    /// A saved profile can stand in for the server's answer only while it is younger than `maxAge` and
    /// no access it reports as active has reached its end: a cache must never keep access alive.
    nonisolated static func isFresh(
        syncedAt: Date?,
        maxAge: TimeInterval,
        accessLevels: [(isActive: Bool, expiresAt: Date?)],
        now: Date
    ) -> Bool {
        guard maxAge > 0, let syncedAt, now.timeIntervalSince(syncedAt) < maxAge else { return false }
        return !accessLevels.contains { $0.isActive && ($0.expiresAt.map { $0 <= now } ?? false) }
    }

    /// The profile update on its way to the server; nil between updates.
    private var syncing: Task<Result<XeeProfile, XeeError>, Never>?
    /// Parameters that arrived while an update was on its way, sent together in the next one.
    private var pendingParams: XeeProfileParameters?

    /// One update at a time: a call made while one is on its way shares its answer, unless it brings
    /// parameters, which go out together in a single follow-up. At launch the app's `getProfile`, the
    /// return to the foreground and a storefront change would otherwise each send the profile.
    private func syncProfile(
        params: XeeProfileParameters?
    ) async throws(XeeError) -> XeeProfile {
        if let params { pendingParams = pendingParams?.merged(with: params) ?? params }
        while let running = syncing {
            let result = await running.value
            if pendingParams == nil { return try result.get() }
        }
        let sending = pendingParams
        pendingParams = nil
        let task = Task { @XeeActor in
            let result: Result<XeeProfile, XeeError>
            do throws(XeeError) {
                result = try .success(await self.sendProfile(params: sending))
            } catch {
                result = .failure(error)
            }
            self.syncing = nil
            return result
        }
        syncing = task
        return try await task.value.get()
    }

    private func sendProfile(
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
        // No body: the server says the saved profile is still current.
        if response == nil { markSynced() }

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

private extension XeeProfileParameters {
    /// These parameters with `later`'s set values on top.
    func merged(with later: XeeProfileParameters) -> XeeProfileParameters {
        var merged = self
        merged.firstName = later.firstName ?? firstName
        merged.lastName = later.lastName ?? lastName
        merged.gender = later.gender ?? gender
        merged.birthday = later.birthday ?? birthday
        merged.email = later.email ?? email
        merged.phoneNumber = later.phoneNumber ?? phoneNumber
        merged.storeCountry = later.storeCountry ?? storeCountry
        merged.ipV4Address = later.ipV4Address ?? ipV4Address
        merged.appTrackingTransparencyStatus = later.appTrackingTransparencyStatus ?? appTrackingTransparencyStatus
        merged.codableCustomAttributes = later.codableCustomAttributes ?? codableCustomAttributes
        merged.analyticsDisabled = later.analyticsDisabled ?? analyticsDisabled
        return merged
    }
}
