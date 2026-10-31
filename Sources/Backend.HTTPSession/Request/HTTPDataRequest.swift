//  HTTPDataRequest.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

protocol HTTPDataRequest: HTTPRequest {
    var contentType: String? { get }
    func getData(configuration: HTTPConfiguration) throws -> Data?
}

extension HTTPDataRequest {
    var contentType: String? { nil }
}
