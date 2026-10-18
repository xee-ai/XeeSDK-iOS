// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+CodeRedemptionSheet.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.05.2023
//

import StoreKit

private let log = Log.default

public extension Xee {
    /// Call this method to have StoreKit present a sheet enabling the user to redeem codes provided by your app.
    nonisolated static func presentCodeRedemptionSheet() {
        Task.detached { @MainActor in
            let stamp = Log.stamp
            let name = MethodName.presentCodeRedemptionSheet
            var error: String?

            Xee.trackSystemEvent(XeeSDKMethodRequestParameters(methodName: name, stamp: stamp))

            #if (os(iOS) || os(visionOS)) && !targetEnvironment(macCatalyst)
            if #available(iOS 14.0, visionOS 1.0, *) {
                SKPaymentQueue.default().presentCodeRedemptionSheet()
            } else {
                error = "Presenting code redemption sheet is available only for iOS 14 and higher."
            }
            #else
            error = "Presenting code redemption sheet is available only for iOS 14 and higher."
            #endif

            if let error { log.error(error) }
            Xee.trackSystemEvent(XeeSDKMethodResponseParameters(methodName: name, stamp: stamp, error: error))
        }
    }
}
