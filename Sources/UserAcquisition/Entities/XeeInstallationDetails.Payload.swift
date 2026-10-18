// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeInstallationDetails.Payload.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 13.06.2025.
//
import Foundation

public extension XeeInstallationDetails {
    struct Payload: Sendable, Hashable {
        public let jsonString: String

        public var dictionary: [String: Any]? {
            guard let data = jsonString.data(using: .utf8),
                  let value = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            else { return nil }
            return value
        }
    }
}

extension XeeInstallationDetails.Payload: CustomStringConvertible {
    public var description: String { jsonString }
}

extension XeeInstallationDetails.Payload: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        jsonString = try container.decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(jsonString)
    }
}
