// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Message.swift
//  XeeLogger
//
//  Created by Aleksei Valiano on 22.08.2024
//

import Foundation

package extension XeeLogger {
    struct Message: Sendable, Hashable, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
        package typealias StringLiteralType = String

        package let value: String

        @inlinable
        package init(stringLiteral value: String) {
            self.value = value
        }
    }
}
