// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Environment.StoreKit.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 25.09.2024
//

import Foundation

extension Environment {
    enum StoreKit {
        static let name = "app_store"

        static let storeKit2Enabled: Bool =
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *) {
                true
            } else {
                false
            }

        @XeeActor
        private static var _lastStorefront: XeeStorefront?

        @XeeActor
        static var storefront: XeeStorefront? {
            get async {
                if let storefront = await XeeStorefront.current {
                    _lastStorefront = storefront
                    return storefront
                } else {
                    return _lastStorefront
                }
            }
        }
    }
}
