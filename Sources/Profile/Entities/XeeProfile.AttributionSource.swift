// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeProfile.AttributionSource.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 26.05.2026.
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

