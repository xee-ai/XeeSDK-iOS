// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  HTTPEndpoint.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 22.09.2022.
//

import Foundation

struct HTTPEndpoint: Sendable, Hashable {
    typealias Path = String
    let method: HTTPMethod
    let path: Path
}

extension HTTPEndpoint: CustomStringConvertible {
    var description: String { "\(method) \(path)" }
}
