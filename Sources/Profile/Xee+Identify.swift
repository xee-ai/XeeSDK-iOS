// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+Identify.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 22.09.2024
//

import Foundation

public extension Xee {
    /// Use this method for identifying user with it's user id in your system.
    ///
    /// If you don't have a user id on SDK configuration, you can set it later at any time with `.identify()` method. The most common cases are after registration/authorization when the user switches from being an anonymous user to an authenticated user.
    ///
    /// - Parameters:
    ///   - customerUserId: User identifier in your system.
    nonisolated static func identify(
        _ customerUserId: String,
        withAppAccountToken appAccountToken: UUID? = nil
    ) async throws(XeeError) {
        let customerUserId = customerUserId.trimmed
        // TODO: throw error if customerUserId isEmpty

        try await withActivatedSDK(methodName: .identify, logParams: [
            "customerUserId": customerUserId,
            "app_account_token": appAccountToken?.uuidString
        ]) { sdk throws(XeeError) in
            try await sdk.identify(toCustomerUserId: customerUserId, withAppAccountToken: appAccountToken)
        }
    }

    /// You can logout the user anytime by calling this method.
    nonisolated static func logout() async throws(XeeError) {
        try await withActivatedSDK(methodName: .logout) { sdk throws(XeeError) in
            try await sdk.logout()
        }
    }
}
