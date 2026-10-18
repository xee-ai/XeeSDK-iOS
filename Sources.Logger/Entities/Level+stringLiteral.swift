// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Level+stringLiteral.swift
//  XeeLogger
//
//  Created by Aleksei Valiano on 22.08.2024
//

import Foundation

extension XeeLogger.Level: ExpressibleByStringLiteral {
    enum CodingValues: String {
        case error
        case warn
        case info
        case verbose
        case debug
    }

    public init(stringLiteral value: String) {
        self =
            switch CodingValues(rawValue: value.lowercased()) {
            case nil: .default
            case .error: .error
            case .warn: .warn
            case .info: .info
            case .verbose: .verbose
            case .debug: .debug
            }
    }

    var stringLiteral: String {
        let value: CodingValues =
            switch self {
            case .error: .error
            case .warn: .warn
            case .info: .info
            case .verbose: .verbose
            case .debug: .debug
            }
        return value.rawValue
    }
}

extension XeeLogger.Level: CustomStringConvertible {
    public var description: String { stringLiteral.uppercased() }
}
