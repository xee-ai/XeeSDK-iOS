// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  MainHTTPConfiguration.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 10.11.2025.
//

import Foundation

struct MainHTTPConfiguration: HTTPCodableConfiguration {
    let sessionConfiguration: URLSessionConfiguration

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
