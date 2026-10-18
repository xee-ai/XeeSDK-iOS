// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeRemoteConfig.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 06.04.2024
//

import Foundation

public struct XeeRemoteConfig: Sendable {
    let xeeLocale: XeeLocale

    public var locale: String { xeeLocale.id }
    /// A custom JSON string configured in Xee Dashboard for this paywall.
    public let jsonString: String
    /// A custom dictionary configured in Xee Dashboard for this paywall (same as `jsonString`)
    public var dictionary: [String: Any]? {
        guard let data = jsonString.data(using: .utf8),
              let remoteConfig = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else { return nil }
        return remoteConfig
    }
}

extension XeeRemoteConfig: CustomStringConvertible {
    public var description: String {
        "(locale: \(locale), jsonString: \(jsonString))"
    }
}

extension XeeRemoteConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case xeeLocale = "lang"
        case jsonString = "data"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        xeeLocale = try container.decode(XeeLocale.self, forKey: .xeeLocale)
        jsonString = try container.decode(String.self, forKey: .jsonString)
    }
}
