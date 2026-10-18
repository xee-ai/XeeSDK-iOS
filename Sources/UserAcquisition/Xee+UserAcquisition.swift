// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+UserAcquisition.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 18.06.2025.
//

import Foundation

public extension Xee {
    nonisolated static func getCurrentInstallationStatus() async throws(XeeError) -> XeeInstallationStatus {
        try await withActivatedSDK(
            methodName: .getCurrentInstallationStatus
        ) { _ in
            guard let manager = UserAcquisitionManager.shared
            else { return .notAvailable }
            return await manager.getCurrentInstallationStatus()
        }
    }

    internal static func applicationDidBecomeActive() {
        UserAcquisitionManager.shared?.startRegisterInstallTaskIfNeeded()
    }
}
