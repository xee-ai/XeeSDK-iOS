//  XeeRefundPreference.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

public enum XeeRefundPreference: String, Sendable {
    case noPreference = "no_preference"
    case grant
    case decline
}

extension XeeRefundPreference: Codable {}
