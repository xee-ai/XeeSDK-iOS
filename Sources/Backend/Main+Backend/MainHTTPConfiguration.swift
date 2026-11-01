//  MainHTTPConfiguration.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

struct MainHTTPConfiguration: HTTPCodableConfiguration {
    let sessionConfiguration: URLSessionConfiguration

    /// A profile read not answered after one second is sent again on its own connection. About 0.7 % of 3,000 reads took
    /// longer than that on a Wi-Fi that stalls about 1 % of them, so about that share is sent twice.
    let hedgeReadsAfter: TaskDuration? = .seconds(1)

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
