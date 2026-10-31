//  Backend.UAExecuter.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

extension Backend {
    struct UAExecutor: BackendExecutor {
        let manager: StateManager
        let session: HTTPSession
        let kind = XeeServerKind.ua
    }

    func createUAExecutor() -> UAExecutor {
        UAExecutor(
            manager: networkManager,
            session: HTTPSession(configuration: uaHTTPConfiguration, responseValidator: validator)
        )
    }
}

extension Backend.UAExecutor {
    func canRetryRequest(_ error: HTTPError) -> Bool {
        switch error {
        case .perform:
            false
        case let .network(_, _, _, error: error):
            (error as NSError).isNetworkConnectionError
        case let .decoding(_, _, statusCode, _, _, _),
             let .backend(_, _, statusCode, _, _, _):
            switch statusCode {
            case 429, 499, 500 ... 599:
                true
            case 400 ... 499:
                false
            default:
                true
            }
        }
    }
}
