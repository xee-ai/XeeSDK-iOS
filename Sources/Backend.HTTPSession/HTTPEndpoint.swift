//  HTTPEndpoint.swift
//  XeeSDK
//
//  Created by Xee team.
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
