// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeStorefront.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2024
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
