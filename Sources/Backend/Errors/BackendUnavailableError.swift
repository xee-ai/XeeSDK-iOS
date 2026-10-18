// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  BackendUnavailableError.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 13.11.2025.
//

import Foundation

public enum BackendUnavailableError: Error, Hashable, Codable {
    case unauthorized
    case blockedUntil(Date?)
}
