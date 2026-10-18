// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywallChosen+Decoder.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 11.11.2025.
//

import Foundation

extension XeePaywallChosen {
    typealias VariationIdResolver = @Sendable (_ paywallId: String, XeePaywall.Draw<Content>) async throws -> String

    @inlinable
    static func createDecoder(
        withUserId userId: XeeUserId,
        withPaywallId paywallId: String,
        withRequestLocale requestLocale: XeeLocale,
        withCached cached: Content?,
        variationIdResolver: VariationIdResolver?
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

            guard let variationId = try await variationIdResolver?(paywallId, draw),
                  variationId != draw.content.variationId
            else {
                if variationIdResolver == nil {
                    Log.crossAB.verbose("AB-test paywallId = \(paywallId), variationId = \(draw.content.variationId) DRAW")
                }
                return response.replaceBody(XeePaywallChosen.draw(draw))
            }

            jsonDecoder.userInfo.setPaywallVariationId(variationId)

            let variation = try jsonDecoder.decode(
                Backend.Response.Data<XeePaywall.Draw<Content>>.self,
                from: body
            ).value

            return response.replaceBody(XeePaywallChosen.draw(variation))
        }
    }

    @inlinable
    static func createDecoder(
        withUserId userId: XeeUserId,
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
            jsonDecoder.userInfo.setRequestLocale(requestLocale)

            let variation = try jsonDecoder.decode(
                Backend.Response.Data<XeePaywall.Variation>.self,
                from: body
            ).value

            let content = try jsonDecoder.decode(
                Backend.Response.Data<Content>.self,
                from: body
            ).value

            let draw = XeePaywall.Draw<Content>(
                userId: userId,
                content: content,
                paywallAudienceVersionId: paywall.audienceVersionId,
                variationIdByPaywalls: variation.variationIdByPaywalls
            )

            return response.replaceBody(XeePaywallChosen.draw(draw))
        }
    }
}
