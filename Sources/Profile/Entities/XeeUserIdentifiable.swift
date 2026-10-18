// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeUserIdentifiable.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 01.08.2025.
//

protocol XeeUserIdentifiable {
    var userId: XeeUserId { get }
}

extension XeeUserId {
    func isEqualProfileId(_ other: XeeUserIdentifiable) -> Bool {
        isEqualProfileId(other.userId)
    }

    func isNotEqualProfileId(_ other: XeeUserIdentifiable) -> Bool {
        !isEqualProfileId(other.userId)
    }
}

extension XeeUserIdentifiable {
    @inlinable
    var profileId: String { userId.profileId }

    @inlinable
    var customerUserId: String? { userId.customerId }

    @inlinable
    func isEqualProfileId(_ other: String) -> Bool {
        userId.isEqualProfileId(other)
    }

    @inlinable
    func isNotEqualProfileId(_ other: String) -> Bool {
        userId.isNotEqualProfileId(other)
    }

    @inlinable
    func isEqualProfileId(_ other: XeeUserId) -> Bool {
        userId.isEqualProfileId(other)
    }

    @inlinable
    func isNotEqualProfileId(_ other: XeeUserId) -> Bool {
        userId.isNotEqualProfileId(other)
    }

    @inlinable
    func isEqualProfileId(_ other: XeeUserIdentifiable) -> Bool {
        userId.isEqualProfileId(other.userId)
    }

    @inlinable
    func isNotEqualProfileId(_ other: XeeUserIdentifiable) -> Bool {
        userId.isNotEqualProfileId(other.userId)
    }
}

extension XeeProfile: XeeUserIdentifiable {}

extension VH<XeeProfile>: XeeUserIdentifiable {
    var userId: XeeUserId { value.userId }
}

extension ProfileStorage {
    var profileId: String {
        userId.profileId
    }
}

extension ProfileManager {
    func isEqualProfileId(_ other: XeeUserId) -> Bool {
        userId.isEqualProfileId(other)
    }

    func isEqualProfileId(_ other: XeeUserIdentifiable) -> Bool {
        userId.isEqualProfileId(other.userId)
    }
}
