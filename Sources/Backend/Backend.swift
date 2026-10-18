// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Backend.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 08.09.2022.
//

import Foundation

package struct Backend {
    let networkManager: StateManager

    let defaultHTTPConfiguration: HTTPCodableConfiguration
    let uaHTTPConfiguration: HTTPCodableConfiguration
    let fallbackHTTPConfiguration: HTTPCodableConfiguration
    var configsHTTPConfiguration: HTTPCodableConfiguration { fallbackHTTPConfiguration }

    init(
        with configuration: XeeConfiguration,
        environment: Environment
    ) async {
        defaultHTTPConfiguration = MainHTTPConfiguration(with: configuration, environment: environment)
        fallbackHTTPConfiguration = FallbackHTTPConfiguration(with: configuration)
        uaHTTPConfiguration = UAHTTPConfiguration(with: configuration, environment: environment)

        networkManager = await Backend.StateManager(with: configuration)
    }

    enum Request {}
    enum Response {}
}
