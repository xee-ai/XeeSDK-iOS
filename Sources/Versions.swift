// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Versions.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 11.08.2022.
//

import Foundation

extension Xee {
    public nonisolated static let SDKVersion = "0.2.0"
    nonisolated static let fallbackFormatVersion = 9
    nonisolated static let userAcquisitionVersion = 1

    // The paywall builder is not part of this SDK. These values stay because they are part of the
    // request hashes and headers that the server matches.
    nonisolated static let uiSchemaVersion = "4.4.0"
    nonisolated static let uiBuilderVersion = "4_4"
}

extension XeeOnboarding.ViewConfiguration {
    nonisolated static let uiVersion = "2.0.0"
}
