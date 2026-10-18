// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeeUI+Events.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 22.10.2025.
//

package extension Xee {
    nonisolated static func logShowOnboardingViaXeeUI(_ params: XeeUIOnboardingScreenShowedParameters) async throws(XeeError) {
        try await trackEvent(
            .onboardingScreenShowed(params)
        )
    }
}
