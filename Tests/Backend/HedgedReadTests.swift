#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

/// A slow profile read is sent a second time on its own connection; the first answer wins. The tiers of the fail-fast
/// timeout are RevenueCat's (purchases-ios, HTTPRequestTimeoutManager): short, and shorter once a host timed out.
struct HedgedReadTests {
    private struct Failure: Error, Equatable { let name: String }

    private actor Calls {
        private(set) var count = 0
        private(set) var cancelled = 0
        func called() { count += 1 }
        func wasCancelled() { cancelled += 1 }
    }

    private let delay: TaskDuration = .milliseconds(200)

    @Test func aFastFirstAnswerSendsNoSecondRequest() async throws {
        let calls = Calls()
        let value = try await hedged(after: delay, first: { 1 }, second: { await calls.called(); return 2 })
        #expect(value == 1)
        try await Task.sleep(nanoseconds: 400_000_000)
        #expect(await calls.count == 0)
    }

    @Test func aSlowFirstAnswerIsBeatenByTheSecondRequestWhichCancelsIt() async throws {
        let calls = Calls()
        let start = Date()
        let value = try await hedged(
            after: delay,
            first: {
                do { try await Task.sleep(nanoseconds: 3_000_000_000) } catch { await calls.wasCancelled() }
                return 1
            },
            second: { 2 }
        )
        #expect(value == 2)
        #expect(Date().timeIntervalSince(start) < 1.0)
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(await calls.cancelled == 1)
    }

    @Test func aFirstRequestThatEndsBeforeTheSecondStartsStillWins() async throws {
        let value = try await hedged(
            after: delay,
            first: { try await Task.sleep(nanoseconds: 300_000_000); return 1 },
            second: { try await Task.sleep(nanoseconds: 2_000_000_000); return 2 }
        )
        #expect(value == 1)
    }

    @Test func aFirstRequestThatFailsEarlySendsTheSecondAtOnce() async throws {
        let start = Date()
        let value = try await hedged(after: .seconds(5), first: { throw Failure(name: "first") }, second: { 2 })
        #expect(value == 2)
        #expect(Date().timeIntervalSince(start) < 1.0)
    }

    @Test func whenBothFailTheFirstErrorIsThrown() async {
        await #expect(throws: Failure(name: "first")) {
            try await hedged(after: delay, first: { throw Failure(name: "first") }, second: { throw Failure(name: "second") }) as Int
        }
    }

    @Test func theRaceSaysWhichRequestWon() async throws {
        let quick = try await hedgedRace(after: delay, first: { 1 }, second: { 2 })
        #expect(quick.value == 1 && !quick.secondWon)
        let slow = try await hedgedRace(
            after: delay,
            first: { try await Task.sleep(nanoseconds: 3_000_000_000); return 1 },
            second: { 2 }
        )
        #expect(slow.value == 2 && slow.secondWon)
    }

    // MARK: fail-fast timeout

    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func aQuickReadWaitsFiveSecondsAndTwoOnceTheHostTimedOut() {
        let tiers = FailFastTimeout()
        #expect(tiers.timeout(host: "api.xee.ai", now: t0) == 5)
        tiers.recordTimeout(host: "api.xee.ai", now: t0)
        #expect(tiers.timeout(host: "api.xee.ai", now: t0.addingTimeInterval(599)) == 2)
        #expect(tiers.timeout(host: "api.xee.ai", now: t0.addingTimeInterval(600)) == 5)
        #expect(tiers.timeout(host: "other.example", now: t0.addingTimeInterval(1)) == 5)
    }
}

#endif
