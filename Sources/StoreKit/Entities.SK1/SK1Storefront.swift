// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SK1Storefront.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2024
//

import StoreKit

typealias SK1Storefront = SKStorefront

extension SK1Storefront {
    var asXeeStorefront: XeeStorefront {
        .init(id: identifier, countryCode: countryCode)
    }
}

private let log = Log.storeFront

extension XeeStorefront {
    enum StoreKit1 {
        static var current: XeeStorefront? {
            get async {
                await MainActor.run {
                    SKPaymentQueue.default().storefront?.asXeeStorefront
                }
            }
        }

        static var updates: AsyncStream<XeeStorefront> {
            AsyncStream<XeeStorefront> { continuation in
                #if os(visionOS)
                continuation.finish()
                #else
                Task<Void, Never> {
                    NotificationCenter.default.addObserver(
                        forName: Notification.Name.SKStorefrontCountryCodeDidChange,
                        object: nil,
                        queue: nil
                    ) { _ in
                        if let storefront = SKPaymentQueue.default().storefront {
                            log.verbose("Notifications SKStorefrontCountryCodeDidChange: value is \(storefront)")
                            continuation.yield(storefront.asXeeStorefront)
                        } else {
                            log.warn("Notifications SKStorefrontCountryCodeDidChange: value is nil")
                        }
                    }
                }
                #endif
            }
        }
    }
}
