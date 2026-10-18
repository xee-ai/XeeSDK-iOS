// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeProfile.Gender.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 26.09.2022.
//

import Foundation

public extension XeeProfile {
    enum Gender: Sendable, Hashable {
        case female
        case male
        case other
    }
}

extension XeeProfile.Gender: CustomStringConvertible {
    public var description: String {
        switch self {
        case .female: "female"
        case .male: "male"
        case .other: "other"
        }
    }
}

extension XeeProfile.Gender: Codable {
    enum CodingValues: String {
        case female = "f"
        case male = "m"
        case other = "o"
    }

    public init(from decoder: Decoder) throws {
        let value = try CodingValues(rawValue: decoder.singleValueContainer().decode(String.self))
        switch value {
        case .female: self = .female
        case .male: self = .male
        case .other: self = .other
        default: self = .other
        }
    }

    public func encode(to encoder: Encoder) throws {
        let value: CodingValues =
            switch self {
            case .female: .female
            case .male: .male
            case .other: .other
            }
        var container = encoder.singleValueContainer()
        try container.encode(value.rawValue)
    }
}
