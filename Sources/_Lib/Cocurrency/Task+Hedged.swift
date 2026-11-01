//  Task+Hedged.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

private enum HedgeEvent<T: Sendable>: Sendable {
    case attempt(isFirst: Bool, Result<T, any Error>)
    case timer(fired: Bool)
}

/// Runs `first`; when it has not answered after `delay`, or has failed, runs `second` as well. The first success wins and
/// the other is cancelled. When both fail, the error of `first` is thrown. For a request that is safe to send twice, with
/// `second` on its own connection: a stalled connection then costs `delay` instead of the stall.
func hedged<T: Sendable>(
    after delay: TaskDuration,
    first: @escaping @Sendable () async throws -> T,
    second: @escaping @Sendable () async throws -> T
) async throws -> T {
    func attempt(_ isFirst: Bool, _ work: @Sendable () async throws -> T) async -> HedgeEvent<T> {
        do { return .attempt(isFirst: isFirst, .success(try await work())) } catch { return .attempt(isFirst: isFirst, .failure(error)) }
    }

    return try await withThrowingTaskGroup(of: HedgeEvent<T>.self) { group in
        group.addTask { await attempt(true, first) }
        group.addTask { .timer(fired: (try? await Task.sleep(duration: delay)) != nil) }

        var secondStarted = false
        var firstError: (any Error)?
        var secondFailed = false
        func startSecond() {
            guard !secondStarted else { return }
            secondStarted = true
            group.addTask { await attempt(false, second) }
        }

        while let event = try await group.next() {
            switch event {
            case let .timer(fired):
                if fired { startSecond() }
            case let .attempt(_, .success(value)):
                group.cancelAll()
                return value
            case let .attempt(isFirst: true, .failure(error)):
                firstError = error
                if secondFailed {
                    group.cancelAll()
                    throw error
                }
                startSecond()
            case .attempt(isFirst: false, .failure):
                secondFailed = true
                if let firstError {
                    group.cancelAll()
                    throw firstError
                }
            }
        }
        throw firstError ?? CancellationError()
    }
}
