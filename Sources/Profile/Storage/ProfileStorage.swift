// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  ProfileStorage.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 30.09.2022.
//

import Foundation

private let log = Log.storage

@XeeActor
final class ProfileStorage {
    private enum Constants {
        static let profileKey = "XeeSDK_Purchaser_Info"
        static let profileIdKey = "XeeSDK_Profile_Id"
        static let appAccountTokenKey = "XeeSDK_app_account_token"
        static let externalAnalyticsDisabledKey = "XeeSDK_External_Analytics_Disabled"
        static let syncedTransactionsHistoryKey = "XeeSDK_Synced_Bundle_Receipt"
        static let appleSearchAdsSyncDateKey = "XeeSDK_Apple_Search_Ads_Sync_Date"
        static let lastOpenedWebPaywallVariantKey = "XeeSDK_Last_Opened_Web_PaywallVariant"
        static let lastStartAcceleratedSyncProfileKey = "XeeSDK_Last_Start_Accelerated_Sync_Profile"
    }

    private static let userDefaults = Storage.userDefaults

    static var userId: XeeUserId = {
        guard let profileId = userDefaults.string(forKey: Constants.profileIdKey) else {
            return createAnonymousUserId()
        }

        guard let profile, profile.isEqualProfileId(profileId) else {
            return XeeUserId(
                profileId: profileId,
                customerId: nil
            )
        }

        return XeeUserId(
            profileId: profileId,
            customerId: profile.customerUserId
        )
    }()

    private static func createAnonymousUserId() -> XeeUserId {
        let identifier = UUID().uuidString.lowercased()
        userDefaults.set(identifier, forKey: Constants.profileIdKey)
        log.debug("create anonymous profile (profileId: \(identifier))")
        return XeeUserId(
            profileId: identifier,
            customerId: nil
        )
    }

    private static var profile: VH<XeeProfile>? = {
        do {
            return try userDefaults.getJSON(VH<XeeProfile>.self, forKey: Constants.profileKey)
        } catch {
            log.warn(error.localizedDescription)
            return nil
        }
    }()

    private static func setProfile(_ newProfile: VH<XeeProfile>) {
        let newProfileId = newProfile.profileId
        if userId.isNotEqualProfileId(newProfileId) {
            userDefaults.set(newProfileId, forKey: Constants.profileIdKey)
            log.debug("set profileId: \(newProfileId)")
        }
        userId = newProfile.userId

        if let oldProfile = profile, oldProfile.isEqualProfileId(newProfileId) {
            guard newProfile.IsNotEqualHash(oldProfile),
                  newProfile.isNewerOrEqualVersion(oldProfile)
            else { return }
        }

        profile = newProfile
        do {
            try userDefaults.setJSON(newProfile, forKey: Constants.profileKey)
            log.debug("saving profile success.")
        } catch {
            log.error("saving profile fail. \(error.localizedDescription)")
        }
    }

    private static var appAccountToken: UUID? =
        userDefaults.string(forKey: Constants.appAccountTokenKey).flatMap(UUID.init)

    private static func setAppAccountToken(_ value: UUID?) {
        guard appAccountToken != value else { return }
        appAccountToken = value
        if let value {
            userDefaults.set(value.uuidString, forKey: Constants.appAccountTokenKey)
            log.debug("set appAccountToken = \(value).")
        } else {
            userDefaults.removeObject(forKey: Constants.appAccountTokenKey)
            log.debug("clear appAccountToken")
        }
    }

    private static var externalAnalyticsDisabled: Bool = userDefaults.bool(forKey: Constants.externalAnalyticsDisabledKey)

    private static func setExternalAnalyticsDisabled(_ value: Bool) {
        guard externalAnalyticsDisabled != value else { return }
        externalAnalyticsDisabled = value
        userDefaults.set(value, forKey: Constants.externalAnalyticsDisabledKey)
        log.debug("set externalAnalyticsDisabled = \(value).")
    }

    private static var syncedTransactionsHistory: Bool = userDefaults.bool(forKey: Constants.syncedTransactionsHistoryKey)

    private static func setSyncedTransactionsHistory(_ value: Bool) {
        guard syncedTransactionsHistory != value else { return }
        syncedTransactionsHistory = value
        userDefaults.set(value, forKey: Constants.syncedTransactionsHistoryKey)
        log.debug("set syncedTransactionsHistory = \(value).")
    }

    private static var appleSearchAdsSyncDate: Date? = userDefaults.object(forKey: Constants.appleSearchAdsSyncDateKey) as? Date

    private static func setAppleSearchAdsSyncDate(_ value: Date) {
        guard appleSearchAdsSyncDate != value else { return }
        appleSearchAdsSyncDate = value
        userDefaults.set(value, forKey: Constants.appleSearchAdsSyncDateKey)
        log.debug("set appleSearchAdsSyncDate = \(value).")
    }

    private static var lastOpenedWebPaywallVariantDate: Date? = userDefaults.object(forKey: Constants.lastOpenedWebPaywallVariantKey) as? Date

    private static func setLastOpenedWebPaywallVariantDate(_ value: Date) {
        guard lastOpenedWebPaywallVariantDate != value else { return }
        lastOpenedWebPaywallVariantDate = value
        userDefaults.set(value, forKey: Constants.lastOpenedWebPaywallVariantKey)
        log.debug("set lastOpenedWebPaywallVariantDate = \(value).")
    }

    private static var lastStartAcceleratedSyncProfileDate: Date? = userDefaults.object(forKey: Constants.lastStartAcceleratedSyncProfileKey) as? Date

    private static func setLastStartAcceleratedSyncProfileDate(_ value: Date) {
        guard lastStartAcceleratedSyncProfileDate != value else { return }
        lastStartAcceleratedSyncProfileDate = value
        userDefaults.set(value, forKey: Constants.lastStartAcceleratedSyncProfileKey)
        log.debug("set setLastStartAcceleratedSyncProfileDate = \(value).")
    }

    static func clearProfile(newProfile: VH<XeeProfile>? = nil) {
        log.verbose("Clear profile")
        if let newProfile {
            setProfile(newProfile)
        } else {
            userId = createAnonymousUserId()
            profile = nil
            userDefaults.removeObject(forKey: Constants.profileKey)
        }

        userDefaults.removeObject(forKey: Constants.appAccountTokenKey)
        appAccountToken = nil
        userDefaults.removeObject(forKey: Constants.externalAnalyticsDisabledKey)
        externalAnalyticsDisabled = false
        userDefaults.removeObject(forKey: Constants.syncedTransactionsHistoryKey)
        syncedTransactionsHistory = false
        userDefaults.removeObject(forKey: Constants.appleSearchAdsSyncDateKey)
        appleSearchAdsSyncDate = nil
        userDefaults.removeObject(forKey: Constants.lastOpenedWebPaywallVariantKey)
        lastOpenedWebPaywallVariantDate = nil
        userDefaults.removeObject(forKey: Constants.lastStartAcceleratedSyncProfileKey)
        lastStartAcceleratedSyncProfileDate = nil

        CrossPaywallStorage.clear()
        BackendIntroductoryOfferEligibilityStorage.clear()
        PaywallStorage.clear()
    }
}

extension ProfileStorage {
    @inlinable
    var userId: XeeUserId { Self.userId }

    var profile: VH<XeeProfile>? {
        guard let profile = Self.profile, profile.isEqualProfileId(userId) else {
            return nil
        }
        return profile
    }

    func clearProfile(newProfile: VH<XeeProfile>? = nil) {
        Self.clearProfile(newProfile: newProfile)
    }

    func setIdentifiedProfile(_ newProfile: VH<XeeProfile>) {
        Self.setProfile(newProfile)
        Self.setSyncedTransactionsHistory(false)
    }
}

extension ProfileStorage {
    func appAccountToken() -> UUID? {
        Self.appAccountToken
    }

    func setAppAccountToken(_ value: UUID?) {
        Self.setAppAccountToken(value)
    }
}

extension ProfileStorage {
    private func checkProfileId(_ otherUserId: XeeUserId) throws(WrongProfileIdError) {
        guard Self.userId.isEqualProfileId(otherUserId) else { throw WrongProfileIdError() }
    }

    func profile(for userId: XeeUserId) throws(WrongProfileIdError) -> VH<XeeProfile>? {
        try checkProfileId(userId)
        return profile
    }

    func updateProfile(_ profile: VH<XeeProfile>) throws(WrongProfileIdError) {
        try checkProfileId(profile.userId)
        Self.setProfile(profile)
    }

    func externalAnalyticsDisabled(for userId: XeeUserId) throws(WrongProfileIdError) -> Bool {
        try checkProfileId(userId)
        return Self.externalAnalyticsDisabled
    }

    func setExternalAnalyticsDisabled(_ value: Bool, for userId: XeeUserId) throws(WrongProfileIdError) {
        try checkProfileId(userId)
        Self.setExternalAnalyticsDisabled(value)
    }

    func syncedTransactionsHistory(for userId: XeeUserId) throws(WrongProfileIdError) -> Bool {
        try checkProfileId(userId)
        return Self.syncedTransactionsHistory
    }

    func setSyncedTransactionsHistory(_ value: Bool, for userId: XeeUserId) throws(WrongProfileIdError) {
        try checkProfileId(userId)
        Self.setSyncedTransactionsHistory(value)
    }

    func appleSearchAdsSyncDate(for userId: XeeUserId) throws(WrongProfileIdError) -> Date? {
        try checkProfileId(userId)
        return Self.appleSearchAdsSyncDate
    }

    func setAppleSearchAdsSyncDate(for userId: XeeUserId) throws(WrongProfileIdError) {
        try checkProfileId(userId)
        Self.setAppleSearchAdsSyncDate(Date())
    }
}

extension ProfileStorage { // TODO: need checkProfileId
    func lastOpenedWebPaywallVariantDate() -> Date? {
        Self.lastOpenedWebPaywallVariantDate
    }

    func setLastOpenedWebPaywallVariantDate() {
        Self.setLastOpenedWebPaywallVariantDate(Date())
    }

    func lastStartAcceleratedSyncProfileDate() -> Date? {
        Self.lastStartAcceleratedSyncProfileDate
    }

    func setLastStartAcceleratedSyncProfileDate() {
        Self.setLastStartAcceleratedSyncProfileDate(Date())
    }
}
