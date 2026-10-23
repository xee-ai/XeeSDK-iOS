//
//  EventsSendPolicy.swift
//  XeeSDK
//

import Foundation

/// What to do after a batch of events failed to send. Pure, so every rule is tested.
///
/// - 413 (too large): halve the byte budget and send a smaller batch; a single event the server
///   still refuses is dropped.
/// - 400 or 415 on a gzipped body: send it again uncompressed (a server without gzip); on a plain
///   body the server can never read it, so it is dropped.
/// - Anything else (no network, 401, 429, 5xx): back off 20 s, doubling to 10 minutes, with up to a
///   quarter more at random so devices do not retry together, and never sooner than `Retry-After`.
struct EventsSendPolicy: Sendable {
    static let maxBytes = 200_000
    static let minBytes = 8000
    static let firstDelay: TimeInterval = 20
    static let maxDelay: TimeInterval = 600
    static let maxRetryAfter: TimeInterval = 3600

    enum Decision: Equatable, Sendable {
        case drop
        case shrink
        case resendPlain
        case backoff(TimeInterval)
    }

    private(set) var byteBudget = maxBytes
    private(set) var gzip = true
    private(set) var failures = 0

    mutating func succeeded() {
        failures = 0
        byteBudget = min(Self.maxBytes, byteBudget * 2)
    }

    /// `jitter` is 0...1; the caller passes a random number.
    mutating func failed(status: Int?, retryAfter: TimeInterval?, eventCount: Int, gzipped: Bool, jitter: Double) -> Decision {
        switch status {
        case 413:
            if eventCount > 1, byteBudget > Self.minBytes {
                byteBudget = max(Self.minBytes, byteBudget / 2)
                return .shrink
            }
            return .drop
        case 400, 415:
            if gzipped {
                gzip = false
                return .resendPlain
            }
            return .drop
        default:
            failures += 1
            let base = min(Self.maxDelay, Self.firstDelay * pow(2, Double(failures - 1)))
            let delay = min(Self.maxDelay, base + base * 0.25 * min(1, max(0, jitter)))
            return .backoff(max(delay, min(retryAfter ?? 0, Self.maxRetryAfter)))
        }
    }
}
