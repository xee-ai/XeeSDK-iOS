// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  HTTPDecodableResponse.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 26.11.2025.
//

import Foundation

typealias HTTPDecodableResponse<Body: Decodable> = HTTPResponse<Body>

extension HTTPDecodableResponse {
    static func decodableBodyDecoder(
        _ response: HTTPDataResponse,
        _ configuration: HTTPCodableConfiguration?,
        _ request: HTTPRequest
    ) async throws -> HTTPResponse<Body> {
        try response.replaceBody(response.decodeBody(Body.self, with: configuration))
    }
}

extension HTTPSession {
    func perform<Body: Decodable & Sendable>(
        _ request: HTTPRequest,
        baseUrl: URL
    ) async throws(HTTPError) -> HTTPResponse<Body> {
        try await perform(request, withBaseUrl: baseUrl, withDecoder: HTTPDecodableResponse.decodableBodyDecoder)
    }
}
