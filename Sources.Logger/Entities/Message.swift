//  Message.swift
//  XeeLogger
//
//  Created by Xee team.
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
