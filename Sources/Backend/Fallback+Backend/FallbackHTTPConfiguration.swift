// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  FallbackHTTPConfiguration.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 08.09.2022.
//

import Foundation

struct FallbackHTTPConfiguration: HTTPCodableConfiguration {
    let sessionConfiguration: URLSessionConfiguration

    func configure(jsonDecoder: JSONDecoder) { Backend.configure(jsonDecoder: jsonDecoder) }
    func configure(jsonEncoder: JSONEncoder) { Backend.configure(jsonEncoder: jsonEncoder) }

    init(with configuration: XeeConfiguration) {
        let backend = configuration.backend

        let sessionConfiguration = URLSessionConfiguration.ephemeral
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
