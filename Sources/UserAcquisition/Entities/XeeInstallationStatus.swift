//  XeeInstallationStatus.swift
//  Xee
//
//  Created by Aleksei Valiano on 18.06.2025.
//

import Foundation

public enum XeeInstallationStatus: Sendable, Hashable {
    case notAvailable
    case notDetermined
    case determined(XeeInstallationDetails)
}
