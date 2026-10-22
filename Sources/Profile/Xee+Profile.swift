// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+Profile.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 22.09.2024
//

import Foundation

public extension Xee {
    /// The main function for getting a user profile. Allows you to define the level of access, as well as other parameters.
    ///
    /// Returns the saved profile without a network call when the server confirmed it less than `maxAge`
    /// seconds ago (5 minutes by default); otherwise it asks the server, and falls back to the saved profile
    /// if the server cannot be reached.
    ///
    /// The saved profile is refreshed by every purchase, restore and profile update, and by the SDK's
    /// own sync about once a minute while the app is open. The SDK asks the server anyway on the first call
    /// after launch, `identify` or `logout`, and when an access level it reports as active has reached its
    /// `expiresAt`. So a change made on the server (a refund, access turned off in the dashboard) can reach
    /// the app up to `maxAge` late; access never outlives its end date.
    ///
    /// - Parameter maxAge: How old, in seconds, the saved profile may be. Pass `0` to always ask the server.
    nonisolated static func getProfile(maxAge: TimeInterval = defaultProfileMaxAge) async throws(XeeError) -> XeeProfile {
        try await withActivatedSDK(methodName: .getProfile) { sdk throws(XeeError) in
            try await sdk.createdProfileManager.fetchProfile(maxAge: maxAge)
        }
    }

    /// How old, in seconds, the saved profile may be when ``getProfile(maxAge:)`` is called without `maxAge`.
    nonisolated static let defaultProfileMaxAge: TimeInterval = 300

    /// You can set optional attributes such as email, phone number, etc, to the user of your app. You can then use attributes to create user [segments](https://xee.invalid/docs) or just view them in CRM.
    ///
    /// Read more on the [Xee Documentation](https://xee.invalid/docs)
    ///
    /// - Parameter params: use `XeeProfileParameters.Builder` class to build this object.
    nonisolated static func updateProfile(params: XeeProfileParameters) async throws(XeeError) {
        try await withActivatedSDK(methodName: .updateProfile) { sdk throws(XeeError) in
            _ = try await sdk.createdProfileManager.updateProfile(params: params)
        }
    }
}
