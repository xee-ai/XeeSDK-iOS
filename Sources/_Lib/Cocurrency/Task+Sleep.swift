//  Task+Sleep.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    @inlinable
    static func sleep(duration value: TaskDuration) async throws {
        try await Task.sleep(nanoseconds: value.asNanoseconds)
    }

    @inlinable
    static func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(duration: TaskDuration(seconds))
    }
}
