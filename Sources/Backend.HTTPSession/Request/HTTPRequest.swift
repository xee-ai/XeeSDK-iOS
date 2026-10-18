// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  HTTPRequest.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 11.08.2022.
//

import Foundation

protocol HTTPRequest: Sendable {
    var endpoint: HTTPEndpoint { get }
    var headers: HTTPHeaders { get }
    var queryItems: QueryItems { get }
    var cachePolicy: URLRequest.CachePolicy? { get }
    var timeoutInterval: TimeInterval? { get }
    var stamp: String { get }
}

extension HTTPRequest {
    var path: HTTPEndpoint.Path { endpoint.path }
    var method: HTTPMethod { endpoint.method }
    var headers: HTTPHeaders { [:] }
    var queryItems: QueryItems { [] }
    var cachePolicy: URLRequest.CachePolicy? { nil }
    var timeoutInterval: TimeInterval? { nil }
}
