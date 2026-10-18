// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywallVersions.swift
//  Xee
//

import Foundation

/// The paywall versions this build was made for, from `XeePaywalls.json` in the app bundle
/// (`{ "main": 4 }`). Claude updates the file whenever it pushes a version. The server serves the
/// matching version, so an older build keeps getting values its code can read.
enum XeePaywallVersions {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var override: [String: Int]?
    private static let bundled: [String: Int] = {
        guard let url = Bundle.main.url(forResource: "XeePaywalls", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return [:] }
        return parse(data)
    }()

    /// Reads the table entry by entry, so one bad value costs only that entry. An entry counts when
    /// it is a whole number of 1 or more (a boolean does not).
    static func parse(_ data: Data) -> [String: Int] {
        guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return [:] }
        var table: [String: Int] = [:]
        for (key, value) in object {
            guard let n = value as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() else { continue }
            let d = n.doubleValue
            guard d >= 1, d < 1e15, d == d.rounded() else { continue }
            table[key] = Int(d)
        }
        return table
    }

    static func version(for paywallId: String) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        return (override ?? bundled)[paywallId]
    }

    static func setForTesting(_ table: [String: Int]?) {
        lock.lock()
        override = table
        lock.unlock()
    }
}
