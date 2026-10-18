// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Level+Codable.swift
//  XeeLogger
//
//  Created by Aleksei Valiano on 22.08.2024
//

import Foundation

extension XeeLogger.Level: Codable {
    public init(from decoder: Decoder) throws {
        self = try XeeLogger.Level(stringLiteral: decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringLiteral)
    }
}
