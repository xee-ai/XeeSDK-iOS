// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
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
