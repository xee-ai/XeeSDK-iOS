// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeUserId.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 30.07.2025.
//

package struct XeeUserId: Sendable, Hashable {
    package let profileId: String
    package let customerId: String?
}

extension XeeUserId {
    @inlinable
    var isAnonymous: Bool { customerId == nil }

    @inlinable
    func isEqualProfileId(_ other: String) -> Bool {
        profileId == other
    }

    @inlinable
    func isNotEqualProfileId(_ other: String) -> Bool {
        !isEqualProfileId(other)
    }

    @inlinable
    func isEqualProfileId(_ other: XeeUserId) -> Bool {
        other.isEqualProfileId(profileId)
    }

    @inlinable
    func isNotEqualProfileId(_ other: XeeUserId) -> Bool {
        !isEqualProfileId(other)
    }
}

extension XeeUserId: CustomStringConvertible {
    package var description: String {
        "(profileId: \(profileId), customerUserId: \(customerId ?? "nil")"
    }
}

extension XeeUserId: Codable {
    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case customerId = "customer_Id"
    }
}
