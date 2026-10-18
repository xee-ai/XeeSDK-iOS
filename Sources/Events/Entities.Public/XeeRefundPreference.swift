// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
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
