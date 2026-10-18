// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  CrossPaywallState.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.01.2025.
//

import Foundation

struct CrossPaywallState: Sendable, Hashable {
    static let defaultForNewUser = CrossPaywallState(variationIdByPaywalls: [:], version: 0)
    let variationIdByPaywalls: [String: String]
    let version: Int64
}

extension CrossPaywallState {
    var canParticipateInABTest: Bool {
        variationIdByPaywalls.isEmpty
    }

    func contains(paywallId: String) -> Bool {
        variationIdByPaywalls.keys.contains(paywallId)
    }

    func variationId(paywallId: String) -> String? {
        variationIdByPaywalls[paywallId]
    }
    
    func isNewerThan(_ other: CrossPaywallState) -> Bool {
        version > other.version
    }
    
    func isNewerThan(_ other: CrossPaywallState?) -> Bool {
        guard let other else { return true }
        return isNewerThan(other)
    }
}



extension CrossPaywallState: CustomStringConvertible {
    public var description: String {
        "(variationIdByPaywalls: \(variationIdByPaywalls), version: \(version))"
    }
}

extension CrossPaywallState: Codable {
    private enum CodingKeys: String, CodingKey {
        case variationIdByPaywalls = "paywall_with_variation_map"
        case version
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        variationIdByPaywalls = try container.decode([String: String].self, forKey: .variationIdByPaywalls)
        version = try container.decode(Int64.self, forKey: .version)
    }
}
