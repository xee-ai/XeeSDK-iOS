// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Backend.FallbackExecutor.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 02.10.2024
//

import Foundation

extension Backend {
    struct FallbackExecutor: BackendExecutor {
        let manager: StateManager
        let session: HTTPSession
        let kind = XeeServerKind.fallback
    }

    func createFallbackExecutor() -> FallbackExecutor {
        FallbackExecutor(
            manager: networkManager,
            session: HTTPSession(configuration: fallbackHTTPConfiguration)
        )
    }
}
