//
//  PaywallAssignment.swift
//  XeeSDK
//

import Foundation

/// The arm the server chose for this profile in a paywall's running test, sent with the variations as `meta.assigned`
/// (server/src/sdk/paywall.rs, paywall_variants). Absent without a test or when the server could not choose: the device
/// then draws.
struct PaywallAssignment: Codable, Sendable, Equatable {
    let variationId: String
    let audienceVersionId: String

    enum CodingKeys: String, CodingKey {
        case variationId = "variation_id"
        case audienceVersionId = "paywall_audience_version_id"
    }
}

/// `{ "meta": { "assigned": PaywallAssignment? } }`, read from the variations body.
struct PaywallAssignedMeta: Decodable, Sendable {
    let assigned: PaywallAssignment?

    private enum CodingKeys: String, CodingKey { case meta }
    private struct Meta: Decodable { let assigned: PaywallAssignment? }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        assigned = (try? container.decodeIfPresent(Meta.self, forKey: .meta))?.assigned
    }
}
