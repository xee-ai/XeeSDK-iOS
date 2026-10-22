// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeStorefront+updates.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2024
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
