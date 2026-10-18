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
    /// The `getProfile` method provides the most up-to-date result as it always tries to query the API. If for some reason (e.g. no internet connection), the Xee SDK fails to retrieve information from the server, the data from cache will be returned. It is also important to note that the Xee SDK updates XeeProfile cache on a regular basis, in order to keep this information as up-to-date as possible.
    nonisolated static func getProfile() async throws(XeeError) -> XeeProfile {
        try await withActivatedSDK(methodName: .getProfile) { sdk throws(XeeError) in
            try await sdk.createdProfileManager.fetchProfile()
        }
    }

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
