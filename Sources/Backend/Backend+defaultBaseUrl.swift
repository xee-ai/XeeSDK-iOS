//  XeeServerKind+.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

extension Backend {
    fileprivate static let basePath = "/api/v1"

    /// The server the SDK talks to: the hosted Xee server. Every kind of request and every cluster
    /// uses it.
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
