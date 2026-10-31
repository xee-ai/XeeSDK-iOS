//  Handler.swift
//  XeeLogger
//
//  Created by Aleksei Valiano on 23.10.2022.
//

import Foundation

public extension XeeLogger {
    typealias Handler = @Sendable (Record) -> Void
}
