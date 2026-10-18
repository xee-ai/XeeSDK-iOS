// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Event.Unpacked.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 15.09.2024
//

import Foundation

extension Event {
    struct Unpacked: Sendable {
        let id: String
        let event: Event
        let userId: XeeUserId
        let environment: Environment
        let createdAt: Date

        init(
            id: String = UUID().uuidString.lowercased(),
            event: Event,
            userId: XeeUserId,
            environment: Environment,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.event = event
            self.userId = userId
            self.environment = environment
            self.createdAt = createdAt
        }
    }
}
