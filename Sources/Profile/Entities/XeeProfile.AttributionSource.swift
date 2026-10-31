//  XeeProfile.AttributionSource.swift
//  XeeSDK
//
//  Created by Xee team.
//

extension XeeProfile {
    public struct AttributionSource: RawRepresentable, Hashable, Sendable, Codable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let appleAds = AttributionSource(rawValue: "apple_search_ads")
    }
}

