// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  XeePaywall.Variation.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 15.04.2025.
//

import Foundation

extension XeePaywall {
    struct Variation: Sendable, Decodable {
        let variationId: String
        let weight: Int

        enum CodingKeys: String, CodingKey {
            case variationId = "variation_id"
            case weight
        }

        init(from decoder: Decoder) throws {
            let superContainer = try decoder.container(keyedBy: Backend.CodingKeys.self)

            let container =
                if superContainer.contains(.attributes) {
                    try superContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .attributes)
                } else {
                    try decoder.container(keyedBy: CodingKeys.self)
                }

            variationId = try container.decode(String.self, forKey: .variationId)
            weight = try container.decode(Int.self, forKey: .weight)
        }
    }
}

extension [XeePaywall.Variation] {
    func draw(
        paywallAudienceVersionId: String,
        userId: XeeUserId
    ) -> Int {
        let countVariations = self.count
        guard countVariations > 1 else { return 0 }

        let data = Data("\(paywallAudienceVersionId)-\(userId.profileId)".md5.suffix(8))
        let value: UInt64 = data.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
        var weight = Int(value % 100)

        let sortedItems = self
            .enumerated()
            .sorted(by: { first, second in
                if first.element.weight == second.element.weight {
                    first.element.variationId < second.element.variationId
                } else {
                    first.element.weight < second.element.weight
                }
            })

        let index = sortedItems.firstIndex { item in
            weight -= item.element.weight
            return weight < 0
        } ?? (countVariations - 1)

        return sortedItems[index].offset
    }
}
