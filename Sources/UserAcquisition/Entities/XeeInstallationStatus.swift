//  XeeInstallationStatus.swift
//  Xee
//
//  Created by Xee team.
//

import Foundation

public enum XeeInstallationStatus: Sendable, Hashable {
    case notAvailable
    case notDetermined
    case determined(XeeInstallationDetails)
}
