// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Backend.ConfigsExecutor.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 02.10.2024
//

import Foundation

extension Backend {
    struct ConfigsExecutor: BackendExecutor {
        let manager: StateManager
        let session: HTTPSession
        let kind = XeeServerKind.configs
    }

    func createConfigsExecutor() -> ConfigsExecutor {
        ConfigsExecutor(
            manager: networkManager,
            session: HTTPSession(configuration: defaultHTTPConfiguration)
        )
    }
}
