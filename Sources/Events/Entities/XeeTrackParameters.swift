// Partly adapted from Mixpanel Swift 7.0.0 (Apache License 2.0, Copyright 2022 Mixpanel, Inc.; see LICENSE-Mixpanel):
// the rule that a number must be neither NaN nor infinite comes from MixpanelType.swift. Changed: the
// value type is a closed enum of four cases, and an invalid value is dropped with a log line instead of
// failing an assertion.
//
//  XeeTrackParameters.swift
//  XeeSDK
//

import Foundation

private let log = Log.events

/// A value of a tracked event's property: text, a whole number, a number or a switch.
/// Written as a literal: `["screen": "goals", "step": 2, "skipped": false]`.
public enum XeeProperty: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}

extension XeeProperty: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self = .string(value) }
}

extension XeeProperty: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self = .int(value) }
}

extension XeeProperty: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self = .double(value) }
}

extension XeeProperty: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}

extension XeeProperty: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .int(value): try container.encode(value)
        case let .double(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        }
    }
}

/// One `Xee.track` call as the event queue keeps it: a checked name and the properties that passed.
/// The server applies the same rules again.
struct XeeTrackParameters: Sendable, Equatable {
    static let maxProperties = 20
    static let maxStringLength = 255

    let name: String
    let properties: [String: XeeProperty]

    /// `nil` when the name breaks the rules (`^[a-z][a-z0-9_]{0,63}$`). A property with a bad key
    /// (`^[a-z][a-z0-9_]{0,39}$`), a string over 255 characters or a number that is NaN or infinite is
    /// left out; past 20, the rest are left out by key order. `durationMs` replaces a `duration_ms` the
    /// caller passed and takes one of the 20 places. One log line for each thing dropped.
    static func make(name: String, properties: [String: XeeProperty], durationMs: Int?) -> XeeTrackParameters? {
        guard isSnake(name, max: 64) else {
            log.warn("Xee.track: \"\(name)\" is not a valid event name (lowercase letters, digits and _, starting with a letter, up to 64); the event is dropped")
            return nil
        }
        let limit = durationMs == nil ? maxProperties : maxProperties - 1
        var kept: [String: XeeProperty] = [:]
        for key in properties.keys.sorted() {
            if durationMs != nil, key == "duration_ms" { continue }
            guard let value = properties[key] else { continue }
            guard isSnake(key, max: 40) else {
                log.warn("Xee.track(\"\(name)\"): property key \"\(key)\" is not valid; it is dropped")
                continue
            }
            guard isValid(value) else {
                log.warn("Xee.track(\"\(name)\"): property \"\(key)\" is too long or not a finite number; it is dropped")
                continue
            }
            guard kept.count < limit else {
                log.warn("Xee.track(\"\(name)\"): more than \(maxProperties) properties; \"\(key)\" and the ones after it are dropped")
                break
            }
            kept[key] = value
        }
        if let durationMs { kept["duration_ms"] = .int(durationMs) }
        return XeeTrackParameters(name: name, properties: kept)
    }

    private static func isValid(_ value: XeeProperty) -> Bool {
        switch value {
        case let .string(text): text.count <= maxStringLength
        case let .double(number): number.isFinite
        case .int, .bool: true
        }
    }

    private static func isSnake(_ s: String, max: Int) -> Bool {
        let bytes = Array(s.utf8)
        guard let first = bytes.first, bytes.count <= max, first >= 97, first <= 122 else { return false }
        return bytes.allSatisfy { ($0 >= 97 && $0 <= 122) || ($0 >= 48 && $0 <= 57) || $0 == 95 }
    }
}

extension XeeTrackParameters: Encodable {
    enum CodingKeys: String, CodingKey {
        case name = "track_name"
        case properties = "track_properties"
    }
}
