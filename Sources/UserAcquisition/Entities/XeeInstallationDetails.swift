//  XeeInstallationDetails.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

public struct XeeInstallationDetails: Sendable, Hashable {
    public let id: String?
    public let installTime: Date
    public let appLaunchCount: Int
    public let payload: Payload?
}
