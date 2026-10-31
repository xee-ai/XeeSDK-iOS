// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  EventsBackendConfiguration.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 24.09.2022.
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
