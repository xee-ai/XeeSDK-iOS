//  MainHTTPConfiguration.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

struct MainHTTPConfiguration: HTTPCodableConfiguration {
    let sessionConfiguration: URLSessionConfiguration

    /// Above the p95 of a profile read (about 0.2 to 0.3 s over 3,000 reads), so about 2 to 3 % of reads are sent twice.
    let hedgeReadsAfter: TaskDuration? = .milliseconds(350)

    let defaultEncodedContentType = "application/vnd.api+json"

    func configure(jsonDecoder: JSONDecoder) { Backend.configure(jsonDecoder: jsonDecoder) }
    func configure(jsonEncoder: JSONEncoder) { Backend.configure(jsonEncoder: jsonEncoder) }

    init(with configuration: XeeConfiguration, environment: Environment) {
        let backend = configuration.backend

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.httpAdditionalHeaders = Backend.Request.globalHeadersWithStoreKit(configuration, environment)
        sessionConfiguration.timeoutIntervalForRequest = 30
        sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
        sessionConfiguration.protocolClasses = (backend.protocolClasses ?? []) + (sessionConfiguration.protocolClasses ?? [])

        if let (host, port) = backend.proxy {
            sessionConfiguration.connectionProxyDictionary = [
                String(kCFNetworkProxiesHTTPEnable): NSNumber(value: 1),
                String(kCFNetworkProxiesHTTPProxy): host,
                String(kCFNetworkProxiesHTTPPort): port,
            ]
        }

        self.sessionConfiguration = sessionConfiguration
    }
}
