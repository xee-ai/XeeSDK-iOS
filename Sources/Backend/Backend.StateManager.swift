//  Backend.StateManager.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

extension Backend {
    @BackendActor
    final class StateManager {
        private let cluster: XeeServerCluster
        private let devBaseUrls: [XeeServerKind: URL]?

        private var mainBaseUrlIndex: Int
        /// The SDK's own API addresses and blocked events; nothing fetches them (the server has no net-config).
        let currentState = BackendState.createDefault()
        private var serverBlockedByKind = Set<XeeServerKind>()
        private var requestBlockedUntil = [BackendRequestName: Date]()

        init(with configuration: XeeConfiguration) {
            let backend = configuration.backend
            cluster = backend.cluster
            devBaseUrls = backend.devBaseUrls
            mainBaseUrlIndex = 0
        }

        private func checkIsBlocked(
            for serverKind: XeeServerKind
        ) throws(BackendUnavailableError) {
            switch serverKind {
            case .ua:
                guard !serverBlockedByKind.contains(.main),
                      !serverBlockedByKind.contains(serverKind)
                else { throw .unauthorized }
            default:
                guard !serverBlockedByKind.contains(.main) else { throw .unauthorized }
            }

            if serverKind == .main, !currentState.mainBaseUrlsExist(by: cluster) {
                throw .blockedUntil(nil)
            }
        }

        private func checkIsBlocked(
            _ requestName: BackendRequestName,
            for serverKind: XeeServerKind
        ) throws(BackendUnavailableError) {
            try checkIsBlocked(for: serverKind)
            if let expiresAt = requestBlockedUntil[requestName], expiresAt > Date() {
                throw .blockedUntil(expiresAt)
            }
        }

        private func handleNetworkError(
            _ serverKind: XeeServerKind,
            _ requestName: BackendRequestName,
            _ error: HTTPError
        ) {
            guard case .backend(_, _, _, _, _, let error) = error,
                  let error = error as? BackendUnavailableError
            else { return }

            switch error {
            case .unauthorized:
                serverBlockedByKind.insert(serverKind)
            case .blockedUntil(let expiresAt):
                guard let expiresAt else { return }
                if let oldExpiresAt = requestBlockedUntil[requestName],
                   oldExpiresAt > expiresAt { return }
                requestBlockedUntil[requestName] = expiresAt
            }
        }

        private func handleIsServerUnavailable(
            _ serverKind: XeeServerKind,
            _ baseUrl: URL,
            _ error: HTTPError
        ) {
            guard serverKind == .main,
                  error.isServerUnavailable,
                  baseUrl == currentState.mainBaseUrl(by: cluster, withIndex: mainBaseUrlIndex)
            else { return }

            mainBaseUrlIndex += 1
        }
    }
}

extension Backend.StateManager {
    func handleNetworkState(
        _ serverKind: XeeServerKind,
        _ requestName: BackendRequestName,
        _ baseUrl: URL,
        _ error: HTTPError
    ) {
        handleNetworkError(serverKind, requestName, error)
        handleIsServerUnavailable(serverKind, baseUrl, error)
    }

    func fetchCurrentState() async -> BackendState {
        currentState
    }

    func baseUrl(
        _ request: BackendRequest,
        for serverKind: XeeServerKind
    ) async throws(BackendUnavailableError) -> URL {
        try checkIsBlocked(request.requestName, for: serverKind)
        guard serverKind == .main else {
            return devBaseUrls[serverKind, with: cluster]
        }
        if let url = devBaseUrls?[serverKind] { return url }

        guard let url = currentState.mainBaseUrl(by: cluster, withIndex: mainBaseUrlIndex) else {
            throw .blockedUntil(nil)
        }
        return url
    }
}
