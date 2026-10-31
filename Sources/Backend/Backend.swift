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

    init(
        with configuration: XeeConfiguration,
        environment: Environment
    ) async {
        defaultHTTPConfiguration = MainHTTPConfiguration(with: configuration, environment: environment)
        uaHTTPConfiguration = UAHTTPConfiguration(with: configuration, environment: environment)

        networkManager = await Backend.StateManager(with: configuration)
    }

    enum Request {}
    enum Response {}
}
