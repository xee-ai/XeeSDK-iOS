// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeLocale.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 07.11.2023
//

import Foundation

struct XeeLocale: Sendable {
    static let defaultPaywallLocale = XeeLocale("en")

    let id: String
    var languageCode: String {
        String(id.prefix { !["-", "_"].contains($0) })
    }

    var normalizedIdentifier: String {
        id.replacingOccurrences(of: "_", with: "-")
    }

    init(_ id: String) {
        self.id = id
    }

    func equalLanguageCode(_ otherLanguageCode: String) -> Bool {
        languageCode.lowercased() == otherLanguageCode.lowercased()
    }

    func equalLanguageCode(_ otherLocale: XeeLocale) -> Bool {
        equalLanguageCode(otherLocale.languageCode)
    }
}

extension XeeLocale: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(value)
    }
}

extension XeeLocale: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension XeeLocale: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.init(value)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}
