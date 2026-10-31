//  XeeUserId.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 30.07.2025.
//

import CryptoKit
import Foundation

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

extension XeeUserId {
    /// Where computed profile IDs live: a fixed UUID, the same in every app and on the server.
    private static let profileIdNamespace: [UInt8] = [
        0x3d, 0x6f, 0x4a, 0x5e, 0x2b, 0x1c, 0x4e, 0x8f, 0x9a, 0x7d, 0x58, 0xe2, 0xc1, 0xb0, 0xa9, 0xf4,
    ]

    /// The profile ID a customer user ID always has: a UUID v5 of it, lowercase. Every install of that person names the
    /// same profile, so the SDK knows its ID without waiting for the server. Profiles made before keep their random ID:
    /// the server answers it on the first launch and the SDK switches to it, as it always did.
    static func computedProfileId(for customerUserId: String) -> String {
        var digest = Array(Insecure.SHA1.hash(data: Data(profileIdNamespace + Array(customerUserId.utf8))).prefix(16))
        digest[6] = (digest[6] & 0x0F) | 0x50 // version 5
        digest[8] = (digest[8] & 0x3F) | 0x80 // RFC 4122 variant
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        let parts = [hex.prefix(8), hex.dropFirst(8).prefix(4), hex.dropFirst(12).prefix(4), hex.dropFirst(16).prefix(4), hex.dropFirst(20)]
        return parts.joined(separator: "-")
    }

    /// This user's ID is the one computed from its customer user ID: it cannot change.
    var isComputed: Bool {
        customerId.map { Self.computedProfileId(for: $0) == profileId } ?? false
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
