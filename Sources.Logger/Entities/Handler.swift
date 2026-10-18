// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Handler.swift
//  XeeLogger
//
//  Created by Aleksei Valiano on 23.10.2022.
//

import Foundation

public extension XeeLogger {
    typealias Handler = @Sendable (Record) -> Void
}
