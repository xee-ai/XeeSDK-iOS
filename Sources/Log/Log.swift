//  Log+default.swift
//  XeeSDK
//
//  Created by Xee team.
//

import XeeLogger
import Foundation

enum Log {
    static var stamp: String {
        XeeLogger.stamp
    }

    nonisolated static func isLevel(_ level: XeeLogger.Level) -> Bool {
        XeeLogger.isLevel(level)
    }

    static func Category(name: String) -> XeeLogger.Category {
        XeeLogger.Category(
            subsystem: "ai.xee",
            version: Xee.SDKVersion,
            name: "sdk"
        )
    }

    static let `default` = Log.Category(name: "sdk")

    static let crossAB = Log.Category(name: "CrossAB")
    static let events = Log.Category(name: "Events")
    static let storage = Log.Category(name: "Storage")
    static let http = Log.Category(name: "API")

    static let fallbackPaywalls = Log.Category(name: "FallbackPaywalls")

    static let storeFront = Log.Category(name: "SKStorefront")
    static let sk2ProductManager = Log.Category(name: "SK2ProductsManager")

    static let sk2TransactionManager = Log.Category(name: "SK2TransactionManager")

}
