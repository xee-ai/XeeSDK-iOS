//  XeeStorefront.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

public struct XeeStorefront: Sendable, Identifiable, Hashable {
    public let id: String
    public let countryCode: String
}

extension XeeStorefront: CustomStringConvertible {
    public var description: String {
        "\(id) \(countryCode)"
    }
}

extension XeeStorefront: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case countryCode = "country_code"
    }
}
