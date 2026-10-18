// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+SetIntegrationIdentifier.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 26.11.2024.
//

import Foundation

extension Xee {
    public nonisolated static func setIntegrationIdentifier(
        key: String,
        value: String
    ) async throws(XeeError) {
        let key = key.trimmed
        let value = value.trimmed
        // TODO: throw error if key isEmpty

        try await setIntegrationIdentifiers([key: value])
    }

    package nonisolated static func setIntegrationIdentifiers(
        _ keyValues: [String: String]
    ) async throws(XeeError) {
        try await withActivatedSDK(methodName: .setIntegrationIdentifiers, logParams: keyValues) { sdk throws(XeeError) in
            try await sdk.setIntegrationIdentifier(
                keyValues: keyValues
            )
        }
    }

    func setIntegrationIdentifier(
        keyValues: [String: String]
    ) async throws(XeeError) {
        let userId = try await createdProfileManager.userId

        do {
            try await httpSession.setIntegrationIdentifier(
                userId: userId,
                keyValues: keyValues
            )
        } catch {
            throw error.asXeeError
        }
    }
}
