// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeServerCluster.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 05.11.2024.
//

public enum XeeServerCluster: Sendable {
    case `default`
    case eu
    case cn
    case other(String)

    static var all: [Self] {
        [.default, .eu, .cn]
    }
}

extension XeeServerCluster: LosslessStringConvertible, RawRepresentable {
    private enum StringValue: String {
        case `default`
        case eu
        case cn
    }

    public init?(rawValue: String) {
        let rawValue = rawValue.trimmed.lowercased()
        self = switch StringValue(rawValue: rawValue) {
        case .default: .default
        case .eu: .eu
        case .cn: .cn
        default: .other(rawValue)
        }
    }

    public var rawValue: String {
        let value: StringValue
        switch self {
        case .default: value = .default
        case .eu: value = .eu
        case .cn: value = .cn
        case .other(let value):
            return value
        }
        return value.rawValue
    }

    public init?(_ value: String) {
        self.init(rawValue: value)
    }

    public var description: String { rawValue }
}

extension XeeServerCluster: Hashable {
    public func hash(into hasher: inout Hasher) {
        description.hash(into: &hasher)
    }
}

extension XeeServerCluster: Codable {
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = XeeServerCluster(rawValue: value) ?? .default
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
