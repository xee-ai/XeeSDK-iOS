// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 24.09.2022.
//

import Foundation

private let log = Log.default

@XeeActor
public final class Xee {
    let profileStorage: ProfileStorage

    let apiKeyPrefix: String

    let backend: Backend
    let httpSession: Backend.MainExecutor
    let httpFallbackSession: Backend.FallbackExecutor
    let httpConfigsSession: Backend.ConfigsExecutor

    let transactionManager: StoreKitTransactionManager
    let productsManager: StoreKitProductsManager
    var purchaser: StorekitPurchaser?

    package let observerMode: Bool

    let purchasePayloadStorage: PurchasePayloadStorage

    init(
        configuration: XeeConfiguration,
        backend: Backend
    ) async {
        self.observerMode = configuration.observerMode
        self.apiKeyPrefix = configuration.apiKeyPrefix
        self.backend = backend
        self.profileStorage = ProfileStorage()
        self.httpSession = backend.createDefaultExecutor()
        self.httpFallbackSession = backend.createFallbackExecutor()
        self.httpConfigsSession = backend.createConfigsExecutor()

        let productVendorIdsStorage = BackendProductInfoStorage()
        await PurchasePayloadStorage.migration(for: ProfileStorage.userId)
        self.purchasePayloadStorage = PurchasePayloadStorage()

        if configuration.transactionFinishBehavior != .manual {
            _ = await PurchasePayloadStorage.removeAllUnfinishedTransactionState()
        }

        self.transactionManager = SK2TransactionManager(
            httpSession: httpSession,
            storage: purchasePayloadStorage
        )
        let sk2ProductsManager = SK2ProductsManager(
            apiKeyPrefix: apiKeyPrefix,
            session: httpSession,
            storage: productVendorIdsStorage
        )
        self.productsManager = sk2ProductsManager

        self.sharedProfileManager = restoreProfileManager(configuration)
        if !observerMode {
            self.purchaser = SK2Purchaser.startObserving(
                transactionSynchronizer: self,
                sk2ProductsManager: sk2ProductsManager,
                storage: purchasePayloadStorage
            )
        }
        startSyncIPv4OnceIfNeeded()
    }

    private var sharedProfileManager: ProfileManager.Shared?

    private func restoreProfileManager(
        _ configuration: XeeConfiguration
    ) -> ProfileManager.Shared {
        let currentProfileId = profileStorage.profileId
        let newCustomerUserId = configuration.customerUserId
        let newAppAccountToken = newCustomerUserId != nil ? configuration.appAccountToken : nil
        let currentAppAccountToken = profileStorage.appAccountToken()
        profileStorage.setAppAccountToken(newAppAccountToken)

        let newUserId = XeeUserId(
            profileId: currentProfileId,
            customerId: newCustomerUserId
        )

        guard let currentProfile = profileStorage.profile else {
            // no existing user found
            return .creating(
                next: .init(userId: newUserId),
                task: createNewProfileOnServer(newUserId, newAppAccountToken)
            )
        }

        guard let next = OfflineProfileManager.ifNeedCreateNewUser(
            currentProfile.value,
            currentAppAccountToken,
            newCustomerUserId,
            newAppAccountToken
        ) else {
            return .current(.init(
                storage: profileStorage,
                profile: currentProfile,
                sentEnvironment: .none
            ))
        }

        return .creating(
            next: next,
            task: createNewProfileOnServer(next.userId, newAppAccountToken)
        )
    }

    private func createNewProfileOnServer(
        _ newUserId: XeeUserId,
        _ appAccountToken: UUID?
    ) -> Task<ProfileManager, Error> {
        Task.detached(priority: .userInitiated) { @XeeActor @Sendable () async throws -> ProfileManager in
            while !Task.isCancelled {
                let analyticsDisabled = (try? self.profileStorage.externalAnalyticsDisabled(for: newUserId)) ?? false
                let meta = await Environment.Meta(includedAnalyticIds: !analyticsDisabled)
                let httpSession = self.httpSession

                let result = await Result.from { () throws -> VH<XeeProfile> in
                    try await httpSession.createProfile(
                        userId: newUserId,
                        appAccountToken: appAccountToken,
                        parameters: XeeProfileParameters(analyticsDisabled: analyticsDisabled),
                        environmentMeta: meta
                    )
                }

                guard case let .creating(next, _) = self.sharedProfileManager,
                      newUserId == next.userId,
                      !Task.isCancelled
                else {
                    throw XeeError.profileWasChanged()
                }

                switch result {
                case let .success(createdProfile):
                    if newUserId.isNotEqualProfileId(createdProfile) {
                        self.profileStorage.clearProfile(newProfile: createdProfile)
                    } else {
                        self.profileStorage.setIdentifiedProfile(createdProfile)
                    }

                    let manager = ProfileManager(
                        storage: self.profileStorage,
                        profile: createdProfile,
                        sentEnvironment: meta.sentEnvironment
                    )
                    self.sharedProfileManager = .current(manager)
                    return manager

                case let .failure(error):
                    // A refusal that cannot change (wrong key, taken token) ends here with the server's
                    // answer. Anything else (offline, timeout, server error) is tried again.
                    if let http = error as? HTTPError, http.isFinal {
                        throw http.asXeeError
                    }
                    try? await Task.sleep(duration: .milliseconds(100))
                    continue
                }
            }
            throw XeeError.profileWasChanged()
        }
    }
}

extension Xee {
    func identify(
        toCustomerUserId newCustomerUserId: String,
        withAppAccountToken newAppAccountToken: UUID?
    ) async throws(XeeError) {
        let currentAppAccountToken = profileStorage.appAccountToken()
        profileStorage.setAppAccountToken(newAppAccountToken)
        let currentProfileId = profileStorage.profileId
        var next: OfflineProfileManager

        switch sharedProfileManager {
        case nil:
            next = .init(userId: .init(profileId: currentProfileId, customerId: newCustomerUserId))

        case let .current(manager):
            if let value = OfflineProfileManager.ifNeedCreateNewUser(
                manager.currentProfile,
                currentAppAccountToken,
                newCustomerUserId,
                newAppAccountToken
            ) {
                next = value
            } else {
                return
            }

        case let .creating(manager, task):
            if let value = OfflineProfileManager.ifNeedCreateNewUser(
                manager.currentProfile,
                currentAppAccountToken,
                newCustomerUserId,
                newAppAccountToken
            ) {
                next = value
                task.cancel()
            } else {
                _ = try await task.profileManager
                return
            }
        }

        if next.userId.isNotEqualProfileId(currentProfileId) {
            log.info("Fixed incorrect profileId form: \(next.userId.profileId) to: \(currentProfileId) ")
            next = .init(userId: .init(profileId: currentProfileId, customerId: newCustomerUserId))
        }

        log.verbose("start identify \(next.userId) ")

        let task = createNewProfileOnServer(next.userId, newAppAccountToken)
        let previous = sharedProfileManager
        sharedProfileManager = .creating(
            next: next,
            task: task
        )

        do {
            _ = try await task.profileManager
        } catch {
            // The server refused: keep the profile the app already had, so it keeps working.
            if case .current = previous,
               case let .creating(creating, _) = sharedProfileManager,
               creating.userId == next.userId
            {
                sharedProfileManager = previous
                profileStorage.setAppAccountToken(currentAppAccountToken)
            }
            throw error
        }
    }

    func logout() async throws(XeeError) {
        switch sharedProfileManager {
        case nil:
            break
        case let .current(manager):
            if manager.userId.isAnonymous {
                throw .unidentifiedUserLogout()
            }
        case let .creating(creating, task):
            if creating.userId.isAnonymous {
                _ = try await task.profileManager
                return
            }
            task.cancel()
        }

        profileStorage.clearProfile()

        let newAnonymousUserId = XeeUserId(
            profileId: profileStorage.profileId,
            customerId: nil
        )

        log.verbose("logout \(newAnonymousUserId) ")

        let task = createNewProfileOnServer(newAnonymousUserId, nil)
        sharedProfileManager = .creating(
            next: .init(userId: newAnonymousUserId),
            task: task
        )
        _ = try await task.profileManager
    }
}

private extension ProfileManager {
    enum Shared {
        case current(ProfileManager)
        case creating(next: OfflineProfileManager, task: Task<ProfileManager, Error>)
    }
}

private extension Task where Success == ProfileManager {
    var profileManager: ProfileManager {
        get async throws(XeeError) {
            do {
                return try await value
            } catch {
                if let xeeError = error as? XeeError {
                    throw xeeError
                }
                throw .profileWasChanged()
            }
        }
    }
}

extension Xee {
    var userId: XeeUserId? {
        switch sharedProfileManager {
        case nil:
            nil
        case let .current(manager):
            manager.userId
        case let .creating(next, _):
            next.userId
        }
    }

    var profileManager: ProfileManager? {
        if case let .current(manager) = sharedProfileManager {
            manager
        } else {
            nil
        }
    }

    var offlineProfileManager: OfflineProfileManager? {
        if case let .creating(manager, _) = sharedProfileManager {
            manager
        } else {
            nil
        }
    }

    func profileManager(withProfileId userId: XeeUserId) throws(XeeError) -> ProfileManager? {
        guard let manager = profileManager else { return nil }
        guard manager.isEqualProfileId(userId) else { throw .profileWasChanged() }
        return manager
    }

    var createdProfileManager: ProfileManager {
        get async throws(XeeError) {
            switch sharedProfileManager {
            case nil:
                throw .notActivated()
            case let .current(manager):
                return manager
            case let .creating(_, task):
                do {
                    return try await withTaskCancellationWithError(CancellationError()) {
                        try await task.profileManager
                    }
                } catch {
                    if let xeeError = error as? XeeError {
                        throw xeeError
                    }
                    throw .profileWasChanged()
                }
            }
        }
    }
}

extension ProfileManager? {
    var orThrows: ProfileManager {
        get throws(XeeError) {
            switch self {
            case nil:
                throw .profileWasChanged()
            case let value?:
                value
            }
        }
    }
}
