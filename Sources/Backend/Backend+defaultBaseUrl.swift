// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeServerKind+.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 12.11.2025.
//

import Foundation

extension Backend {
    fileprivate static let basePath = "/api/v1"

    /// The server the SDK talks to unless `with(serverUrl:)` says otherwise: the hosted Xee server.
    /// To use a server on your own machine, pass `with(serverUrl:)` (the iOS Simulator reaches the
    /// Mac as `localhost`). Every kind of request and every cluster uses it.
    static let defaultServerUrl = "https://api.xee.ai"

    static func defaultBaseUrl(kind _: XeeServerKind, by _: XeeServerCluster) -> URL {
        URL(string: "\(defaultServerUrl)\(basePath)")!
    }
}

extension URL {
    var appendingDefaultPathIfNeed: Self {
        guard path.isEmpty || path == "/" else { return self }
        return appendingPathComponent(Backend.basePath)
    }
}

extension [XeeServerKind: URL] {
    subscript(_ kind: XeeServerKind, with cluster: XeeServerCluster) -> URL {
        self[kind] ?? Backend.defaultBaseUrl(kind: kind, by: cluster)
    }
}

extension [XeeServerKind: URL]? {
    subscript(_ kind: XeeServerKind, with cluster: XeeServerCluster) -> URL {
        self?[kind] ?? Backend.defaultBaseUrl(kind: kind, by: cluster)
    }
}
