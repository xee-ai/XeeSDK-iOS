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

    /// Xee has no built-in server. A kind with no configured URL resolves to a host that can never
    /// resolve (`.invalid` is reserved), so a missing `with(serverUrl:)` fails loudly instead of
    /// sending traffic somewhere unintended.
    static func defaultBaseUrl(kind _: XeeServerKind, by _: XeeServerCluster) -> URL {
        URL(string: "https://xee.invalid\(basePath)")!
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
