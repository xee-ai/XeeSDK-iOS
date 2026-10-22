// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Versions.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 11.08.2022.
//

import Foundation

extension Xee {
    public nonisolated static let SDKVersion = "0.4.0"
    /// Must equal `FALLBACK_FORMAT_VERSION` in the dashboard (`dashboard/lib/fallback.ts`), which writes the file.
    nonisolated static let fallbackFormatVersion = 9
    /// Stored on the device; changing it resets install tracking.
    nonisolated static let userAcquisitionVersion = 1

    // The paywall builder is not part of this SDK. These go into the paywall request's URL hash and
    // headers and the fallback file paths; the Xee server ignores them, so they never need to change.
    nonisolated static let uiSchemaVersion = "4.4.0"
    nonisolated static let uiBuilderVersion = "4_4"
}
