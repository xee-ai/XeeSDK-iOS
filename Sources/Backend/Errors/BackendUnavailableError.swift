//  BackendUnavailableError.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

public enum BackendUnavailableError: Error, Hashable, Codable {
    case unauthorized
    case blockedUntil(Date?)
}
