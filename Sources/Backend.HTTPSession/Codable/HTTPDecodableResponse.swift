//  HTTPDecodableResponse.swift
//  XeeSDK
//
//  Created by Xee team.
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
