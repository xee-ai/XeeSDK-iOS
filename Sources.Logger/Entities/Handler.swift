//  Handler.swift
//  XeeLogger
//
//  Created by Xee team.
//

import Foundation

public extension XeeLogger {
    typealias Handler = @Sendable (Record) -> Void
}
