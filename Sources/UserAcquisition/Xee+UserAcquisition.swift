//  Xee+UserAcquisition.swift
//  XeeSDK
//
//  Created by Xee team.
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
