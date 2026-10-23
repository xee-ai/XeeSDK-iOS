// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywallConfig.swift
//  Xee
//

import Foundation

/// Remembers which keys were already seen, so a fallback is logged once per key and not on every read.
final class FirstSightings: @unchecked Sendable {
    private let lock = NSLock()
    private var keys: Set<String> = []

    func isFirst(_ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return keys.insert(key).inserted
    }
}

/// A paywall variant's values, read with the default your code already has. A missing key, or a value
/// of another type, returns that default, so a paywall never breaks because of the server.
public struct XeePaywallConfig: @unchecked Sendable {
    private let values: [String: Any]
    /// No "missing key" log lines: every key is missing on purpose.
    private let quiet: Bool
    private static let fallbacks = FirstSightings()

    init(json: String) {
        let parsed = json.data(using: .utf8).flatMap { try? JSONSerialization.jsonObject(with: $0) }
        values = parsed as? [String: Any] ?? [:]
        quiet = false
    }

    private init(emptyValues: Void) {
        values = [:]
        quiet = true
    }

    /// Every getter returns the code's default, without a log line: what `Xee.getView` hands back when
    /// the view could not load.
    public static let empty = XeePaywallConfig(emptyValues: ())

    private func fallback<T>(_ key: String, expecting type: String, _ value: T) -> T {
        if !quiet, Self.fallbacks.isFirst(key) {
            Log.default.debug("paywall config key '\(key)' is missing or not a \(type); using the code's default")
        }
        return value
    }

    private func number(_ key: String) -> NSNumber? {
        guard let n = values[key] as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() else { return nil }
        return n
    }

    public func string(_ key: String, default value: String) -> String {
        values[key] as? String ?? fallback(key, expecting: "string", value)
    }

    public func int(_ key: String, default value: Int) -> Int {
        guard let n = number(key), n.doubleValue == n.doubleValue.rounded() else { return fallback(key, expecting: "int", value) }
        return n.intValue
    }

    public func double(_ key: String, default value: Double) -> Double {
        number(key)?.doubleValue ?? fallback(key, expecting: "double", value)
    }

    public func bool(_ key: String, default value: Bool) -> Bool {
        guard let n = values[key] as? NSNumber, CFGetTypeID(n) == CFBooleanGetTypeID() else { return fallback(key, expecting: "bool", value) }
        return n.boolValue
    }

    public func stringList(_ key: String, default value: [String]) -> [String] {
        values[key] as? [String] ?? fallback(key, expecting: "list of strings", value)
    }
}

public extension XeePaywallVariant {
    /// The variant's values for the variables Claude declared in this paywall version.
    var config: XeePaywallConfig { XeePaywallConfig(json: remoteConfig?.jsonString ?? "{}") }
}
