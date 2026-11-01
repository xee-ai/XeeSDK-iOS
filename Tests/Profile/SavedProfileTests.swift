#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

/// `getProfile(policy: .savedThenRefresh)`: the saved profile at once, refreshed behind it.
/// The shape is RevenueCat's `cachedOrFetched` (purchases-ios, CustomerInfoManager); the end-date rule is ours.
struct SavedProfileTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func answer(
        confirmedAgo: TimeInterval?,
        syncedAgo: TimeInterval? = nil,
        levels: [(isActive: Bool, expiresAt: Date?)] = []
    ) -> ProfileManager.SavedAnswer {
        ProfileManager.savedAnswer(
            confirmedAt: confirmedAgo.map { now.addingTimeInterval(-$0) },
            syncedAt: syncedAgo.map { now.addingTimeInterval(-$0) },
            accessLevels: levels,
            now: now
        )
    }

    @Test func aProfileConfirmedInAnEarlierLaunchIsAnsweredAtOnceAndRefreshed() {
        #expect(answer(confirmedAgo: 3600) == .saved(refresh: true))
    }

    @Test func aProfileConfirmedThisLaunchWithinMaxAgeNeedsNoRefresh() {
        #expect(answer(confirmedAgo: 60, syncedAgo: 60) == .saved(refresh: false))
    }

    @Test func aProfileSyncedThisLaunchButLongAgoIsRefreshed() {
        #expect(answer(confirmedAgo: 600, syncedAgo: 600) == .saved(refresh: true))
    }

    @Test func aProfileNeverConfirmedAsksTheServer() {
        #expect(answer(confirmedAgo: nil) == .askServer)
    }

    @Test func aProfileConfirmedAWeekAgoOrMoreAsksTheServer() {
        let week = ProfileManager.savedProfileMaxAge
        #expect(answer(confirmedAgo: week - 1) == .saved(refresh: true))
        #expect(answer(confirmedAgo: week) == .askServer)
    }

    @Test func aConfirmationInTheFutureIsNotTrusted() {
        #expect(answer(confirmedAgo: -60) == .askServer)
    }

    @Test func activeAccessThatHasEndedAsksTheServer() {
        #expect(answer(confirmedAgo: 60, syncedAgo: 60, levels: [(true, now.addingTimeInterval(-1))]) == .askServer)
        #expect(answer(confirmedAgo: 60, syncedAgo: 60, levels: [(true, now)]) == .askServer)
    }

    @Test func accessThatEndsLaterOrNeverIsAnsweredFromTheSavedProfile() {
        let later: [(isActive: Bool, expiresAt: Date?)] = [(true, now.addingTimeInterval(60)), (true, nil)]
        #expect(answer(confirmedAgo: 3600, levels: later) == .saved(refresh: true))
    }

    @Test func anInactiveLevelWithAPastEndDoesNotMatter() {
        #expect(answer(confirmedAgo: 3600, levels: [(false, now.addingTimeInterval(-3600))]) == .saved(refresh: true))
    }
}

#endif
