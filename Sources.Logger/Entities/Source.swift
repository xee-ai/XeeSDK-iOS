// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Source.swift
//  XeeLogger
//
//  Created by Aleksei Valiano on 24.08.2024
//

import Foundation

public extension XeeLogger {
    struct Source: Equatable, Sendable {
        public let fileName: String
        public let functionName: String
        public let lineNumber: UInt
    }
}

extension XeeLogger.Source: CustomStringConvertible {
    public var description: String { "\(fileName)#\(lineNumber)" }
}
