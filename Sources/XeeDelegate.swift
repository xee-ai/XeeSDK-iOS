// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeDelegate.swift
//  XeeSDK
//
//  Created by Andrey Kyashkin on 28.10.2019.
//

import Foundation

public protocol XeeDelegate: AnyObject, Sendable {
    /// Implement this delegate method to receive automatic profile updates
    func didLoadLatestProfile(_ profile: XeeProfile)

    func onInstallationDetailsSuccess(_ details: XeeInstallationDetails)

    func onInstallationDetailsFail(error: XeeError)

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    func onUnfinishedTransaction(_ xeeUnfinishedTransaction: XeeUnfinishedTransaction)
}

public extension XeeDelegate {
    func onInstallationDetailsSuccess(_ details: XeeInstallationDetails) {}
    func onInstallationDetailsFail(error: XeeError) {}

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    func onUnfinishedTransaction(_ xeeUnfinishedTransaction: XeeUnfinishedTransaction) {}
}

extension Xee {
    /// Set the delegate to listen for `XeeProfile` updates and user initiated an in-app purchases
    public nonisolated(unsafe) static var delegate: XeeDelegate?

    static func callDelegate(_ call: @Sendable @escaping (XeeDelegate) -> Void) {
        guard let delegate = Xee.delegate else { return }
        let queue = XeeConfiguration.callbackDispatchQueue ?? .main
        queue.async {
            call(delegate)
        }
    }
}
