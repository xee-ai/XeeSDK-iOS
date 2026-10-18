// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SK2Storefront.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2024
//

import StoreKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
typealias SK2Storefront = Storefront

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
extension SK2Storefront {
    var asXeeStorefront: XeeStorefront {
        .init(id: id, countryCode: countryCode)
    }
}

private let log = Log.storeFront

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
extension XeeStorefront {
    enum StoreKit2 {
        static var current: XeeStorefront? {
            get async {
                await SK2Storefront.current?.asXeeStorefront
            }
        }

        static var updates: AsyncStream<XeeStorefront> {
            AsyncStream<XeeStorefront> { continuation in
                Task {
                    for await storefront in SK2Storefront.updates {
                        log.verbose("StoreKit2 Storefront.updates new value: \(storefront)")
                        continuation.yield(storefront.asXeeStorefront)
                    }
                    continuation.finish()
                }
            }
        }
    }
}
