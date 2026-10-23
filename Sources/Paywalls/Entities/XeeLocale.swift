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

/// A locale split into its parts, in stored form. Same rules as `parse` in the server's store/locales.rs.
private struct LocaleTag {
    let lang: String
    let script: String?
    let region: String?

    init?(_ raw: String) {
        let parts = raw.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-", omittingEmptySubsequences: false)
            .map(String.init)
        guard let first = parts.first?.lowercased(),
              (2...3).contains(first.count),
              first.unicodeScalars.allSatisfy({ ("a"..."z").contains($0) })
        else { return nil }
        var script: String?
        var region: String?
        for p in parts.dropFirst() {
            if p.count == 1 { break } // an extension (-u-…, -x-…): it and everything after it are ignored
            let letters = p.unicodeScalars.allSatisfy { ("a"..."z").contains($0) || ("A"..."Z").contains($0) }
            let digits = p.unicodeScalars.allSatisfy { ("0"..."9").contains($0) }
            if script == nil, region == nil, p.count == 4, letters {
                script = p.prefix(1).uppercased() + p.dropFirst().lowercased()
            } else if region == nil, (p.count == 2 && letters) || (p.count == 3 && digits) {
                region = p.uppercased()
            } else if region == nil, script == nil {
                return nil
            }
        }
        lang = first
        self.script = script
        self.region = region
    }

    var id: String { [lang, script, region].compactMap { $0 }.joined(separator: "-") }

    /// Chinese and Cantonese without a script: Traditional in Taiwan, Hong Kong and Macau, else Simplified.
    var inferredScript: String? {
        guard script == nil, lang == "zh" || lang == "yue" else { return script }
        return ["TW", "HK", "MO"].contains(region ?? "") ? "Hant" : "Hans"
    }
}

private let latinAmerica: Set<String> = [
    "AR", "BO", "CL", "CO", "CR", "CU", "DO", "EC", "GT", "HN", "MX", "NI", "PA", "PE", "PR", "PY", "SV", "US", "UY",
]

extension XeeLocale {
    /// The stored form (`zh-Hant-TW`), or nil when this is not a locale.
    var normalized: XeeLocale? { LocaleTag(id).map { XeeLocale($0.id) } }

    /// The language the app runs in, the one paywalls and views are requested in by default.
    static var app: XeeLocale {
        Bundle.main.preferredLocalizations.first.flatMap { XeeLocale($0).normalized } ?? .defaultPaywallLocale
    }

    /// The offered language a device asking for `requested` gets, or nil for the source language.
    /// Same rules as `resolve` in the server's store/locales.rs.
    static func resolve(_ requested: XeeLocale, offered: [XeeLocale]) -> XeeLocale? {
        guard let want = LocaleTag(requested.id) else { return nil }
        var best: (score: Int, locale: XeeLocale)?
        for o in offered {
            guard let tag = LocaleTag(o.id), tag.lang == want.lang, tag.inferredScript == want.inferredScript else { continue }
            let score: Int
            if tag.region == want.region { score = 4 }
            else if tag.region == "419", let w = want.region, latinAmerica.contains(w) { score = 3 }
            else if tag.region == nil { score = 2 }
            else { score = 1 }
            if score > (best?.score ?? 0) { best = (score, o) }
        }
        return best?.locale
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
