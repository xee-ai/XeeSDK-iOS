//  XeeInstallationDetails.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 17.06.2025.
//

import Foundation

public struct XeeInstallationDetails: Sendable, Hashable {
    public let id: String?
    public let installTime: Date
    public let appLaunchCount: Int
    public let payload: Payload?
}
