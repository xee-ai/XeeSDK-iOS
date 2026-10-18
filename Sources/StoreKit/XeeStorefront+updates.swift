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
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *) {
                await XeeStorefront.StoreKit2.current
            } else {
                await XeeStorefront.StoreKit1.current
            }
        }
    }

    static var updates: AsyncStream<XeeStorefront> {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *) {
            XeeStorefront.StoreKit2.updates
        } else {
            XeeStorefront.StoreKit1.updates
        }
    }
}
