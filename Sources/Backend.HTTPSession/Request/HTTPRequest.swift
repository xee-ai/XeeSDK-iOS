//  HTTPRequest.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

protocol HTTPRequest: Sendable {
    var endpoint: HTTPEndpoint { get }
    var headers: HTTPHeaders { get }
    var queryItems: QueryItems { get }
    var cachePolicy: URLRequest.CachePolicy? { get }
    var timeoutInterval: TimeInterval? { get }
    /// Safe to send twice, and the app has a saved answer to fall back on (the profile GET): it waits for the server
    /// 5 seconds (2 after a timeout, `FailFastTimeout`) and is sent a second time when it is slow (`hedgeReadsAfter`).
    var isQuickRead: Bool { get }
    var stamp: String { get }
}

extension HTTPRequest {
    var path: HTTPEndpoint.Path { endpoint.path }
    var method: HTTPMethod { endpoint.method }
    var headers: HTTPHeaders { [:] }
    var queryItems: QueryItems { [] }
    var cachePolicy: URLRequest.CachePolicy? { nil }
    var timeoutInterval: TimeInterval? { nil }
    var isQuickRead: Bool { false }
}
