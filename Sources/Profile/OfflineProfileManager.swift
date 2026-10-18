// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  OfflineProfileManager.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 15.10.2025.
//

import Foundation

@XeeActor
final class OfflineProfileManager {
    var userId: XeeUserId { currentProfile.userId }
    var currentProfile: XeeProfile

    init(profile: XeeProfile) {
        self.currentProfile = profile
    }

    convenience init(userId: XeeUserId) {
        self.init(profile: .init(
            userId: userId,
            segmentId: "", // TODO: The user hasn't been created on the server; the segmentID is unknown. This user is created when a purchase is made in the Xcode environment, and the server hasn't created the user yet.
            isTestUser: false,
            codableCustomAttributes: nil,
            appliedAttributionSources: [],
            customAttributes: [:],
            accessLevels: [:],
            subscriptions: [:],
            nonSubscriptions: [:],
            version: 0,
            storeAccountToken: nil
        ))
    }

    static func ifNeedCreateNewUser(
        _ currentProfile: XeeProfile,
        _ currenAppAccountToken: UUID?,
        _ newCustomerUserId: String?,
        _ newAppAccountToken: UUID?
    ) -> Self? {
        guard let newCustomerUserId else {
            // same user
            return nil
        }

        guard let currentCustomerId = currentProfile.customerUserId else {
            // current anonymous user identified with a new customerUserId
            return .init(profile: currentProfile.with(customerUserId: newCustomerUserId))
        }

        guard currentCustomerId == newCustomerUserId else {
            // current non-anonymous user identified with a different customerUserId
            return .init(userId: currentProfile.userId.with(customerUserId: newCustomerUserId))
        }

        // current non-anonymous user is the same
        if let newAppAccountToken, newAppAccountToken != currenAppAccountToken {
            return .init(profile: currentProfile)
        }

        return nil
    }
}

private extension XeeUserId {
    func with(customerUserId newCustomerUserId: String) -> Self {
        .init(
            profileId: profileId,
            customerId: newCustomerUserId
        )
    }
}

private extension XeeProfile {
    func with(customerUserId newCustomerUserId: String) -> Self {
        .init(
            userId: userId.with(customerUserId: newCustomerUserId),
            segmentId: segmentId,
            isTestUser: isTestUser,
            codableCustomAttributes: codableCustomAttributes,
            appliedAttributionSources: appliedAttributionSources,
            customAttributes: customAttributes,
            accessLevels: accessLevels,
            subscriptions: subscriptions,
            nonSubscriptions: nonSubscriptions,
            version: version,
            storeAccountToken: storeAccountToken
        )
    }
}
