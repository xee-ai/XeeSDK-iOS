// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+SyncIPv4.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 19.12.2023
//

import Foundation

extension XeeConfiguration {
    @XeeActor
    static var ipAddressCollectionDisabled = Self.default.ipAddressCollectionDisabled
}

extension Environment.Device {
    @XeeActor
    static var ipV4Address: String?
}

extension Xee {
    private static var syncIPv4Started = false

    func startSyncIPv4OnceIfNeeded() {
        guard !XeeConfiguration.ipAddressCollectionDisabled,
              Environment.Device.ipV4Address == nil,
              !Xee.syncIPv4Started
        else { return }

        Xee.syncIPv4Started = true

        Task.detached(priority: .utility) { @XeeActor @Sendable [weak self] in
            defer { Xee.syncIPv4Started = false }
            let value = try await Xee.cachedIPv4OrFetch()
            _ = try await self?.createdProfileManager.updateProfile(
                params: XeeProfileParameters(ipV4Address: value)
            )
        }
    }

    private static func cachedIPv4OrFetch() async throws -> String {
        if let value = Environment.Device.ipV4Address { return value }
        let value = try await fetchIPv4()
        Environment.Device.ipV4Address = value
        return value
    }

    private static func fetchIPv4() async throws -> String {
        var attemptsCount: UInt64 = 0
        while !Task.isCancelled {
            do {
                let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.ipify.org?format=json")!)
                struct FetchIPv4Response: Decodable { let ip: String }
                let response = try JSONDecoder().decode(FetchIPv4Response.self, from: data)
                return response.ip
            } catch {
                guard let error = error as? URLError, error.shouldRetry else { throw error }
                attemptsCount += 1
                try await Task.sleep(duration: .seconds(min(attemptsCount, 10)))
            }
        }
        throw CancellationError()
    }
}

private extension URLError {
    var shouldRetry: Bool {
        switch self.code {
        case .timedOut,
             .cannotFindHost,
             .cannotConnectToHost,
             .networkConnectionLost,
             .dnsLookupFailed,
             .notConnectedToInternet,
             .resourceUnavailable,
             .backgroundSessionWasDisconnected:
            return true
        default:
            return false
        }
    }
}
