// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywall.Draw.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 26.03.2024
//

import Foundation

extension XeePaywall {
    struct Draw<Content: PaywallContent>: Sendable {
        let userId: XeeUserId
        var content: Content
        let paywallAudienceVersionId: String
        let variationIdByPaywalls: [String: String]
    }
}

extension XeePaywall.Draw {
    var participatesInCrossPaywallABTest: Bool { variationIdByPaywalls.isNotEmpty }
}

extension XeePaywall.Draw: Decodable {
    init(from decoder: Decoder) throws {
        let userId = try decoder.userInfo.userId
        let paywall = try decoder.userInfo.paywall
        let paywallAudienceVersionId = paywall.audienceVersionId

        let variations = try [XeePaywall.Variation](from: decoder)

        guard variations.isNotEmpty else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Paywalls contents collection is empty"))
        }

        let index: Int
        if let variationId = decoder.userInfo.paywallVariationIdOrNil {
            guard let founded = variations.firstIndex(where: { $0.variationId == variationId }) else {
                throw PaywallDecodingError.notFoundVariationId
            }
            index = founded
        } else {
            index = variations.draw(
                paywallAudienceVersionId: paywallAudienceVersionId,
                userId: userId
            )
        }

        guard variations.indices.contains(index) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Paywall content with index \(index) not found"))
        }

        let variation = variations[index]

        let content = try Self.content(from: decoder, index: index)

        self.init(
            userId: userId,
            content: content,
            paywallAudienceVersionId: paywallAudienceVersionId,
            variationIdByPaywalls: variation.variationIdByPaywalls
        )
    }

    private static func content(from decoder: Decoder, index: Int) throws -> Content {
        var array = try decoder.unkeyedContainer()
        while !array.isAtEnd {
            if array.currentIndex == index {
                return try array.decode(Content.self)
            }
            _ = try array.decode(PassObject.self)
        }

        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Paywall content with index \(index) not found"))
    }
}

private struct PassObject: Decodable {}
