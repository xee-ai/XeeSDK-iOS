//  Backend.DefaultExecutor.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

extension Backend {
    struct MainExecutor: BackendExecutor {
        let manager: Backend.StateManager
        let session: HTTPSession
        let kind = XeeServerKind.main
    }

    func createDefaultExecutor() -> MainExecutor {
        MainExecutor(
            manager: networkManager,
            session: HTTPSession(configuration: defaultHTTPConfiguration, responseValidator: validator)
        )
    }
}
