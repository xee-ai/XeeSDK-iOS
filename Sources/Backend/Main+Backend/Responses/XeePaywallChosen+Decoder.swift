// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywallChosen+Decoder.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 11.11.2025.
//

import Foundation

extension XeePaywallChosen {
    @inlinable
    static func createDecoder(
        withUserId userId: XeeUserId,
        withPaywallId paywallId: String,
        withRequestLocale requestLocale: XeeLocale,
        withCached cached: Content?
    ) -> HTTPDecoder<XeePaywallChosen> {
        return decoder

        @Sendable
        func decoder(
            _ response: HTTPDataResponse,
            _ configuration: HTTPCodableConfiguration?,
            _ request: HTTPRequest
        ) async throws -> HTTPResponse<XeePaywallChosen> {
            let body = response.body ?? Data()
            let jsonDecoder = JSONDecoder()
            configuration?.configure(jsonDecoder: jsonDecoder)

            let paywall = try jsonDecoder.decode(
                Backend.Response.Meta<XeePaywall>.self,
                from: body
            ).value

            if let cached, cached.paywall.isNewerThan(paywall) {
                return response.replaceBody(XeePaywallChosen.restore(cached))
            }

            jsonDecoder.userInfo.setPaywall(paywall)
            jsonDecoder.userInfo.setUserId(userId)
            jsonDecoder.userInfo.setRequestLocale(requestLocale)

            let draw = try jsonDecoder.decode(
                Backend.Response.Data<XeePaywall.Draw<Content>>.self,
                from: body
            ).value

            Log.crossAB.verbose("AB-test paywallId = \(paywallId), variationId = \(draw.content.variationId) DRAW")
            return response.replaceBody(XeePaywallChosen.draw(draw))
        }
    }
}
