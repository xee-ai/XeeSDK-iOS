//  Backend.EventsExecutor.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

extension Backend {
    struct EventsExecutor: BackendExecutor {
        let manager: StateManager
        let session: HTTPSession
        let kind = XeeServerKind.main
    }

    func createEventsExecutor() -> EventsExecutor {
        EventsExecutor(
            manager: networkManager,
            session: HTTPSession(configuration: defaultHTTPConfiguration, responseValidator: validator)
        )
    }
}
