// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  HTTPStringResponse.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 26.08.2024
//

import Foundation

typealias HTTPStringResponse = HTTPResponse<String?>

extension HTTPDataResponse {
    var asHTTPStringResponse: HTTPStringResponse {
        replaceBody(body.flatMap { String(data: $0, encoding: .utf8) })
    }
}

extension HTTPStringResponse {
    static func stringDecoder(
        _ response: HTTPDataResponse,
        _ configuration: HTTPCodableConfiguration?,
        _ request: HTTPRequest
    ) async throws -> HTTPStringResponse {
        response.asHTTPStringResponse
    }
}

extension HTTPSession {
    func perform(_ request: some HTTPRequest, baseUrl: URL) async throws(HTTPError) -> HTTPStringResponse {
        try await perform(request, withBaseUrl: baseUrl, withDecoder: HTTPStringResponse.stringDecoder)
    }
}
