//  EventsBackendConfiguration.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

struct EventsBackendConfiguration: Sendable {
    var blacklist: Set<String>

    init(_ state: BackendState) {
        blacklist = state.eventBlacklist
    }

    init() {
        blacklist = Set<String>()
    }
}
