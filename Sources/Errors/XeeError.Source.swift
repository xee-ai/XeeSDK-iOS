//  XeeError.Source.swift
//  XeeSDK
//
//  Created by Xee team.
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
