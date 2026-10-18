// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  HTTPDataResponse.Validator.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2022.
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
