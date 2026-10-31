//  Versions.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

extension Xee {
    public nonisolated static let SDKVersion = "0.6.5"
    /// Must equal `FALLBACK_FORMAT_VERSION` in the dashboard (`dashboard/lib/fallback.ts`), which writes the file.
    nonisolated static let fallbackFormatVersion = 10
    /// Stored on the device; changing it resets install tracking.
    nonisolated static let userAcquisitionVersion = 1

    // The paywall builder is not part of this SDK. These go into the paywall request's URL hash and
    // headers and the fallback file paths; the Xee server ignores them, so they never need to change.
    nonisolated static let uiSchemaVersion = "4.4.0"
    nonisolated static let uiBuilderVersion = "4_4"
}
