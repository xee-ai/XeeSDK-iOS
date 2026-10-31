//  XeeStorefront+updates.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

public extension XeeStorefront {
    static var current: XeeStorefront? {
        get async {
            await XeeStorefront.StoreKit2.current
        }
    }

    static var updates: AsyncStream<XeeStorefront> {
        XeeStorefront.StoreKit2.updates
    }
}
