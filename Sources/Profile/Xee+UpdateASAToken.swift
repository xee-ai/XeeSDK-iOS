// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+UpdateASAToken.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 23.09.2024
//

import Foundation
#if canImport(AdServices)
import AdServices

private let log = Log.default

extension Xee {
    func updateASATokenIfNeed(for profile: VH<XeeProfile>) {
        guard
            #available(iOS 14.3, macOS 11.1, visionOS 1.0, *),
            (try? profileStorage.appleSearchAdsSyncDate(for: profile.userId)) == nil, // check if this is an actual first sync
            let attributionToken = try? Xee.getASAToken()
        else { return }

        Task {
            let userId = profile.userId

            let response = try await httpSession.sendASAToken(
                userId: userId,
                token: attributionToken,
                responseHash: profile.hash
            )
            handleProfileResponse(response)

            // mark appleSearchAds attribution data as synced
            try? profileStorage.setAppleSearchAdsSyncDate(for: userId)
        }
    }

    @available(iOS 14.3, macOS 11.1, visionOS 1.0, *)
    static func getASAToken() throws -> String {
        let stamp = Log.stamp
        Xee.trackSystemEvent(XeeAppleRequestParameters(
            methodName: .fetchASAToken,
            stamp: stamp
        ))

        do {
            let attributionToken = try AAAttribution.attributionToken()

            Xee.trackSystemEvent(XeeAppleResponseParameters(
                methodName: .fetchASAToken,
                stamp: stamp,
                params: [
                    "token": attributionToken,
                ]
            ))

            return attributionToken

        } catch {
            log.error("UpdateASAToken: On AAAttribution.attributionToken \(error)")
            Xee.trackSystemEvent(XeeAppleResponseParameters(
                methodName: .fetchASAToken,
                stamp: stamp,
                error: "\(error.localizedDescription). Detail: \(error)"
            ))
            throw error
        }
    }
}

#else
extension Xee {
    func updateASATokenIfNeed(for _: VH<XeeProfile>) {}
}
#endif
