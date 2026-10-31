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
    }
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
        } else if let assigned = decoder.userInfo.assignedVariationOrNil,
                  assigned.audienceVersionId == paywallAudienceVersionId,
                  let kept = variations.firstIndex(where: { $0.variationId == assigned.variationId }) {
            // The server's choice for this test (Xee+Paywalls.swift, assignedVariation); a stale one is ignored.
            index = kept
        } else {
            index = variations.draw(
                paywallAudienceVersionId: paywallAudienceVersionId,
                userId: userId
            )
        }

        guard variations.indices.contains(index) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Paywall content with index \(index) not found"))
        }

        let content = try Self.content(from: decoder, index: index)

        self.init(
            userId: userId,
            content: content,
            paywallAudienceVersionId: paywallAudienceVersionId
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
