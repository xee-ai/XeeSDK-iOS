//  FailFastTimeout.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

/// How long a quick read (the profile GET: safe to send twice, and the app has a saved answer to fall back on) waits
/// for the server. The tiers are RevenueCat's (purchases-ios, HTTPRequestTimeoutManager): short, and shorter still for
/// 10 minutes after a host timed out. Every other request keeps the session's 30 seconds.
final class FailFastTimeout: @unchecked Sendable {
    static let base: TimeInterval = 5
    static let afterTimeout: TimeInterval = 2
    static let memory: TimeInterval = 600

    private let lock = NSLock()
    private var lastTimeoutByHost: [String: Date] = [:]

    func timeout(host: String?, now: Date = Date()) -> TimeInterval {
        guard let host else { return Self.base }
        lock.lock()
        defer { lock.unlock() }
        guard let last = lastTimeoutByHost[host], now.timeIntervalSince(last) < Self.memory else { return Self.base }
        return Self.afterTimeout
    }

    func recordTimeout(host: String?, now: Date = Date()) {
        guard let host else { return }
        lock.lock()
        defer { lock.unlock() }
        lastTimeoutByHost[host] = now
    }
}
