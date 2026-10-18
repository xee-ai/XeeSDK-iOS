// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Task+Sleep.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 12.09.2024
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
