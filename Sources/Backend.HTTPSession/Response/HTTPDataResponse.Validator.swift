//  HTTPDataResponse.Validator.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

extension HTTPDataResponse {
    typealias Validator = @Sendable (HTTPDataResponse) -> Error?
    static let defaultValidator: Validator = statusCodeValidator

    @Sendable
    static func statusCodeValidator(_ response: HTTPDataResponse) -> Error? {
        200 ... 299 ~= response.statusCode ? nil : URLError(.badServerResponse)
    }
}
