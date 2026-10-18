// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeConfiguration.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.04.2024.
//

import XeeLogger
import Foundation

public struct XeeConfiguration: Sendable {
    static let `default` = (
        observerMode: false,
        idfaCollectionDisabled: false,
        ipAddressCollectionDisabled: false,
        transactionFinishBehavior: TransactionFinishBehavior.default,
        clearDataOnBackup: false
    )

    let apiKey: String
    let customerUserId: String?
    let appAccountToken: UUID?
    let observerMode: Bool
    let idfaCollectionDisabled: Bool
    let ipAddressCollectionDisabled: Bool
    let callbackDispatchQueue: DispatchQueue?
    let backend: Backend.Configuration
    let logLevel: XeeLog.Level?
    let crossPlatformSDK: (name: String, version: String)?
    let transactionFinishBehavior: TransactionFinishBehavior
    let clearDataOnBackup: Bool
}

extension XeeConfiguration {
    @XeeActor
    static var transactionFinishBehavior = Self.default.transactionFinishBehavior

    var apiKeyPrefix: String {
        String(apiKey.prefix(while: { $0 != "." }))
    }
}
