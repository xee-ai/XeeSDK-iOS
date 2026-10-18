// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Category.swift
//  XeeLogger
//
//  Created by Aleksei Valiano on 24.08.2024
//

import Foundation

extension XeeLogger {
    public struct Category: Sendable, Hashable {

        public let subsystem: String
        public let version: String
        public let name: String

        package init(subsystem: String? = nil, version: String, name: String) {
            self.subsystem = subsystem ?? "ai.xee"
            self.version = version
            self.name = name
        }
    }
}

extension XeeLogger.Category: CustomStringConvertible {
    public var description: String {
        if name == "sdk" {
            "[\(subsystem) v\(version)]"
        } else {
            "[\(subsystem) v\(version)] #\(name)#"
        }
    }
}
