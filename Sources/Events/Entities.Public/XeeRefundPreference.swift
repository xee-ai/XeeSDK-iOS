//  XeeRefundPreference.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 19.03.2025.
//

import Foundation

public enum XeeRefundPreference: String, Sendable {
    case noPreference = "no_preference"
    case grant
    case decline
}

extension XeeRefundPreference: Codable {}
