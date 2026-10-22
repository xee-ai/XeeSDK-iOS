#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

struct ProfileCacheTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func fresh(
        syncedAgo: TimeInterval?,
        maxAge: TimeInterval = 300,
        levels: [(isActive: Bool, expiresAt: Date?)] = []
    ) -> Bool {
        ProfileManager.isFresh(
            syncedAt: syncedAgo.map { now.addingTimeInterval(-$0) },
            maxAge: maxAge,
            accessLevels: levels,
            now: now
        )
    }

    @Test func aProfileSyncedWithinMaxAgeIsFresh() {
        #expect(fresh(syncedAgo: 60))
    }

    @Test func aProfileNeverSyncedSinceLaunchIsStale() {
        #expect(!fresh(syncedAgo: nil))
    }

    @Test func aProfileOlderThanMaxAgeIsStale() {
        #expect(!fresh(syncedAgo: 300))
        #expect(!fresh(syncedAgo: 301))
    }

    @Test func aZeroOrNegativeMaxAgeAlwaysAsksTheServer() {
        #expect(!fresh(syncedAgo: 0, maxAge: 0))
        #expect(!fresh(syncedAgo: 0, maxAge: -1))
    }

    @Test func activeAccessThatHasEndedMakesTheProfileStale() {
        #expect(!fresh(syncedAgo: 10, levels: [(true, now.addingTimeInterval(-1))]))
        #expect(!fresh(syncedAgo: 10, levels: [(true, now)]))
    }

    @Test func accessThatEndsLaterOrNeverKeepsItFresh() {
        #expect(fresh(syncedAgo: 10, levels: [(true, now.addingTimeInterval(60)), (true, nil)]))
    }

    @Test func anInactiveLevelWithAPastEndDoesNotMatter() {
        #expect(fresh(syncedAgo: 10, levels: [(false, now.addingTimeInterval(-3600))]))
    }
}

#endif
