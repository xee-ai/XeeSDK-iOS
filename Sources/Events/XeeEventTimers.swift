//  XeeEventTimers.swift
//  XeeSDK
//

import Foundation

/// Start times for `Xee.time`, by event name, in memory only: a cold start forgets them.
final class XeeEventTimers: @unchecked Sendable {
    static let shared = XeeEventTimers()

    private let lock = NSLock()
    private var starts: [String: Date] = [:]

    /// Starts a timer for this name; a second start replaces the first. An empty name is ignored.
    func start(_ name: String, at date: Date) {
        guard !name.isEmpty else {
            Log.events.error("Xee.time: cannot time an empty event name")
            return
        }
        lock.lock()
        defer { lock.unlock() }
        starts[name] = date
    }

    /// Milliseconds since `start` for this name, and forgets the timer; `nil` when none runs.
    func take(_ name: String, at date: Date) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        guard let start = starts.removeValue(forKey: name) else { return nil }
        return max(0, Int((date.timeIntervalSince(start) * 1000).rounded()))
    }
}
