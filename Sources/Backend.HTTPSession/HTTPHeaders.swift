// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  HTTPHeaders.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 26.08.2024
//
//

import Foundation

typealias HTTPHeaders = [String: String]

extension HTTPHeaders {
    @inlinable
    func header(forHTTPHeaderField field: String) -> Element? {
        first { key, _ in
            key.caseInsensitiveCompare(field) == .orderedSame
        }
    }

    @inlinable
    func value(forHTTPHeaderField field: String) -> String? {
        header(forHTTPHeaderField: field).map(\.value)
    }
}

extension HTTPHeaders {
    init(_ other: [AnyHashable: Any]) {
        self.init(
            other.compactMap { key, value in
                guard let key = key as? String, let value = value as? String else { return nil }
                return (key, value)
            }
        ) { $1 }
    }
}
