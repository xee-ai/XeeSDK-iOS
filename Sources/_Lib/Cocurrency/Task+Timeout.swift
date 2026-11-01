//  Task+Timeout.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

func withThrowingTimeout<T: Sendable>(
    _ timeout: TaskDuration,
    operation: sending @escaping @isolated(any) () async throws -> T,
    isolation: isolated (any Actor)? = #isolation
) async throws -> T {
    let task = Task(operation: operation)

    var timeoutTask: Task<Void, any Error>?

    if timeout < .never {
        guard timeout > .now else {
            task.cancel()
            throw TimeoutError(timeout.asTimeInterval)
        }

        timeoutTask = Task {
            defer { task.cancel() }
            try await Task.sleep(duration: timeout)
            throw TimeoutError(timeout.asTimeInterval)
        }
    }

    let result = await withTaskCancellationHandler {
        await task.result
    } onCancel: {
        task.cancel()
    }

    if let timeoutTask {
        timeoutTask.cancel()

        if case let .failure(error) = await timeoutTask.result, error is TimeoutError {
            throw error
        }
    }

    return try result.get()
}

/// Whether `work` ended, successfully or not, within `budget`. When it did not, the caller goes on without it:
/// `work` is cancelled, which for `Xee.createdProfileManager` only stops the wait, not the profile being made.
func finishes(
    within budget: TaskDuration,
    _ work: sending @escaping @isolated(any) () async throws -> Void
) async -> Bool {
    do {
        try await withThrowingTimeout(budget, operation: work)
    } catch is TimeoutError {
        return false
    } catch {
        return true
    }
    return true
}
