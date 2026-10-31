//  NetworkState.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 24.09.2022.
//

import Foundation

struct BackendState: Sendable {
    let eventBlacklist: Set<String>
    let mainBaseUrls: [XeeServerCluster: [URL]]
}

extension BackendState {
    static func createDefault() -> Self {
        .init(
            eventBlacklist: Event.defaultBlackList,
            mainBaseUrls: [
                .default: [Backend.defaultBaseUrl(kind: .main, by: .default)],
                .eu: [Backend.defaultBaseUrl(kind: .main, by: .eu)],
                .cn: [Backend.defaultBaseUrl(kind: .main, by: .cn)]
            ]
        )
    }

    func mainBaseUrlsExist(by cluster: XeeServerCluster) -> Bool {
        guard let baseUrls = mainBaseUrls(by: cluster),
              baseUrls.isNotEmpty
        else { return false }
        return true
    }

    private func mainBaseUrls(by cluster: XeeServerCluster) -> [URL]? {
        if let baseUrls = mainBaseUrls[cluster] { return baseUrls }
        guard cluster != .default else { return nil }
        return mainBaseUrls[.default]
    }

    func mainBaseUrl(by cluster: XeeServerCluster, withIndex index: Int) -> URL? {
        guard let baseUrls = mainBaseUrls(by: cluster),
              baseUrls.isNotEmpty
        else { return nil }

        guard baseUrls.indices.contains(index) else {
            return baseUrls.last?.appendingDefaultPathIfNeed
        }

        return baseUrls[index].appendingDefaultPathIfNeed
    }
}
