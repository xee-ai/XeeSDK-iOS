//  Environment.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

struct Environment: Sendable {
    let application: (installationIdentifier: String, version: String?, build: String?)
    let system: (name: String, version: String)
    let sessionIdentifier: String

    @XeeActor
    private init() async {
        application = (
            installationIdentifier: Environment.Application.installationIdentifier,
            version: Environment.Application.version,
            build: Environment.Application.build
        )
        system = await (
            name: Environment.System.name,
            version: Environment.System.version
        )

        sessionIdentifier = Environment.Application.sessionIdentifier
    }

    @XeeActor
    static var _instance: Environment?

    @XeeActor
    static var instance: Environment {
        get async {
            if let instance = _instance { return instance }
            let instance = await Environment()
            _instance = instance
            return instance
        }
    }
}
