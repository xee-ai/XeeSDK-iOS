// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywall.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 03.04.2025.
//

public struct XeePaywall: Sendable, Identifiable {
    public let id: String
    public let audienceName: String

    /// Current revision (version) of a paywall. Every change within a paywall creates a new revision.
    public let revision: Int

    /// Parent A/B test name.
    public let abTestName: String

    let audienceVersionId: String

    let shouldTrackOnboardingShown: Bool

    var version: Int64
}

extension XeePaywall {
    func replace(version: Int64) -> Self {
        var paywall = self
        paywall.version = version
        return paywall
    }
    
    func isNewerThan(_ other: XeePaywall) -> Bool {
        version > other.version
    }
}

extension XeePaywall: CustomStringConvertible {
    public var description: String {
        "(id: \(id), abTestName: \(abTestName), audienceName: \(audienceName), revision: \(revision))"
    }
}

extension XeePaywall: Codable {
    enum CodingKeys: String, CodingKey {
        case paywall
        case id = "developer_id"
        case audienceName = "audience_name"
        case revision
        case abTestName = "ab_test_name"
        case audienceVersionId = "paywall_audience_version_id"
        case shouldTrackOnboardingShown = "is_tracking_purchases"
        case version = "response_created_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let paywall = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .paywall)

        id = try paywall.decode(String.self, forKey: .id)
        audienceName = try paywall.decode(String.self, forKey: .audienceName)
        revision = try paywall.decode(Int.self, forKey: .revision)
        abTestName = try paywall.decode(String.self, forKey: .abTestName)
        audienceVersionId = try paywall.decode(String.self, forKey: .audienceVersionId)
        shouldTrackOnboardingShown = try paywall.decodeIfPresent(Bool.self, forKey: .shouldTrackOnboardingShown) ?? false
        version = try container.decodeIfPresent(Int64.self, forKey: .version) ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var paywall = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .paywall)

        try paywall.encode(id, forKey: .id)
        try paywall.encode(audienceName, forKey: .audienceName)
        try paywall.encode(revision, forKey: .revision)
        try paywall.encode(abTestName, forKey: .abTestName)
        try paywall.encode(audienceVersionId, forKey: .audienceVersionId)
        if shouldTrackOnboardingShown {
            try paywall.encode(shouldTrackOnboardingShown, forKey: .shouldTrackOnboardingShown)
        }
        try container.encode(version, forKey: .version)
    }
}
