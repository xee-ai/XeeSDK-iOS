// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeLog.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 24.09.2025.
//

import XeeLogger

public enum XeeLog {
    public typealias Handler = XeeLogger.Handler
    public typealias Level = XeeLogger.Level
}

public extension Xee {
    /// Set to the most appropriate level of logging
    nonisolated static var logLevel: XeeLog.Level {
        get { XeeLogger.level }
        set {
            Task {
                await XeeLogger.set(level: newValue)
            }
        }
    }

    /// Register the log handler to define the desired behavior, such as writing logs to files or sending them to your server.
    /// This will not override the default behavior but will add a new one.
    ///
    /// - Parameter handler: The function will be called for each message with the appropriate `logLevel`
    nonisolated static func setLogHandler(_ handler: XeeLog.Handler?) {
        Task {
            await XeeLogger.set(handler: handler)
        }
    }
}
