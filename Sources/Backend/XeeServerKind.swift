// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeServerKind.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 12.11.2025.
//

import Foundation

package enum XeeServerKind: Sendable, CaseIterable {
    case main
    case fallback
    case configs
    case ua
}
