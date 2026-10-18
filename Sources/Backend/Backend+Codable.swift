// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Backend+Codable.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 08.09.2022.
//

import Foundation

extension Backend {
    static func configure(jsonDecoder: JSONDecoder) {
        jsonDecoder.dateDecodingStrategy = .formatted(Backend.dateFormatter)
        jsonDecoder.dataDecodingStrategy = .base64
    }

    static func configure(jsonEncoder: JSONEncoder) {
        jsonEncoder.dateEncodingStrategy = .formatted(Backend.inUTCDateFormatter)
        jsonEncoder.dataEncodingStrategy = .base64
    }

    package static let inUTCDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }()

    package static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
}

private extension CodingUserInfoKey {
    static let enableEncodingViewConfiguration = CodingUserInfoKey(rawValue: "adapty_encode_view_configuration")!
    static let userId = CodingUserInfoKey(rawValue: "adapty_user_id")!
    static let paywallId = CodingUserInfoKey(rawValue: "adapty_paywall_id")!
    static let paywallVariationId = CodingUserInfoKey(rawValue: "adapty_paywall_variation_id")!
    static let paywall = CodingUserInfoKey(rawValue: "adapty_paywall")!
    static let requestlocale = CodingUserInfoKey(rawValue: "adapty_request_locale")!
}

extension CodingUserInfo {
    mutating func setUserId(_ value: XeeUserId) {
        self[.userId] = value
    }

    mutating func setPaywall(_ value: XeePaywall) {
        self[.paywall] = value
    }

    mutating func setPaywallId(_ value: String) {
        self[.paywallId] = value
    }

    mutating func setRequestLocale(_ value: XeeLocale) {
        self[.requestlocale] = value
    }

    mutating func setPaywallVariationId(_ value: String) {
        self[.paywallVariationId] = value
    }

    package mutating func enableEncodingViewConfiguration() {
        self[.enableEncodingViewConfiguration] = true
    }
}

extension [CodingUserInfoKey: Any] {
    var enabledEncodingViewConfiguration: Bool {
        self[.enableEncodingViewConfiguration] as? Bool ?? false
    }

    var userId: XeeUserId {
        get throws {
            if let value = self[.userId] as? XeeUserId {
                return value
            }

            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The decoder does not have the \(CodingUserInfoKey.userId) parameter"))
        }
    }

    var paywallId: String {
        get throws {
            if let value = self[.paywallId] as? String {
                return value
            }
            if let value = paywallOrNil {
                return value.id
            }
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The decoder does not have the \(CodingUserInfoKey.paywallId) parameter"))
        }
    }

    var paywall: XeePaywall {
        get throws {
            if let value = paywallOrNil {
                return value
            }

            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The decoder does not have the \(CodingUserInfoKey.paywall) parameter"))
        }
    }

    var paywallOrNil: XeePaywall? {
        self[.paywall] as? XeePaywall
    }

    var requestLocaleOrNil: XeeLocale? {
        self[.requestlocale] as? XeeLocale
    }

    var paywallVariationIdOrNil: String? {
        self[.paywallVariationId] as? String
    }
}

extension Backend {
    enum CodingKeys: String, CodingKey {
        case data
        case type
        case id
        case attributes
        case meta
    }
}

extension Backend.Response {
    struct Data<Value>: Sendable, Decodable where Value: Decodable, Value: Sendable {
        let value: Value

        init(from decoder: Decoder) throws {
            value = try decoder
                .container(keyedBy: Backend.CodingKeys.self)
                .decode(Value.self, forKey: .data)
        }
    }

    struct OptionalData<Value>: Sendable, Decodable where Value: Decodable, Value: Sendable {
        let value: Value?

        init(from decoder: Decoder) throws {
            value = try decoder
                .container(keyedBy: Backend.CodingKeys.self)
                .decodeIfPresent(Value.self, forKey: .data)
        }
    }

    struct Meta<Value>: Sendable, Decodable where Value: Decodable, Value: Sendable {
        let value: Value

        init(from decoder: Decoder) throws {
            value = try decoder
                .container(keyedBy: Backend.CodingKeys.self)
                .decode(Value.self, forKey: .meta)
        }
    }
}
