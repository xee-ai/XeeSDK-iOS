// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeError.Source.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 20.09.2022.
//

import Foundation

public extension XeeError {
    struct Source: Sendable, Hashable {
        public let version = Xee.SDKVersion
        public let file: String
        public let function: String
        public let line: UInt

        public init(file: String = #fileID, function: String = #function, line: UInt = #line) {
            self.file = file
            self.function = function
            self.line = line
        }
    }
}

extension XeeError.Source: CustomStringConvertible {
    public var description: String { "[\(version)]: \(file)#\(line)" }
}
