//  HTTPRequest+URLRequest.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

private enum HeaderKey {
    static let contentType: String = "Content-Type"
}

extension HTTPRequest {
    func convertToURLRequest(baseUrl: URL, configuration: HTTPConfiguration) throws -> URLRequest {
        let preUrl = baseUrl.appendingPathComponent(endpoint.path)

        guard var urlComponents = URLComponents(url: preUrl, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        if queryItems.isNotEmpty {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(
            url: url,
            cachePolicy: cachePolicy ?? .useProtocolCachePolicy,
            timeoutInterval: timeoutInterval ?? 60.0
        )

        request.httpMethod = endpoint.method.rawValue
        // api.xee.ai speaks HTTP/3: QUIC sets up the connection and TLS in one round trip instead of
        // TCP's two, and the ephemeral session would forget the server's alt-svc on every launch.
        // Where UDP is blocked, URLSession falls back to TCP.
        request.assumesHTTP3Capable = true

        headers.forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        if let dataRequest = self as? HTTPDataRequest {
            let httpBody = try dataRequest.getData(configuration: configuration)
            request.httpBody = httpBody

            if let contentType = dataRequest.contentType
                ?? (configuration as? HTTPCodableConfiguration)?.defaultEncodedContentType,
                request.value(forHTTPHeaderField: HeaderKey.contentType).isEmpty
            {
                request.setValue(contentType, forHTTPHeaderField: HeaderKey.contentType)
            }
        }

        return request
    }
}
