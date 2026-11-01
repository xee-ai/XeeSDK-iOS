//  TaskTimeoutsTests.swift
//  XeeTests
//
//  Created by Xee team.
//

#if canImport(Testing)

@testable import Xee
import Foundation
import Testing

struct TaskTimeoutsTests {
    /// The work sleeps for twice this. A call that returns before 1.5× it was cut off by the timeout; the
    /// margin is half the duration because suites run in parallel and the scheduler can be late by ~0.1 s.
    let duration: TaskDuration = .milliseconds(500)

    @Test func testTask() async {
        let start = Date()
        await #expect(throws: TimeoutError.self) {
            try await withThrowingTimeout(duration) {
                try await Task.sleep(nanoseconds: 2 * duration.asNanoseconds)
            }
        }

        #expect(Date().timeIntervalSince(start) < 1.5 * duration.asTimeInterval)
    }

    @Test func testTaskWithoutCancellationHandler() async {
        let start = Date()
        await #expect(throws: TimeoutError.self) {
            try await withThrowingTimeout(duration) {
                let nestedTask = Task {
                    try await Task.sleep(nanoseconds: 2 * duration.asNanoseconds)
                }

                try await nestedTask.value
            }
        }

        #expect(Date().timeIntervalSince(start) > 2 * duration.asTimeInterval)
    }

    @Test func testTaskWithCancellationHandler() async {
        let start = Date()
        await #expect(throws: TimeoutError.self) {
            try await withThrowingTimeout(duration) {
                let nestedTask = Task {
                    try await Task.sleep(nanoseconds: 2 * duration.asNanoseconds)
                }

                // Add cleanup to ensure the task is cancelled if timeout occurs
                try await withTaskCancellationHandler {
                    try await nestedTask.value
                } onCancel: {
                    nestedTask.cancel()
                }
            }
        }

        #expect(Date().timeIntervalSince(start) < 1.5 * duration.asTimeInterval)
    }
}

#endif

#if canImport(Testing)

/// `finishes(within:)`: first launch answers from StoreKit when the create request is slower than its budget.
struct FinishesWithinTests {
    let budget: TaskDuration = .milliseconds(500)

    @Test func workThatEndsInTimeFinishes() async {
        let done = await finishes(within: budget) { try await Task.sleep(nanoseconds: 10_000_000) }
        #expect(done)
    }

    @Test func workThatEndsLateDoesNotFinishAndTheCallDoesNotWaitForIt() async {
        let start = Date()
        let done = await finishes(within: budget) { try await Task.sleep(nanoseconds: 2 * budget.asNanoseconds) }
        #expect(!done)
        #expect(Date().timeIntervalSince(start) < 1.5 * budget.asTimeInterval)
    }

    @Test func workThatFailsInTimeCountsAsFinished() async {
        struct Failure: Error {}
        let done = await finishes(within: budget) { throw Failure() }
        #expect(done)
    }
}

#endif
